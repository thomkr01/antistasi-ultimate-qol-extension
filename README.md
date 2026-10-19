# Antistasi Ultimate QoL Extension (AUQOL)

A standalone Arma 3 addon that adds quality-of-life features to Antistasi Ultimate without editing any mission file. It needs CBA_A3. ACE3, RHS and CUP are optional, and the mod detects them at runtime.

A full description of each feature and its rules is in [FEATURES.md](FEATURES.md). [FILEMAP.md](FILEMAP.md) lists where everything is in the repo.

| Feature | What it does |
| --- | --- |
| Enemy crew ejection | When an enemy AI land vehicle can no longer move, its living enemy AI occupants are moved out and their group stops using the vehicle. |
| Infinite service stock | Recognized fuel, ammo and repair sources never run out of what they hand out. Services that are already unlimited are left alone. |
| No weapon sway | Removes weapon sway for your own character. |
| Unlimited stamina | Your own character never tires. AI is unchanged. |
| Weight-independent running | Carried weight no longer drains or reserves your stamina. |
| No total weight limit | You can keep picking things up however heavy your load is. Uniform, vest and backpack keep their normal size. |
| Recoil slider | Sets your own character's weapon recoil from 0 to 100%. 100% (vanilla) by default. |
| Loot from any vehicle | Every vehicle gets the loot crate's "Gather Scattered Loot" action, and the vehicle and the crate share one radius you can set up to 2000 m. |
| Short Withstand cooldown | Antistasi's Withstand self-revive cooldown drops from 5 minutes to 1 second, adjustable. |
| Squad gets your perks | No sway, unlimited stamina, weightless running and the recoil setting also apply to the AI in your group. |
| Wounded AI treat themselves | Hurt AI in your group use their first aid kit on themselves at once, and the stale red hurt icon is cleared. |
| Copy from user | A "Copy from user" button in Antistasi's Set Rebel Loadout arsenal loads your own loadout into the role you are editing (unlocked items only). |
| Faster AI reactions | Your squad, and by default every friendly AI (garrisons, static and turret gunners), spot enemies sooner, share sightings faster and turn onto targets quicker. Their accuracy is unchanged. |
| T key alerts your squad | Pressing Reveal target (T) at an enemy makes your whole group know about it, and it becomes your AI's focus. Each new press moves the focus to the new enemy. |
| Squad launchers at once | Squad AI with a loaded AT or AA launcher take it out as soon as they know about an enemy vehicle they can see and hit. |
| Live vehicle markers | Antistasi's markers on convoy objectives, mission vehicles, supply boxes and spotted enemy vehicles follow their vehicle every second instead of once a minute. |
| AI stuck recovery | Friendly AI that have somewhere to go but make no progress are freed step by step: refresh the order, rejoin formation, a short safe hop, and an optional emergency teleport to the squad leader. |
| Faster AI animations | Every AI soldier of every faction moves, turns and acts 25% faster (adjustable 1.0 to 2.0), so it gets to its next decision sooner. Same idea as the Fast Reaction AI (FRAI) mod. |
| Faster pistol swap | Switching to or from your handgun plays twice as fast, and the pistol comes up three times as fast (adjustable). |
| Faster ladders | You climb ladders 1.5 times as fast. Hold the Fast ladder climbing key (Left Shift by default) to climb 2.5 times as fast, or to slide down at 4 times. |
| Smart combat AI | AI squads in a fight move as two fire teams from cover to cover (walls, rocks, trees, inside buildings), clear buildings, flank, lay suppressive fire, throw grenades at hidden enemies and smoke when caught in the open, assault when stronger, defend in place, fight armor as a team, split targets, share sightings with nearby groups, dodge grenades, share magazines and send medics. AI under close fire learn where it came from and get low. Antistasi keeps steering its groups. Stands down when LAMBS Danger or Vcom AI is loaded. |

Every feature has its own CBA setting and can be switched on or off while the mission is running. Everything is on by default (recoil at 100%, which is vanilla) except the emergency teleport and the "unit got stuck" messages.

## Requirements

- Arma 3 2.12 or newer (stable branch). The vanilla `Service` event handler the service feature uses was added in 2.12.
- [CBA_A3](https://github.com/CBATeam/CBA_A3), as a hard dependency (`requiredAddons[] = {"cba_main"}`).
- Antistasi Ultimate is the target mission, but it isn't required to load the addon.

## Installation

1. Download the latest zip from [Releases](https://github.com/thomkr01/antistasi-ultimate-qol-extension/releases) (or build it, see [Building](#building)) and extract `@auqol`.
2. Load it alongside CBA_A3 and Antistasi Ultimate, for example `-mod=@CBA_A3;@AntistasiUltimate;@auqol`.
3. In multiplayer, run it on the server and on every client. Settings that change world state are forced by the server.

More detail is in [docs/installation.md](docs/installation.md).

## CBA settings

Open **Options → Addon Options → Antistasi Ultimate QoL by TchicX**. "Server" settings are synchronized from the server to everyone (`isGlobal = 1`). The only "Client" setting is `auqol_debug`, which each machine sets for itself. Player features (sway, stamina, weight) are still applied on each player's own machine, but the server decides whether they are on.

| Setting | Type | Default | Scope | Purpose |
| --- | --- | --- | --- | --- |
| `auqol_eject_enabled` | Checkbox | On | Server | Eject enemy crew from immobilized vehicles. |
| `auqol_eject_outOfFuel` | Checkbox | On | Server | Count an empty fuel tank as immobilized too. |
| `auqol_service_fuel` | Checkbox | On | Server | Infinite fuel-service stock. |
| `auqol_service_ammo` | Checkbox | On | Server | Infinite ammunition-service stock. |
| `auqol_service_repair` | Checkbox | On | Server | Infinite repair-service stock. |
| `auqol_service_garageFuel` | Checkbox | On | Server | Keep Antistasi garage fuel sources full. Also needs the fuel setting on. |
| `auqol_player_noSway` | Checkbox | On | Server | No weapon sway. |
| `auqol_player_unlimitedStamina` | Checkbox | On | Server | Unlimited stamina. |
| `auqol_player_weightless` | Checkbox | On | Server | Running unaffected by carried weight. |
| `auqol_player_recoil` | Slider 0–100% | 100% | Server | Weapon recoil for your own character. 100% is vanilla, 0% is no recoil. |
| `auqol_player_squad` | Checkbox | On | Server | Also apply the four player settings above to the AI in your group. |
| `auqol_squad_reaction` | Checkbox | On | Server | Faster reactions for the AI in your group (spot time, spot distance, aiming speed, commanding). |
| `auqol_squad_reactionAll` | Checkbox | On | Server | Also give the faster reactions to every friendly AI: garrisons, static and turret gunners, high-command squads. |
| `auqol_squad_reactionSkill` | Slider 0.3–1 | 0.8 | Server | The minimum those four skills are raised to. |
| `auqol_squad_revealKey` | Checkbox | On | Server | Reveal target (T) at an enemy alerts your group and makes it your AI's focus for 30 s; a new press replaces the focus. |
| `auqol_squad_selfTreat` | Checkbox | On | Server | Hurt AI in your group treat themselves with their own first aid kit; light leftover damage (the stale red hurt icon) is cleared. Off under ACE medical. |
| `auqol_squad_selfTreatMedikit` | Checkbox | On | Server | Only clear that light leftover damage (the red hurt icon) on AI that carry a medikit. Off: clear it on every AI. |
| `auqol_squad_launchers` | Checkbox | On | Server | Squad AI switch to a loaded AT or AA launcher as soon as an enemy vehicle they know about is visible and in range. |
| `auqol_anim_ai` | Checkbox | On | Server | Every AI soldier plays its animations faster (moving, turning, stance changes, actions). Players are never sped up. |
| `auqol_anim_aiSpeed` | Slider 1–2 | 1.25 | Server | The AI animation speed. 1.0 is vanilla. |
| `auqol_anim_pistolSwap` | Checkbox | On | Server | Switching to or from your handgun plays faster. |
| `auqol_anim_pistolSwapSpeed` | Slider 1–3 | 2 | Server | The pistol swap speed. |
| `auqol_anim_ladder` | Checkbox | On | Server | Climbing ladders plays faster, and faster still while you hold the Fast ladder climbing key (Left Shift by default, Controls > Configure Addons). |
| `auqol_anim_ladderSpeed` | Slider 1–3 | 1.5 | Server | The ladder speed. |
| `auqol_anim_ladderFastSpeed` | Slider 1–4 | 2.5 | Server | The climbing speed up the ladder while the key is held. |
| `auqol_anim_ladderSlideSpeed` | Slider 1–6 | 4 | Server | The speed down the ladder while the key is held (sliding). |
| `auqol_combat_tactics` | Checkbox | On | Server | AI groups in contact fight as two fire teams that take turns moving to covered spots. Not for groups led by a player. |
| `auqol_combat_buildings` | Checkbox | On | Server | Building positions count as cover, and an enemy inside a building within 80 m is cleared by up to two AI. |
| `auqol_combat_flank` | Checkbox | On | Server | In groups of four or more, the second fire team swings out to one side of the enemy. |
| `auqol_combat_suppressiveFire` | Checkbox | On | Server | Covering AI that can't see the enemy fire at where it was last seen. |
| `auqol_combat_grenades` | Checkbox | On | Server | AI 12 to 35 m from an enemy they can't see throw a hand grenade at it. |
| `auqol_combat_smoke` | Checkbox | On | Server | AI with no cover near and the enemy within 200 m throw smoke first. |
| `auqol_combat_assault` | Checkbox | On | Server | Within 50 m and at least twice the enemy's number, the moving team closes in on it. |
| `auqol_combat_defend` | Checkbox | On | Server | Groups that aren't going anywhere take cover near their leader instead of advancing. |
| `auqol_combat_antiArmor` | Checkbox | On | Server | Against a known tank or APC within 400 m, AT gunners target it and the rest take cover further away. |
| `auqol_combat_spreadTargets` | Checkbox | On | Server | The covering team splits known enemies between them. |
| `auqol_combat_shareContacts` | Checkbox | On | Server | A sighting by a group or your squad is shared with AI groups of the same side within 300 m. |
| `auqol_combat_dodge` | Checkbox | On | Server | AI within 10 m of a thrown grenade run 12 m away from it. |
| `auqol_combat_resupply` | Checkbox | On | Server | AI low on magazines get one from a nearby group mate. |
| `auqol_combat_medics` | Checkbox | On | Server | Group medics treat wounded mates once no enemy is within 60 m. Off under ACE medical. |
| `auqol_combat_range` | Slider 100–1000 m | 500 | Server | How close a known enemy must be for the tactics to run. |
| `auqol_combat_noProne` | Checkbox | On | Server | AUQOL never makes AI go prone (for no-prone AI mods). |
| `auqol_combat_revealShooter` | Checkbox | On | Server | AI that come under close fire make their group aware of the shooter. Every AI, both sides. |
| `auqol_combat_takeCover` | Checkbox | On | Server | Standing AI on foot crouch under close fire, or go prone under heavy fire, then go back to their own stance 10 s after the last close round. Groups led by a player are skipped. |
| `auqol_combat_yieldToAIMods` | Checkbox | On | Server | Turn all smart combat AI off while LAMBS Danger or Vcom AI is loaded. |
| `auqol_map_liveVehicles` | Checkbox | On | Server | Antistasi's vehicle markers follow their vehicle (checked every second while the map or GPS is open, every 10 s otherwise; moved when the vehicle moved more than 5 m). |
| `auqol_freeze_parked` | Checkbox | On | Server | Empty parked vehicles stop being simulated while no player is within 500 m and wake when one comes closer (Arma's dynamic simulation). |
| `auqol_freeze_wrecks` | Checkbox | On | Server | The same for destroyed vehicles that have come to rest. |
| `auqol_loadout_copyFromUser` | Checkbox | On | Server | "Copy from user" button in Antistasi's rebel loadout editor. |
| `auqol_stuck_enabled` | Checkbox | On | Server | Detect and recover stuck friendly AI. |
| `auqol_stuck_scope` | List | Your squad | Server | Which AI to watch: your squad, friendly AI near players, or all friendly AI. |
| `auqol_stuck_scopeRadius` | Slider 50–3000 | 500 | Server | Radius for the "near players" scope, in metres. |
| `auqol_stuck_timeout` | Slider 10–300 | 30 | Server | Seconds without progress before a unit counts as stuck; also the time each step gets. |
| `auqol_stuck_minProgress` | Slider 0.5–20 | 3 | Server | Metres gained toward the destination (or moved, while the unit still reaches new closest points) that count as progress. |
| `auqol_stuck_refreshOrders` | Checkbox | On | Server | Step 1: re-issue the unit's current order. |
| `auqol_stuck_regroup` | Checkbox | On | Server | Step 2: formation followers rejoin formation. |
| `auqol_stuck_reposition` | Checkbox | On | Server | Step 3: short hop onto a checked safe spot toward the destination. |
| `auqol_stuck_teleport` | Checkbox | Off | Server | Step 4: emergency teleport next to the squad leader (infantry only). |
| `auqol_stuck_maxDistance` | Slider 5–500 | 100 | Server | Cap for the hop, and how close the leader must be for a teleport, in metres. |
| `auqol_stuck_cooldown` | Slider 10–600 | 60 | Server | Wait after a failed recovery round, in seconds. |
| `auqol_stuck_maxAttempts` | Slider 1–10 | 3 | Server | Failed rounds before a unit is left alone until it moves by itself. |
| `auqol_stuck_notifyDetect` | Checkbox | Off | Server | System chat line when a unit gets stuck and for each step tried. |
| `auqol_stuck_notifyResult` | Checkbox | On | Server | System chat line when a unit moves again or a round fails. |
| `auqol_loot_enabled` | Checkbox | On | Server | Loot action on every vehicle, with the radius below for vehicles and the loot crate. |
| `auqol_loot_radius` | Slider 10–2000 | 2000 | Server | Loot gather radius in metres. |
| `auqol_loot_enemyRadius` | Slider 10–2000 | 100 | Server | Gathering is refused while an enemy in combat is this close. |
| `auqol_loot_caches` | Checkbox | On | Server | Also empty enemy item caches within 30 m into the vehicle or crate, then delete the empty box. |
| `auqol_withstand_enabled` | Checkbox | On | Server | Replace Antistasi's 5-minute Withstand cooldown. |
| `auqol_withstand_timeout` | Slider 1–300 | 1 | Server | Withstand cooldown in seconds. |
| `auqol_debug` | Checkbox | Off | Client | Write one RPT line per ejection, refill, loot run and stuck-recovery event, and every 5 minutes the average and worst time of each AUQOL timer. |

There is no medical or logistics stock setting because the audit found no depleting medical or logistics service stock to change. See [docs/service-audit.md](docs/service-audit.md). The full reference is in [docs/configuration.md](docs/configuration.md).

## Compatibility

| | Vanilla | Antistasi Ultimate | RHS | CUP | ACE3 |
| --- | --- | --- | --- | --- | --- |
| Crew ejection | Yes | Yes. Respects its surrendered and captive units, and overrides its `allowCrewInImmobile` on immobilized enemy vehicles. | Yes (config-agnostic) | Yes (config-agnostic) | Yes. Respects ACE captives. |
| Fuel service | `transportFuel` cargo | Yes, including garage fuel sources | Yes (vanilla/ACE config) | Yes (vanilla/ACE config) | ACE refuel infinite-source mode |
| Ammo service | `transportAmmo` cargo | Garage sources are already non-depleting | Yes | Yes | Limited mode is topped up. Unlimited and magazine modes are untouched. |
| Repair service | `transportRepair` cargo | Garage sources are already non-depleting | Yes | Yes | ACE repair has no stock, so it is untouched. |
| No sway | `setCustomAimCoef` | Yes | n/a | n/a | ACE sway factor |
| Unlimited stamina | `enableStamina` | Yes | n/a | n/a | ACE Advanced Fatigue duty factor |
| Weightless running | `loadCoef` trait | Yes. Re-applied after Antistasi role traits. | n/a | n/a | ACE movement base `loadCoef` and fatigue carried mass |
| No total weight limit | `maxSoldierLoad` in config | Yes | n/a | n/a | Inventory only. ACE dragging limits are untouched. |
| Recoil slider | `setUnitRecoilCoefficient` | Yes | n/a | n/a | n/a (ACE has no recoil module) |
| Squad perks | Same commands on your group's AI | Yes | n/a | n/a | AI get the vanilla commands, since ACE sway and fatigue only run for players. |
| Squad reactions, T key, launchers | `setSkill`, `reveal`, `doTarget`, `doFire`, `selectWeapon` on your group's AI | Yes. Accuracy stays at Antistasi's rebel training level. | Any launcher, by its ammo's AI usage flags | Any launcher, by its ammo's AI usage flags | Yes |
| Wounded AI treat themselves | Vanilla `HealSoldierSelf` action, `setDamage 0` for light leftover damage | Yes. Skips units Antistasi's medical is handling (incapacitated, `helped`, `helping`). Clears the 0.25 Antistasi's non-medic revive leaves. | Their first aid kits work (kits are found by item type) | Their first aid kits work | Off under ACE medical (ACE's medical AI treats AI) |
| Live vehicle markers | n/a | Moves the markers of Antistasi's `A3A_fnc_vehicleMarkers` | Any vehicle | Any vehicle | Yes |
| Copy from user | n/a | Rebel loadout editor (Antistasi Ultimate only) | Any unlocked RHS gear | Any unlocked CUP gear | n/a |
| Faster AI animations, pistol swap, ladders | `setAnimSpeedCoef` | Yes | Any unit and any animation that follows the vanilla state names | Same | Ladder and pistol boosts register in ACE Advanced Fatigue's animation-speed exclusions. ACE medical's reset of a medic is re-applied within 15 s. |
| Smart combat AI | `EnemyDetected` and `Suppressed` events, `doMove`, `doFollow`, `setUnitPos`, `doSuppressiveFire`, `forceWeaponFire` | Never touches group waypoints, behaviour, combat mode, formation or speed, so Antistasi's PATCOM keeps steering its groups. Skips garrisons, statics and every unit Antistasi has busy, and pauses during Antistasi's kill reaction. | Any unit, any grenades (found by ammo type) | Same | Yes |
| AI stuck recovery | Engine AI commands | Leaves garrisons, patrols, HOLD/GUARD waypoints, incapacitated, surrendered, healing and rearming units alone | Any infantry or land vehicle | Any infantry or land vehicle | Respects ACE unconscious state (`lifeState`). |

Details and reasoning are in [docs/compatibility.md](docs/compatibility.md).

## How it works

- **Ejection** listens to the global `Dammaged`, `Fuel` and `GetIn` events on land vehicles, excluding static weapons, and acts only on the machine where the vehicle is local. That can be the server, a headless client or a player. A vehicle counts as immobilized when `canMove` is false, or, if enabled, when its fuel is exactly 0. Parked or waiting vehicles never qualify. The mod waits until the vehicle is below 3 km/h, then moves each eligible unit out on the machine that owns it, with `unassignVehicle`, `moveOut` and `leaveVehicle`. Nothing is damaged and ownership is unchanged.
- **Service stock** refills only the service cargo (`setFuelCargo`, `setAmmoCargo`, `setRepairCargo`) of objects whose config declares that service. It refills from the vanilla `Service` event while a vehicle is being serviced, and once when the object appears. A fuel truck's own engine fuel is never touched. Under ACE it uses ACE's own APIs instead.
- **Player features** are applied on settings change, on respawn or unit change (and again 3 seconds later, because Antistasi re-applies role traits shortly after respawn without raising an event), on loadout and group changes, and by a 15-second fallback re-check. They only restore values AUQOL itself changed.
- **Loot** adds a copy of the crate's hold action to vehicles and swaps it in on the crate. Completing it asks the server to run Antistasi's own `SCRT_fnc_loot_gatherLoot`, the crate's function, with the AUQOL radius. The server first checks the request: it must come from the machine of the player who held the action, and that player must be alive, on foot and within 10 m of a vehicle or crate that has the action. A second request for the same object within 10 s is refused, so a double send can't empty caches or run the gather twice. The 10-second cooldown, unlocked-item rule and money split are Antistasi's. Enemy item caches within 30 m (the supply crates at outposts, bases and airports) are emptied into a weapon holder first, so the same run picks their contents up, and the empty box is deleted. The enemies-nearby check is done by AUQOL with its own radius, using Antistasi's `A3A_fnc_enemyNearCheck`.
- **Withstand** sets `A3A_selfReviveTimeout`, the cooldown Antistasi's `A3A_fnc_selfRevive` reads, which defaults to 300 s.
- **Squad perks** run in the same player re-check over the AI in your group that are local to your machine. A recruit gets them the moment it joins (the group's `UnitJoined` event), with the 15-second re-check as fallback.
- **AI reactions** run every 5 seconds on every machine (server, headless clients, players) for the friendly AI local to it, and only raise skills that are below the floor, remembering the old values for when the setting is turned off. Those values are a public variable on the unit, so they stay correct when a unit moves between the server and a headless client. **The T key** is the engine's own Reveal target action, caught with `addUserActionEventHandler`. **Launchers** are checked when your group spots a new enemy (the group's `EnemyDetected` event), when you press T, and every 5 seconds as a fallback for targets that only become visible later. The T key and launchers only touch AI in your own group that are local to your machine.
- **Live vehicle markers** run every second on each player's machine over the markers already tracked, and only move a marker when its vehicle moved more than 5 m. New markers come from the `MarkerCreated` event, with a full marker scan every 30 seconds as fallback. Antistasi still creates and deletes the markers; AUQOL only moves them to their vehicle.
- **Copy from user** waits for Antistasi's loadout editor to finish opening, then turns the editor's empty third bottom-bar button into "Copy from user". It takes the loadout you wore when you opened the editor, drops anything the arsenal does not have unlimited (weapons stored in the uniform, vest or backpack are checked attachment by attachment and magazine by magazine too), and loads the rest through Antistasi's own "load this role" step, which switches the slot overrides on. Nothing is saved until you press Save.
- **AI stuck recovery** checks every 5 seconds, on each machine, only the AI local to that machine. For the wider scopes it keeps a list of that machine's friendly AI, rebuilt every 30 seconds and pruned on every check, instead of going through every unit each time. A unit is watched only while it has a destination more than 8 m away (25 m in a vehicle) and nothing else to do, and is stuck after the timeout with no progress. Units that are fighting, in COMBAT behaviour, healing, rearming, surrendered or captive, on a static weapon, attached, remote controlled or playing a scripted animation are never moved, and that is checked again right before any hop or teleport. Steps are tried one per timeout window, cheapest first; after the last enabled step the round fails, a cooldown follows, and after the maximum number of rounds the unit is left alone. Tracking is a variable on the unit, so nothing piles up over a long campaign. Details in [FEATURES.md](FEATURES.md#12-ai-stuck-recovery).
- **No total weight limit** raises the engine's total soldier load cap (`maxSoldierLoad`, vanilla 1000) to 10,000,000 in config. That cap is what stops you adding items once you carry something heavy. Each container's own size is unchanged.

There are no per-frame handlers. The AI animation speed has a 15-second pass on every machine that only writes when a unit's speed is off. The only timers are a 1-second check of tracked live vehicle markers and a 5-second launcher fallback on each player's machine, the 15-second player fallback re-check, a 5-second AI reaction pass on every machine, the 5-second stuck-AI check, a 10-second garage-fuel check (fuel sources only, writes only when a source is not full), and a 30-second ACE rearm top-up, which runs only in ACE limited-supply mode.

## Diagnostics

`call AUQOL_fnc_diagnostics` (debug console) prints which integrations are active on that machine. The same report is written to the RPT once at mission start. Turn on `auqol_debug` for per-action lines.

## Building

Builds use [HEMTT](https://github.com/BrettMayson/HEMTT):

```sh
tools/build.sh          # Linux/macOS: static checks + hemtt check + hemtt release
pwsh tools/build.ps1    # Windows
```

The release zip ends up in `releases/`. Without Arma 3 Tools, HEMTT signs the PBOs with its own key and prints a warning about Arma 3 Tools. That warning is harmless. See [docs/testing.md](docs/testing.md) for what is validated statically and what has to be tested in game.

## Known limitations

- Static weapons, aircraft and boats are never ejected. Ejecting from aircraft in flight would kill the crew.
- An overturned vehicle with no damage is left to the engine, which ejects crews from upside-down vehicles on its own.
- ACE rearm's "magazine supply" mode is a stockpile of specific magazines and is not made infinite.
- ACE limited rearm supply is set to 1,000,000 points and topped up every 30 seconds. ACE raises no event when supply is used, so this is effectively infinite rather than literally infinite.
- The total weight limit is a config value, so it applies to every unit, AI included, and has no in-game switch. Script can't change it per unit. See [docs/configuration.md](docs/configuration.md#total-weight-limit).
- Loot and Withstand need Antistasi Ultimate. Withstand also needs the mission's Withstand self-revive parameter turned on.
- The stuck check can't see why the engine's pathfinding failed, only that a unit with a destination made no progress. A unit that is legitimately waiting with a destination set (for example behind a closed gate a player will open) can be nudged. Raise the timeout if that happens.
- The emergency teleport is off by default, infantry only, and only to a leader within the maximum distance. Vehicles are only ever moved by the short hop.
- The T key and the launcher switch only cover AI in your own group. Faster reactions also cover all friendly AI unless `auqol_squad_reactionAll` is off. Enemy AI are never changed.
- The T key only alerts the squad about enemies. Your AI then fire under their current combat mode, so Hold fire still holds. Only the group leader's T press makes the AI focus the target, for 30 s or until it dies or you press T on another enemy.
- Self-treatment only covers AI in your own group, on foot, with a first aid kit (or a medikit for medics) for real wounds. It is off under ACE medical, whose own AI medical handles it.
- SQF scripts run on one thread per machine, so no mod can spread its scripts over CPU cores. AUQOL keeps its work event-driven instead, and the engine already runs AI, physics and rendering on its own threads.
- Freezing parked vehicles and wrecks uses Arma's dynamic simulation. Only players wake a frozen vehicle, so AI more than 500 m from every player find it as it was left. If the mission or another mod already runs dynamic simulation, AUQOL keeps its distances (the default wake distance for empty vehicles is then 250 m instead of 500 m).
- Live vehicle markers only speed up the markers Antistasi already shows. Player markers already update every second, and zone markers change when a zone changes hands. Intercepted enemy support markers keep Antistasi's 5-second update because the server owns them. Nothing new is revealed.
- Antistasi stores no link between a vehicle marker and its vehicle, so AUQOL pairs each marker with the nearest vehicle of the matching kind when it appears. In a tight convoy of same-kind vehicles two markers can still swap; Antistasi's own once-a-minute update then shows the swap and AUQOL re-pairs the marker, so a wrong pairing lasts at most about a minute.
- "Copy from user" keeps only items the arsenal has unlimited. Items with a limited count, and slots holding locked items, are left to Antistasi's random pick, and the chat line lists them.
- Animation speed (`setAnimSpeedCoef`) doesn't change reloading or other upper-body animations; that is an engine limit. Faster AI animations therefore don't speed up AI reloads.
- The pistol swap and ladder boosts recognise animations by their vanilla-style names (a weapon switch with `wpst` on one side, any state with `ladder` in it). Addon animations named differently play at normal speed.
- Smart combat AI moves group members, never the leader, so the group still goes where Antistasi (or the mission) sends it; members fight from cover around that. Cover is judged by a line from where the group believes the enemy is, so cover against a second enemy elsewhere is not guaranteed. It does not retreat or call for help: Antistasi does that.
- With infinite stock, selling a fuel or ammo utility item back to the Antistasi garage always refunds its full price, because Antistasi refunds based on the remaining stock.

Troubleshooting is in [docs/installation.md](docs/installation.md#troubleshooting).

## License

MIT, see [LICENSE](LICENSE). This project contains no code from Antistasi Ultimate, CBA_A3 or ACE3. It only calls their public functions at runtime.
