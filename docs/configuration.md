# Configuration

All settings are under **Options → Addon Options → Antistasi Ultimate QoL by TchicX**. They can also be put in a CBA settings file, `cba_settings.sqf`, for example `force auqol_loot_radius = 1000;`.

**Scope.** Settings marked *Server* are registered with `isGlobal = 1`. The server's value is shared with every client, because the code they control runs on whichever machine owns the object, and that has to be the same everywhere. The player features are also server settings, so the server decides for everyone, while the effect is still applied on each player's own machine. Only `auqol_debug` is *Client* (`isGlobal = 0`).

Every setting takes effect immediately, with no mission restart.

## Enemy crew ejection

| Setting | Type | Default | Scope | Description |
| --- | --- | --- | --- | --- |
| `auqol_eject_enabled` | Checkbox | On | Server | When an enemy AI land vehicle becomes immobilized, move its eligible occupants out. |
| `auqol_eject_outOfFuel` | Checkbox | On | Server | `canMove` ignores fuel for land vehicles. With this on, a tank of exactly 0 fuel also counts as immobilized. |

**How immobilization is detected.**

- Each land vehicle except static weapons gets `Dammaged`, `Fuel` and `GetIn` handlers on every machine, added by a CBA `InitPost` class handler. These events are global, and the handler exits immediately unless the vehicle is local, so only its owner acts. That stays true when locality changes, for example when an AI group moves to a headless client.
- On each event the vehicle counts as immobilized if `!canMove vehicle` is true, meaning engine, wheels or tracks are damaged beyond use, or if `fuel vehicle == 0` and the fuel option is on. A parked vehicle, a vehicle waiting for orders, or one with its engine off is still `canMove` true and keeps its crew.
- If eligible crew are aboard, ejection waits until the vehicle is below 3 km/h, for up to 8 seconds, so nobody is dropped out at speed. After that it retries at most 3 times, then waits for the next event. A per-vehicle pending flag prevents duplicate scheduling. There is no loop. When the wait ends, `auqol_eject_enabled`, the vehicle and the crew are checked again; if the vehicle changed owner during the wait, the check is sent to the new owner with the `auqol_eject_evaluate` CBA event.

**Who is ejected:** living AI that are not players and whose side is hostile to the rebels. Hostile means `getFriend` is below 0.6 toward Antistasi's `teamPlayer` side, or toward any player's side outside Antistasi. Units that are `captive`, Antistasi `surrendered`, ACE handcuffed or ACE surrendering are never ejected. Friendly AI, civilians and players are never ejected either.

**Opt-out for mission makers:** `vehicleOrUnit setVariable ["auqol_noEject", true, true]`.

## Service vehicles

| Setting | Type | Default | Scope | Description |
| --- | --- | --- | --- | --- |
| `auqol_service_fuel` | Checkbox | On | Server | Fuel sources never run out of the fuel they hand out. |
| `auqol_service_ammo` | Checkbox | On | Server | Ammo sources never run out. |
| `auqol_service_repair` | Checkbox | On | Server | Repair sources never run out. |
| `auqol_service_garageFuel` | Checkbox | On | Server | Keep fuel sources stored in the Antistasi garage full. Needs `auqol_service_fuel` on as well. |

An object is a service source only if its config declares the service: `transportFuel`, `transportAmmo` or `transportRepair` greater than 0, or ACE's `ace_refuel_fuelCargo` or `ace_rearm_defaultSupply`. Ordinary vehicles are never touched. ACE jerry cans are excluded because they are portable consumables. Map-placed fuel stations are terrain objects, not service vehicles, so they keep Antistasi's finite fuel economy.

Turning a setting off restores ACE fuel sources to their normal finite capacity and ACE rearm sources to their default supply. Vanilla cargo simply stops being refilled.

To opt a single object out: `object setVariable ["auqol_service_exclude", true, true]`.

See [service-audit.md](service-audit.md) for why each service is handled the way it is.

## Player

| Setting | Type | Default | Scope | Description |
| --- | --- | --- | --- | --- |
| `auqol_player_noSway` | Checkbox | On | Server | No weapon sway. Uses vanilla `setCustomAimCoef 0`, or an ACE sway multiplier of 0 when ACE sway is active. Turned off, the vanilla coefficient from before is put back. |
| `auqol_player_unlimitedStamina` | Checkbox | On | Server | Uses vanilla `enableStamina false`, or an ACE Advanced Fatigue duty factor of 0 when ACE fatigue is active. |
| `auqol_player_weightless` | Checkbox | On | Server | Sets the `loadCoef` trait to 0, including ACE movement's saved base value, and gives ACE Advanced Fatigue a carried mass of 0. |
| `auqol_player_recoil` | Slider 0–100% | 100% | Server | Below 100%, `setUnitRecoilCoefficient` to the slider value (0.7 at 70%) on your own character. Back at 100%, the value from before is put back. Replaced the `auqol_player_noRecoil` checkbox in 1.9.0; 0% is the old No recoil. |
| `auqol_player_squad` | Checkbox | On | Server | Also apply the four settings above to the AI in your group that are local to your machine. AI always get the vanilla commands (`setCustomAimCoef`, `enableStamina`, `loadCoef`, `setUnitRecoilCoefficient`), because ACE sway, Advanced Fatigue and movement only run for players. Off restores the AI values AUQOL changed. |

With `auqol_player_squad` off these only affect the local player's unit. With it on they also cover the AI in your own group, applied when a recruit joins and re-checked every 15 seconds as a fallback. AI outside your group are never changed. An AI that leaves your group keeps the values it had (Antistasi normally deletes dismissed AI).

## Squad reactions

| Setting | Type | Default | Scope | Description |
| --- | --- | --- | --- | --- |
| `auqol_squad_reaction` | Checkbox | On | Server | Raises the `spotTime`, `spotDistance`, `aimingSpeed` and `commanding` skills of the AI in groups a player leads to at least the value below. `aimingAccuracy` and `aimingShake` are left at Antistasi's value. Off restores the values AUQOL replaced. Also, when your group detects a new enemy (`EnemyDetected`), each AI of your group local to you gets `reveal` on it at once, with the best knowledge on its side, instead of waiting for the spoken report. |
| `auqol_squad_reactionAll` | Checkbox | On | Server | The same for every friendly AI (Antistasi's `teamPlayer` side): garrisons, static and turret gunners, high-command squads. Each unit is checked where it is local when it spawns (CBA `InitPost` on `CAManBase`), again 5 s later after Antistasi has set its skills, when it becomes local to another machine (`Local` event) and when it joins a player's group (`UnitJoined`). A full pass over the friendly AI local to each machine runs once a minute as a fallback (four `skill` reads per unit, `setSkill` only below the floor). Off: units outside player-led groups get their old values back. |
| `auqol_squad_reactionSkill` | Slider 0.3–1 | 0.8 | Server | The floor for those four skills. Antistasi sets rebel skill to `0.1 + 0.1 × rebel skill multiplier + 0.015 × FIA skill`, so recruits start around 0.2 to 0.4. The server's AI difficulty still scales the final value. |
| `auqol_squad_revealKey` | Checkbox | On | Server | On the engine's Reveal target action (`revealTarget`, T by default): if `cursorTarget` (or `cursorObject`) is a living hostile soldier or vehicle, every unit of your group local to you gets `reveal` 4 on it. When you lead the group it becomes the group's focus for 30 s (`AUQOL_fnc_squadRevealFocus`, run on the press and then every second by one handler per group): each AI whose `getAttackTarget` is something else gets `doTarget`, and `doFire` when its combat mode is YELLOW or RED, so Hold fire still holds. A new press replaces the focus; the old target keeps its knowledge. The focus ends when the target dies, after 30 s, or when you stop leading the group. |
| `auqol_squad_selfTreat` | Checkbox | On | Server | For the AI of your group local to you: a `Dammaged` handler checks the unit 3 s after a hit, and the 15 s player pass and `UnitJoined` check the whole group. Really hurt (`HitLegs` or any hit point at 0.5 or more, or `damage` above 0.25): the vanilla `HealSoldierSelf` action, if it carries an item of type 401 (first aid kit) or 619 (medikit, medics only), then a check 11 s later. Lightly hurt (`damage` at most 0.25 and every hit point below 0.5): `setDamage 0`. Skipped in vehicles, for captives, while incapacitated or surrendered, while Antistasi's `helped`/`helping` medical is running, and entirely when ACE medical (`ace_medical_engine`) is loaded. |
| `auqol_squad_selfTreatMedikit` | Checkbox | On | Server | With it on, the lightly-hurt `setDamage 0` only happens when the unit carries an item of type 619 (medikit). Off: every lightly hurt AI of your group is cleared. Real wounds still need a first aid kit (or a medikit for medics) either way. |
| `auqol_squad_launchers` | Checkbox | On | Server | When the group detects a new enemy vehicle (`EnemyDetected` group event), on the T key, and every 5 seconds as a fallback, an AI of your group with a loaded launcher whose ammo `aiAmmoUsageFlags` include 128 or 512 (ground vehicles, 500 m) or 256 (air, 2000 m) checks its known enemy targets (`targets`). The first vehicle in range with a clear line of sight (`checkVisibility` above 0.5) makes it `selectWeapon` the launcher and `doTarget` the vehicle; vehicles another gunner already targets with a launcher come last. A vehicle out of the fight (`AUQOL_fnc_squadIsOutOfFight`: no living crew, an aircraft with `canMove` false, or a ground vehicle with `canMove` and `canFire` false) is never picked. An empty launcher counts when the unit carries a compatible round. A unit holding the launcher keeps its target while it is in the fight; once it is out, the unit gets the next vehicle, or `forgetTarget`, `doTarget objNull` and back to its rifle. Also runs 1 s after each launcher round of a local AI has hit (CBA `Fired` class handler). Skipped in vehicles and while incapacitated. |

The T key setting only touches AI in your own group. Self-treat and the launcher switch also run for AI groups in a fight, through smart combat. Faster reactions cover friendly AI only; enemies are never changed.

## AI animation speed

| Setting | Type | Default | Scope | Description |
| --- | --- | --- | --- | --- |
| `auqol_anim_ai` | Checkbox | On | Server | Every non-player soldier (`CAManBase`) gets `setAnimSpeedCoef` set to the speed below. That command only acts on the machine that runs it, so every machine sets it for every AI: when a unit spawns (CBA `InitPost`) and in a 15 s pass that writes only when a unit's value is different, which also re-applies it after ACE medical puts a medic back to 1. A unit that becomes a player is set back to 1 at once on its own machine and within 15 s elsewhere. Off: every unit AUQOL changed goes back to 1. No FSM, behaviour or skill is changed. |
| `auqol_anim_aiSpeed` | Slider 1–2 | 1.25 | Server | The coefficient. 1.0 is vanilla, 2.0 twice as fast. Upper-body animations such as reloading are not affected by the engine command. |

## Player animations

| Setting | Type | Default | Scope | Description |
| --- | --- | --- | --- | --- |
| `auqol_anim_pistolSwap` | Checkbox | On | Server | An `AnimStateChanged` handler on your unit speeds up weapon switch states to or from the handgun: names of the form `<from>_<to>` with `wpst` in exactly one half, and their `<from>_<to>_end` part at 1.5 times that speed (2 and 3 by default). The next state goes back to 1. |
| `auqol_anim_pistolSwapSpeed` | Slider 1–3 | 2 | Server | The speed during the swap. |
| `auqol_anim_ladder` | Checkbox | On | Server | The same handler speeds up every state with `ladder` in its name. The CBA keybind *Fast ladder climbing (hold)* (Left Shift by default, under Controls > Configure Addons > Antistasi Ultimate QoL by TchicX) switches to the faster speed below while held; it doesn't block the key, so Left Shift still sprints off the ladder. |
| `auqol_anim_ladderSpeed` | Slider 1–3 | 1.5 | Server | Ladder speed without the key. |
| `auqol_anim_ladderFastSpeed` | Slider 1–4 | 2.5 | Server | Speed with the key held while climbing (any ladder state without `down` in its name). |
| `auqol_anim_ladderSlideSpeed` | Slider 1–6 | 4 | Server | Speed with the key held on ladder states with `down` in their name, so you slide down. |

The boost is sent to every machine with a CBA global event, so others see you climb at the same speed. Under ACE Advanced Fatigue, `auqol` is added to `ace_advanced_fatigue_setAnimExclusions` while the boost lasts, which is ACE's own way to keep its 1 s loop from resetting the speed.

## Smart combat AI

| Setting | Type | Default | Scope | Description |
| --- | --- | --- | --- | --- |
| `auqol_combat_tactics` | Checkbox | On | Server | Each AI group gets an `EnemyDetected` handler (added on every machine, acting where the group is local); that event, or a member's `Suppressed` event, starts one 3 s CBA timer for the group (`AUQOL_fnc_combatTick`) that ends 30 s after the group last knew of an enemy within `auqol_combat_range`. Members (never the leader) are split into two fire teams by order. One team moves while the other covers; they swap when every mover has reached its spot (at least 6 s after the last swap) or after 20 s. A mover's spot is found by `AUQOL_fnc_combatFindCover` near a point a third of the way (at most 25 m) from the leader toward where the leader believes the enemy is (`getHideFrom`): building positions and the spot behind each nearby terrain object (trees, rocks, walls, fences, ruins, bunkers, houses) or wall, sandbag or H-barrier object, closest first, at most 12 tested, each with one `lineIntersectsSurfaces` from the enemy's eye height to the spot's chest height. The unit gets `doMove` to it. In cover outdoors it crouches (`setUnitPos "MIDDLE"`, only from "Auto"); at a building position it stays up. When contact ends, the feature is turned off or the unit stops being eligible, it gets `doFollow` its leader and its stance back. Groups led by a player and civilians are skipped. |
| `auqol_combat_buildings` | Checkbox | On | Server | Building positions are cover candidates. When the believed enemy position is inside a building (within 70% of its bounding radius) within 80 m of the leader, up to two movers take that building's free positions nearest to the enemy instead. |
| `auqol_combat_flank` | Checkbox | On | Server | With three or more members and the enemy over 40 m away, the second team's advance point is turned 50° to one side (chosen once per group). |
| `auqol_combat_suppressiveFire` | Checkbox | On | Server | A covering unit whose view to the believed enemy position is blocked (`checkVisibility` 0.3 or less) gets `doSuppressiveFire` on it, with a 35% chance per pass, within 400 m. |
| `auqol_combat_grenades` | Checkbox | On | Server | Instead of suppressing, a covering unit 12 to 35 m from that position, with no friendly soldier within 8 m of it, faces it and throws a hand grenade (`forceWeaponFire` with the Throw muzzle of a magazine whose ammo simulation is `shotGrenade`). Once every 40 s per unit. |
| `auqol_combat_smoke` | Checkbox | On | Server | A mover that finds no cover while the enemy is within 200 m throws smoke (ammo simulation `shotSmoke` or `shotSmokeX`) toward it. Once a minute per group. |
| `auqol_combat_assault` | Checkbox | On | Server | When the believed enemy position is within 50 m of the leader, no armor is known, and the group (leader included) is at least twice the number of known enemy soldiers within 50 m of that position, movers search for cover within 12 m of the enemy position, and with none go straight to 4 m from it. |
| `auqol_combat_defend` | Checkbox | On | Server | The group counts as defending when Antistasi's PATCOM gave it defend orders (`PATCOM_Patrol_Params` "Patrol_Defend"), its current waypoint is HOLD, GUARD or SENTRY, it has no waypoint left, or its leader is stopped. Movers then search for cover within 30 m of the leader, no building clearing, flanking or smoke. |
| `auqol_combat_antiArmor` | Checkbox | On | Server | The launcher switch (`AUQOL_fnc_squadLaunchers`) runs on the members every pass while any enemy vehicle is known, so AA gunners engage aircraft too. With a known enemy `Tank` or `Wheeled_APC_F` (RHS and CUP armour inherits these) within 400 m of the leader, AT gunners target it, and movers without a launcher search for cover around a point 15 m further from the vehicle. |
| `auqol_combat_spreadTargets` | Checkbox | On | Server | At each team swap, with more than one known enemy soldier, each covering unit in turn gets `doTarget` on the next one. |
| `auqol_combat_shareContacts` | Checkbox | On | Server | On a group's `EnemyDetected`, AI groups of the same side whose leader is within 300 m (at most 6, once every 10 s per reporting group) get `reveal` 1.5 on the enemy, through a CBA target event to their leader's machine since `reveal` only acts locally. Your own squad's sightings are shared the same way. Their own `EnemyDetected` then starts their tactics. No orders or waypoints change. |
| `auqol_combat_dodge` | Checkbox | On | Server | A CBA `Fired` class handler on every soldier: when the weapon is `Throw` and the ammo's simulation is `shotGrenade`, once the grenade is more than 3 m from the thrower (ACE Advanced Throwing raises the event while it is still in the hand) and 1.2 s later, every eligible AI on foot within 10 m of the grenade that is local to the machine gets `doMove` to 12 m directly away from it, and `doFollow` 6 s later. |
| `auqol_combat_resupply` | Checkbox | On | Server | Every 10 s per group in contact: a member with fewer than two magazines for its primary weapon (`compatibleMagazines`) gets one moved over from a local group mate within 15 m who has four or more. Antistasi's own rearming from bodies is separate and unchanged. |
| `auqol_combat_medics` | Checkbox | On | Server | Every 10 s per group in contact, while the nearest known enemy is more than 60 m away: each member with the medic trait treats the most hurt group mate within 30 m whose damage is over 0.3 and who is not down or already being helped, with the vanilla `HealSoldier` action, at most every 20 s. Downed units and units treating themselves are left alone. Before that, wounded members treat themselves with `AUQOL_fnc_squadSelfTreat` when `auqol_squad_selfTreat` is on. Off when `ace_medical_engine` is loaded. |
| `auqol_combat_range` | Slider 100–1000 | 500 | Server | Distance from the leader to the nearest known enemy within which the tactics run. |
| `auqol_combat_noProne` | Checkbox | On | Server | AUQOL's stance changes go no lower than crouching (the suppression reaction's prone step is skipped). Turn it off to let heavily suppressed AI go prone. AUQOL only changes units whose `unitPos` is "Auto" either way, so a no-prone mod's or Antistasi's stance orders always win. |
| `auqol_combat_revealShooter` | Checkbox | On | Server | From each AI's `Suppressed` event (a hostile round passed close), where the unit is local, at most once every 2 s per unit: the unit's group gets `reveal` 1.5 on the instigator (or the shooter for a vehicle). `reveal` never lowers knowledge. Every AI, both sides, players' squads included. |
| `auqol_combat_takeCover` | Checkbox | On | Server | In the same event: an AI on foot that is standing with `unitPos` "Auto" gets `setUnitPos "MIDDLE"`, or `"DOWN"` when `getSuppression` is above 0.8. 10 s after the last close round it goes back to "AUTO", unless something else changed its stance meanwhile. Skipped in vehicles, for captives, incapacitated units and groups led by a player. |
| `auqol_combat_yieldToAIMods` | Checkbox | On | Server | When `lambs_danger` or `VCOM_AI` is in CfgPatches, every smart combat setting above does nothing, since those mods run their own combat AI. Off: AUQOL runs alongside them, and the two will both give orders. |

**Leaving Antistasi Ultimate's AI alone.** Antistasi's PATCOM steers each group with waypoints (patrol, defend, and a search-and-destroy waypoint near the enemy in combat) and sets its behaviour, combat mode, formation and speed. AUQOL never touches any of those, and never moves the leader, so the group goes where Antistasi sends it and the members fight from cover around that. A member is only moved when nothing else has it busy (`AUQOL_fnc_combatIsEligible`): not with pathing or movement off (Antistasi garrisons and its smoke charge), stopped, in a vehicle or static, incapacitated, surrendered, captive, fleeing, healing or being healed (`helping`, `helped`), rearming, attached, remote controlled, or with a command other than none, attack or fire, or with a move order AUQOL didn't give. While Antistasi's kill reaction runs for the group (`A3A_reactingToKill`: support call, suppressing fire, smoke charge), AUQOL gives no new orders. Badly hit units running for cover (`A3A_fnc_unitGetToCover`) have Antistasi's move order and are left alone.

## Map

| Setting | Type | Default | Scope | Description |
| --- | --- | --- | --- | --- |
| `auqol_map_liveVehicles` | Checkbox | On | Server | Antistasi's `A3A_fnc_vehicleMarkers` puts a local marker on each player's map for convoy objectives, mission vehicles, supply boxes and revealed enemy vehicles, and moves it every 60 s. With this on, each player's machine checks those markers every second while the map or the GPS panel is open (`visibleMap`, `visibleGPS`), every 10 s while both are closed, and at once when the map opens (`Map` mission event). A marker is moved when its vehicle is more than 5 m from it. |

**How the markers are found.** Antistasi names each one after its text followed by a random number and gives it a NATO vehicle icon (`n_`, `b_` or `o_` plus `motor_inf`, `mech_inf`, `armor`, `plane`, `uav`, `air`, `naval` or `unknown`). Antistasi keeps no link from the marker to its vehicle, so a marker of that shape is paired with the nearest unpaired living vehicle within 150 m of it whose kind gives the same icon, by Antistasi's own rules (car or truck, APC, tank, plane, UAV, helicopter, boat); if none is near yet it is tried again every second. New markers are found through the `MarkerCreated` mission event (a marker whose text is still empty waits up to 10 s for it), with a full `allMapMarkers` scan every 30 s as fallback. When Antistasi deletes the marker (`MarkerDeleted`), AUQOL forgets it. Antistasi still moves every marker to its real vehicle once a minute; if it moves a tracked marker more than 20 m (plus 2 s of travel) away from the paired vehicle, the pairing was wrong, so the marker stays where Antistasi put it and is paired again from there. Off: the markers fall back to Antistasi's once-a-minute update.

**What stays as it is.** Player markers (Antistasi updates them every second already), zone markers (they change when a zone changes hands) and intercepted support markers (owned by the server, updated every 5 s).

## Performance

| Setting | Type | Default | Scope | Description |
| --- | --- | --- | --- | --- |
| `auqol_freeze_parked` | Checkbox | On | Server | Every 30 s the server marks each empty vehicle (no living crew) that stands still (`speed` below 1) on the ground or water, and is not attached, towed or on a rope, with `enableDynamicSimulation true`. The engine then stops simulating it while no player is within 500 m and wakes it when one comes closer. A marked vehicle that gets crew, moves or is picked up is unmarked on the next pass. Static weapons are never marked. Vehicles that are hidden or whose simulation is already off when first seen (ACE cargo, Antistasi logistics, other mods) are never marked. |
| `auqol_freeze_wrecks` | Checkbox | On | Server | The same for destroyed vehicles that have come to rest. Antistasi's garbage clean still deletes wrecks as before. |

If the engine's dynamic simulation is off, AUQOL turns it on (`enableDynamicSimulationSystem`) and sets the empty-vehicle wake distance to 500 m (`"EmptyVehicle" setDynamicSimulationDistance 500`). Only marked objects are affected; AI groups are never marked. If the mission or another mod already runs dynamic simulation, its distances are kept. With both settings off, AUQOL unmarks every vehicle it marked and turns dynamic simulation off again if it was the one that turned it on.

## Rebel loadouts

| Setting | Type | Default | Scope | Description |
| --- | --- | --- | --- | --- |
| `auqol_loadout_copyFromUser` | Checkbox | On | Server | Adds "Copy from user" to the bottom bar of Antistasi's Set Rebel Loadout arsenal, in the empty third slot (the vanilla Random button, which Antistasi blanks). |

**What it copies.** The loadout you wore when you opened the editor, which Antistasi keeps aside while you edit. Weapons are reduced to their base class, the way the arsenal lists them. Every item that the arsenal does not have unlimited is dropped: a locked weapon, uniform, vest, backpack, headgear, facewear or assigned item leaves that slot unset, which Antistasi fills at random for each recruit, and locked attachments, magazines and container items are removed. The chat line lists what was skipped.

**How it is applied.** Through Antistasi's own "load this role into the editor" step, so every slot the copy fills gets its override switch turned on (green). Nothing is saved until you press Save. Closing without saving keeps the old loadout, and you get your own loadout back on close as usual.

**Recruits not wearing the loadout?** That is Antistasi's slot switch. Green slot icons on the left of the editor are forced on recruits, black ones are rolled at random. Click a black icon to make it green, then Save. New loadouts start all green unless the mission parameter "loadoutArsenalDefaultOverride" is off.

## AI stuck recovery

| Setting | Type | Default | Scope | Description |
| --- | --- | --- | --- | --- |
| `auqol_stuck_enabled` | Checkbox | On | Server | Master switch. |
| `auqol_stuck_scope` | List | Your squad | Server | 0 Your squad: AI in each player's own group. 1 Friendly AI near players: within `auqol_stuck_scopeRadius` of any player. 2 All friendly AI. Friendly means Antistasi's `teamPlayer` side, or the player's side outside Antistasi. |
| `auqol_stuck_scopeRadius` | Slider 50–3000 | 500 | Server | Radius for scope 1, in metres. |
| `auqol_stuck_timeout` | Slider 10–300 | 30 | Server | Seconds without progress before a unit counts as stuck. Each recovery step also gets this long to work. |
| `auqol_stuck_minProgress` | Slider 0.5–20 | 3 | Server | Getting this many metres closer to the destination than before, or moving this far from where the current window started, counts as progress and resets everything. Moving only counts while the unit reached a new closest point within the last three timeouts, so circling or going back and forth is detected. |
| `auqol_stuck_refreshOrders` | Checkbox | On | Server | Step 1: re-issue the current order to the same place (`doMove`, `setCurrentWaypoint` on the current waypoint, or `doFollow` the leader). |
| `auqol_stuck_regroup` | Checkbox | On | Server | Step 2, formation followers only: `doWatch objNull`, `doStop`, `doFollow` the leader. |
| `auqol_stuck_reposition` | Checkbox | On | Server | Step 3: a hop of up to 10 m (25 m for a driven vehicle) toward the destination or leader, onto a checked spot, then step 1 again. |
| `auqol_stuck_teleport` | Checkbox | Off | Server | Step 4, infantry only: to a checked spot within 15 m of the squad leader, when the leader is within `auqol_stuck_maxDistance`. |
| `auqol_stuck_maxDistance` | Slider 5–500 | 100 | Server | Upper limit for the hop, and the furthest the leader may be for a teleport. |
| `auqol_stuck_cooldown` | Slider 10–600 | 60 | Server | After every enabled step failed (one round), wait this long before the next round. |
| `auqol_stuck_maxAttempts` | Slider 1–10 | 3 | Server | Failed rounds before the unit is left alone until it moves again by itself. |
| `auqol_stuck_notifyDetect` | Checkbox | Off | Server | System chat when a unit gets stuck (with the likely reason) and for each step tried. |
| `auqol_stuck_notifyResult` | Checkbox | On | Server | System chat when a unit moves again, and when a round fails or the unit is given up on. |

**Checks.** Every 5 seconds each machine (server, headless clients, players) checks the AI local to it in the chosen scope. A unit local to one machine is never checked anywhere else, so recovery never runs twice. The full list of skipped states is in [FEATURES.md](../FEATURES.md#12-ai-stuck-recovery). In short: a unit is watched only with a destination more than 8 m away (25 m driving), only a move or follow order, not fighting, not down, surrendered, captive, healing or rearming, not attached, remote controlled or in a scripted animation, on the ground and dry, and, in AI-led groups, not holding, guarding, patrolling or on a scripted waypoint. For scopes 1 and 2 each machine keeps its friendly AI in a list, rebuilt from `allUnits` every 30 s or when the scope changes, and pruned on every check.

**Before moving.** Steps 3 and 4 run the full eligibility check again (`AUQOL_fnc_stuckIsEligible`) right before `setPosATL` or `setVehiclePosition`, and also require that the unit is not in COMBAT behaviour. A unit that fails is not moved.

**Safe spots** for steps 3 and 4 come from `findEmptyPosition` (room for that unit or vehicle type), and are rejected when in water, on a slope above about 37°, under a roof, more than 3 m above or below the centre, or within 100 m of a unit hostile to the players.

**Messages** go to the player leading the unit's group, through a CBA event when the AI is local to another machine. A unit produces at most one line when it gets stuck, one per step, one per failed round and one when it moves again. With `auqol_debug` on, each event is also written to the RPT with the unit's grid position.

**Clean-up.** Tracking is a variable on the unit, cleared whenever the unit is ineligible and dropped with the unit when it dies or is deleted. A unit not seen for 15 seconds, or that changed group, starts fresh. There is one 5-second timer per machine and no per-unit script.

## Total weight limit

There is no setting. The engine stops you adding items once your total load passes `CfgInventoryGlobalVariable >> maxSoldierLoad` (vanilla 1000), however much room your backpack has. AUQOL raises it to 10,000,000 in `config.cpp`, so total weight never blocks you. Each uniform, vest and backpack keeps its own normal capacity.

It is a static config value, and the wiki says unit max load can't be set by script, so it applies to every unit, AI included. It also makes weight count for almost nothing in vanilla stamina for everyone. Remove the mod to undo it.

## Loot gathering

Needs Antistasi Ultimate. Without it the action is not added.

| Setting | Type | Default | Scope | Description |
| --- | --- | --- | --- | --- |
| `auqol_loot_enabled` | Checkbox | On | Server | Adds the loot crate's "Gather Scattered Loot" hold action to every land vehicle, aircraft and boat (not static weapons), and makes vehicles and the loot crate use `auqol_loot_radius`. Off: vehicles lose the action and the crate uses Antistasi's `lootCrateDistance` parameter again. |
| `auqol_loot_radius` | Slider 10–2000, integer | 2000 | Server | Gather radius in metres around the vehicle or crate. Antistasi's crate parameter only goes to 400. |
| `auqol_loot_caches` | Checkbox | On | Server | Enemy item caches within 30 m of the vehicle or crate are emptied into it as part of the same run. These are the faction `ammobox` crates Antistasi spawns at outposts, bases and airports. The empty box is then deleted. The HQ box and rebel-owned items are never touched. |
| `auqol_loot_enemyRadius` | Slider 10–2000, integer | 100 | Server | Gathering is refused while an enemy in combat mode is within this distance of the vehicle or crate. Antistasi's own check would use the gather radius. |

The action is the crate's own: same text, icon, 2-second hold, on foot within 5 m. Completing it runs Antistasi's `SCRT_fnc_loot_gatherLoot` on the server, so everything else is the crate's behaviour: dead bodies, weapon holders and surrender crates in the radius are emptied into the vehicle, money items are split between rebel players, already-unlocked items follow the mission's "loot crate ignores unlocked items" parameter, and there is a 10-second cooldown per vehicle. Before that, the server checks the request: it must come from the machine of the player who held the action (`remoteExecutedOwner`; a hosting player is local), and that player must be alive, on foot and within 10 m of an object that has the action. A repeat request for the same object within 10 s is refused before any cache is touched. The enemies-nearby check is AUQOL's, with `auqol_loot_enemyRadius`, centred on the vehicle. Antistasi's crate centres it on the host player instead, which on a dedicated server is no position at all. Items are added even past the vehicle's normal cargo capacity, as with the crate.

## Withstand

Needs Antistasi Ultimate with the mission's Withstand self-revive parameter on.

| Setting | Type | Default | Scope | Description |
| --- | --- | --- | --- | --- |
| `auqol_withstand_enabled` | Checkbox | On | Server | Replace the Withstand cooldown. Off: Antistasi's 300 s default. |
| `auqol_withstand_timeout` | Slider 1–300, integer | 1 | Server | Seconds before Withstand can be used again. The after-effects (desaturated screen, aim penalty) last the same time, because Antistasi ties them to the cooldown. |

A cooldown already running when you change the setting finishes at its old length.

## Diagnostics

| Setting | Type | Default | Scope | Description |
| --- | --- | --- | --- | --- |
| `auqol_debug` | Checkbox | Off | Client | Write one RPT line per ejection, refill, ACE source change, garage restore, loot run and stuck-recovery event, on the machine doing it. Every 5 minutes it also writes a `Timing:` line per AUQOL timer with its runs, average and worst time in ms (`diag_tickTime`), so the mod's own cost can be read. |

`call AUQOL_fnc_diagnostics` returns and logs the active integrations on that machine. Run from the debug console, it also prints them to system chat.
