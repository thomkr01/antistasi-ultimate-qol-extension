# Configuration

All settings are under **Options → Addon Options → Antistasi Ultimate QoL by TchicX**. They can also be put in a CBA settings file, `cba_settings.sqf`, for example `force auqol_capacity_multiplier = 100;`.

**Scope.** Settings marked *Server* are registered with `isGlobal = 1`. The server's value is shared with every client, because the code they control runs on whichever machine owns the object, and that has to be the same everywhere. Settings marked *Client* are registered with `isGlobal = 0`. Each player chooses for themselves, unless the server admin forces a value.

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
| `auqol_player_noSway` | Checkbox | On | Client | No weapon sway. Uses vanilla `setCustomAimCoef 0`, or an ACE sway multiplier of 0 when ACE sway is active. |
| `auqol_player_unlimitedStamina` | Checkbox | On | Client | Uses vanilla `enableStamina false`, or an ACE Advanced Fatigue duty factor of 0 when ACE fatigue is active. |
| `auqol_player_weightless` | Checkbox | On | Client | Sets the `loadCoef` trait to 0, including ACE movement's saved base value, and gives ACE Advanced Fatigue a carried mass of 0. |

These only ever affect the local player's unit. AI is not changed.

## Carrying capacity

| Setting | Type | Default | Scope | Description |
| --- | --- | --- | --- | --- |
| `auqol_capacity_enabled` | Checkbox | On | Server | Turn the multiplier on or off. |
| `auqol_capacity_multiplier` | Slider 1–1000, integer | 1000 | Server | Each worn container's capacity becomes its config capacity (`getContainerMaxLoad`) times this value. |

**Which capacity systems are affected:**

| System | Affected? | Why |
| --- | --- | --- |
| Vanilla uniform, vest and backpack containers | Yes | `setMaxLoad` on each worn container. It runs on the server, as the command requires, and persists for JIP. |
| Vanilla total soldier load (`CfgInventoryGlobalVariable >> maxSoldierLoad`, 1000) | Yes, to 9999 | It is a static config value, and the wiki states unit max load cannot be set by script, so `config.cpp` sets it. It applies to every unit, AI included, and also lowers how much weight drains vanilla stamina for everyone. It has no runtime switch: remove the mod to undo it. |
| ACE carrying and dragging of objects (`ace_dragging_weightCoefficient`) | No | That is a separate, global ACE setting for objects you carry by hand, not inventory capacity. Server admins can change it in ACE's own settings. |
| Antistasi arsenal restrictions | No | These are unlock counts, not capacity. |
| Antistasi logistics (vehicle cargo nodes) | No | Vehicle cargo slots are a separate mechanic. |

Containers you drop or swap go back to their normal capacity. Their contents stay as they are, so a container may now hold more than its normal capacity until items are removed. The multiplier is clamped to 1–1000, and the slider only allows integers, so there are no overflow or invalid values: the largest vanilla backpack times 1000 is well within float precision.

## Loot gathering

Needs Antistasi Ultimate. Without it the action is not added.

| Setting | Type | Default | Scope | Description |
| --- | --- | --- | --- | --- |
| `auqol_loot_enabled` | Checkbox | On | Server | Adds the loot crate's "Gather Scattered Loot" hold action to every land vehicle, aircraft and boat (not static weapons), and makes vehicles and the loot crate use `auqol_loot_radius`. Off: vehicles lose the action and the crate uses Antistasi's `lootCrateDistance` parameter again. |
| `auqol_loot_radius` | Slider 10–2000, integer | 2000 | Server | Gather radius in metres around the vehicle or crate. Antistasi's crate parameter only goes to 400. |
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
| `auqol_debug` | Checkbox | Off | Client | Write one RPT line per ejection, refill, ACE source change, garage restore and capacity change, on the machine doing it. |

`call AUQOL_fnc_diagnostics` returns and logs the active integrations on that machine. Run from the debug console, it also prints them to system chat.
