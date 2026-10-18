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
- If eligible crew are aboard, ejection waits until the vehicle is below 3 km/h, for up to 8 seconds, so nobody is dropped out at speed. After that it retries at most 3 times, then waits for the next event. A per-vehicle pending flag prevents duplicate scheduling. There is no loop.

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
| `auqol_player_noSway` | Checkbox | On | Server | No weapon sway. Uses vanilla `setCustomAimCoef 0`, or an ACE sway multiplier of 0 when ACE sway is active. |
| `auqol_player_unlimitedStamina` | Checkbox | On | Server | Uses vanilla `enableStamina false`, or an ACE Advanced Fatigue duty factor of 0 when ACE fatigue is active. |
| `auqol_player_weightless` | Checkbox | On | Server | Sets the `loadCoef` trait to 0, including ACE movement's saved base value, and gives ACE Advanced Fatigue a carried mass of 0. |
| `auqol_player_noRecoil` | Checkbox | Off | Server | `setUnitRecoilCoefficient 0` on your own character, back to 1 when turned off. |
| `auqol_player_squad` | Checkbox | On | Server | Also apply the four settings above to the AI in your group that are local to your machine. AI always get the vanilla commands (`setCustomAimCoef`, `enableStamina`, `loadCoef`, `setUnitRecoilCoefficient`), because ACE sway, Advanced Fatigue and movement only run for players. Off restores the AI values AUQOL changed. |

With `auqol_player_squad` off these only affect the local player's unit. With it on they also cover the AI in your own group, re-checked every 5 seconds so new recruits are included. AI outside your group are never changed. An AI that leaves your group keeps the values it had (Antistasi normally deletes dismissed AI).

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
| `auqol_stuck_minProgress` | Slider 0.5–20 | 3 | Server | Moving this many metres from where the current window started, or getting this much closer to the destination, counts as progress and resets everything. |
| `auqol_stuck_refreshOrders` | Checkbox | On | Server | Step 1: re-issue the current order to the same place (`doMove`, `setCurrentWaypoint` on the current waypoint, or `doFollow` the leader). |
| `auqol_stuck_regroup` | Checkbox | On | Server | Step 2, formation followers only: `doWatch objNull`, `doStop`, `doFollow` the leader. |
| `auqol_stuck_reposition` | Checkbox | On | Server | Step 3: a hop of up to 10 m (25 m for a driven vehicle) toward the destination or leader, onto a checked spot, then step 1 again. |
| `auqol_stuck_teleport` | Checkbox | Off | Server | Step 4, infantry only: to a checked spot within 15 m of the squad leader, when the leader is within `auqol_stuck_maxDistance`. |
| `auqol_stuck_maxDistance` | Slider 5–500 | 100 | Server | Upper limit for the hop, and the furthest the leader may be for a teleport. |
| `auqol_stuck_cooldown` | Slider 10–600 | 60 | Server | After every enabled step failed (one round), wait this long before the next round. |
| `auqol_stuck_maxAttempts` | Slider 1–10 | 3 | Server | Failed rounds before the unit is left alone until it moves again by itself. |
| `auqol_stuck_notifyDetect` | Checkbox | Off | Server | System chat when a unit gets stuck (with the likely reason) and for each step tried. |
| `auqol_stuck_notifyResult` | Checkbox | On | Server | System chat when a unit moves again, and when a round fails or the unit is given up on. |

**Checks.** Every 5 seconds each machine (server, headless clients, players) checks the AI local to it in the chosen scope. A unit local to one machine is never checked anywhere else, so recovery never runs twice. The full list of skipped states is in [FEATURES.md](../FEATURES.md#12-ai-stuck-recovery). In short: a unit is watched only with a destination more than 8 m away (25 m driving), only a move or follow order, not fighting, not down, surrendered, healing or rearming, on the ground and dry, and, in AI-led groups, not holding, guarding or patrolling.

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
| `auqol_loot_enemyRadius` | Slider 10–2000, integer | 500 | Server | Gathering is refused while an enemy in combat mode is within this distance of the vehicle or crate. Antistasi's own check would use the gather radius. |

The action is the crate's own: same text, icon, 2-second hold, on foot within 5 m. Completing it runs Antistasi's `SCRT_fnc_loot_gatherLoot` on the server, so everything else is the crate's behaviour: dead bodies, weapon holders and surrender crates in the radius are emptied into the vehicle, money items are split between rebel players, already-unlocked items follow the mission's "loot crate ignores unlocked items" parameter, and there is a 10-second cooldown per vehicle. The enemies-nearby check is AUQOL's, with `auqol_loot_enemyRadius`, centred on the vehicle. Antistasi's crate centres it on the host player instead, which on a dedicated server is no position at all. Items are added even past the vehicle's normal cargo capacity, as with the crate.

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
| `auqol_debug` | Checkbox | Off | Client | Write one RPT line per ejection, refill, ACE source change, garage restore, loot run and stuck-recovery event, on the machine doing it. |

`call AUQOL_fnc_diagnostics` returns and logs the active integrations on that machine. Run from the debug console, it also prints them to system chat.
