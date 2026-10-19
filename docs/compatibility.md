# Compatibility

## Dependencies

| Mod | Required? | How it is referenced |
| --- | --- | --- |
| CBA_A3 | **Yes** | `requiredAddons[] = {"cba_main"}`, the same dependency class ACE3 declares. It provides the settings (`CBA_fnc_addSetting`), XEH (`Extended_PreInit_EventHandlers`, `Extended_PostInit_EventHandlers`, `CBA_fnc_addClassEventHandler`), events (`CBA_fnc_addEventHandler`, `CBA_fnc_targetEvent`, `CBA_fnc_addPlayerEventHandler`) and timers (`CBA_fnc_addPerFrameHandler` with a delay, `CBA_fnc_waitAndExecute`, `CBA_fnc_waitUntilAndExecute`). |
| Antistasi Ultimate | No (the target mission) | Runtime only: `teamPlayer`, the unit variable `surrendered`, `A3A_hasAce`, and garage globals (`HR_GRG_Vehicles`, `HR_GRG_Sources`, `HR_GRG_fnc_broadcastStateUpdate`, `HR_GRG_fnc_declairSources`). Each is checked with `isNil` or a default before use. |
| ACE3 | No | Runtime only, guarded by `isNil` on each function and by ACE's own `*_enabled` settings. |
| RHS (AFRF, USAF, GREF, SAF) | No | No direct references. Their service vehicles use vanilla and ACE config fields, see [service-audit.md](service-audit.md#rhs-and-cup). |
| CUP Vehicles | No | Same as RHS. |

With only CBA loaded, every feature works on vanilla mechanics. The ejection fallback for "hostile" uses the players' own sides when Antistasi's `teamPlayer` is not defined.

## Matrix

| Feature | Vanilla | Antistasi Ultimate | RHS | CUP | ACE3 |
| --- | --- | --- | --- | --- | --- |
| Enemy crew ejection | `canMove`, `fuel`; `Dammaged`, `Fuel` and `GetIn` events | Rebel side `teamPlayer`. Skips `surrendered` and captive units, so convoy prisoners and POWs stay put. Antistasi sets `allowCrewInImmobile true` on armour and QRF vehicles, which keeps crews inside immobile vehicles. AUQOL deliberately moves them out anyway, because that is the feature. | Any `LandVehicle` | Any `LandVehicle` | Skips `ace_captives_isHandcuffed` / `ace_captives_isSurrendering` units |
| Fuel stock | `setFuelCargo` | Field service through the vanilla or ACE path. Garage fuel sources are restored on the server. | Covered by config | Covered by config | `ace_refuel_fnc_makeSource` with -10 (infinite) |
| Ammo stock | `setAmmoCargo` | Garage ammo sources already don't deplete, so they are untouched | Covered by config | Covered by config | Mode 1 topped up through `ace_rearm_fnc_setSupplyCount`. Modes 0 and 2 untouched. |
| Repair stock | `setRepairCargo` | Garage repair sources already don't deplete, so they are untouched | Covered by config | Covered by config | ACE repair has no stock, so it is untouched |
| No sway | `setCustomAimCoef 0` (local argument, local effect) | n/a | n/a | n/a | When `ace_common_enableSway` is on, ACE re-applies the coefficient every 0.5 s, so AUQOL adds a sway multiplier of 0 with `ace_common_fnc_addSwayFactor` instead |
| Unlimited stamina | `enableStamina false` (local argument, global effect) | n/a | n/a | n/a | ACE Advanced Fatigue disables vanilla stamina itself. AUQOL adds a duty factor of 0 with `ace_advanced_fatigue_fnc_addDutyFactor`, which is ACE-internal (see below). |
| Weightless running | `setUnitTrait ["loadCoef", 0]` | Antistasi sets `loadCoef` 1.2–1.4 by role in `A3A_fnc_unitTraits` after respawn. The 5-second re-check re-applies 0 and remembers Antistasi's value for when the setting is turned off. | n/a | n/a | ACE movement rebuilds `loadCoef` from `ace_movement_loadCoef` on every loadout change, so that base is set to 0 too. ACE fatigue reads carried mass from `ace_movement_totalLoad`, which AUQOL keeps at 0 from its duty factor hook. |
| No total weight limit | `maxSoldierLoad` in config | n/a | n/a | n/a | ACE dragging and carrying of objects is untouched |
| Recoil slider | `setUnitRecoilCoefficient` (slider value) on the local player | n/a | n/a | n/a | ACE has no recoil feature |
| Squad perks | The same four commands on AI in the player's group that are local to the player | Recruits are local to the recruiting player, so they are covered | n/a | n/a | AI always get the vanilla commands: ACE sway, Advanced Fatigue and movement only run for players |
| Squad reactions, T key, launchers | `setSkill`, `addUserActionEventHandler` (`revealTarget`), `reveal`, `doTarget`, `doFire`, `getAttackTarget`, `targets`, `checkVisibility`, `selectWeapon` | Raises only reaction skills above Antistasi's `A3A_fnc_FIAinit` values; accuracy stays tied to rebel training | Any launcher: AT/AA comes from the ammo's `aiAmmoUsageFlags` | Same | Works the same; ACE does not change AI skills or the Reveal target key |
| Wounded AI treat themselves | Vanilla `HealSoldierSelf` and `setDamage 0` on the AI of the player's group | Leaves units alone while Antistasi's medical runs (`incapacitated`, `helped`, `helping`, `surrendered`). Clears the 0.25 damage a non-medic revive (`A3A_fnc_actionRevive`) leaves | Kits found by item type 401/619, so their kits work | Same | Off when `ace_medical_engine` is loaded; ACE's medical AI handles AI treatment |
| Faster AI animations, pistol swap, ladders | `setAnimSpeedCoef` (global argument, local effect) | Antistasi doesn't set animation speed | Any unit | Any unit | ACE Advanced Fatigue resets a player's speed to 1 every second unless `ace_advanced_fatigue_setAnimExclusions` has an entry, so AUQOL adds `auqol` there while a ladder or pistol boost lasts. ACE medical sets a medic to 1 after treatment; the 15 s pass re-applies the AI speed. |
| Smart combat AI | `EnemyDetected` and `Suppressed` events, `getHideFrom`, `lineIntersectsSurfaces`, `nearestTerrainObjects`, `buildingPos`, `doMove`, `doFollow`, `setUnitPos`, `doSuppressiveFire`, `forceWeaponFire`, `reveal` | Never touches PATCOM's waypoints, behaviour, combat mode, formation or speed, never moves the leader. Skips units with `PATH`/`MOVE` off (garrisons, `A3A_fnc_chargeWithSmoke`), stopped, `incapacitated`, `surrendered`, `helping`, `helped`, `rearming`, and move orders it didn't give (`A3A_fnc_unitGetToCover`); pauses while `A3A_reactingToKill` is set. Reads `PATCOM_Patrol_Params` only to tell a defending group. Medics leave downed units to Antistasi's revive; magazine sharing is separate from its `A3A_fnc_autoRearm`. Only changes units whose `unitPos` is "Auto" | Any unit | Any unit | Yes. Stands down when LAMBS Danger (`lambs_danger`) or Vcom AI (`VCOM_AI`) is loaded, unless `auqol_combat_yieldToAIMods` is off |
| Live vehicle markers | `setMarkerPosLocal` | Moves the local markers of `A3A_fnc_vehicleMarkers` (convoys, mission vehicles, supply boxes, revealed enemy vehicles) | Any vehicle | Any vehicle | n/a |
| Copy from user | `getUnitLoadout` data, `BIS_fnc_baseWeapon` | Antistasi's rebel loadout editor: reuses its `applyInitialLoadout` step, its `OverrideTab` switches and `commanderLoadout`; reads `rebelLoadouts` and the arsenal's `jna_dataList` (-1 = unlimited) | Any unlocked RHS item | Any unlocked CUP item | n/a |
| AI stuck recovery | `expectedDestination`, `currentCommand`, `stopped`, `doMove`, `doFollow`, `doStop`, `setCurrentWaypoint`, `findEmptyPosition`, `setPosATL`, `setVehiclePosition` | Skips Antistasi `incapacitated`, `surrendered`, `helping` (medic busy) and `rearming` (auto-rearm) units, garrisons (stopped or no destination), patrol routes and HOLD/GUARD waypoints. Antistasi orders are never replaced: only the order a unit already has is re-issued. | Any infantry and any `LandVehicle` | Any infantry and any `LandVehicle` | ACE unconscious units have `lifeState` "INCAPACITATED" and are skipped |

Loot and Withstand use only Antistasi Ultimate: `SCRT_fnc_loot_gatherLoot`, the `lootActionID` variable and the action text of `SCRT_fnc_loot_addActionLoot`, the `lootCrateDistance` parameter, the faction's `lootCrate` and `ammobox` classes, the `boxX` HQ box, the `A3A_canGarage` variable, and the `A3A_selfReviveTimeout` value `A3A_fnc_selfRevive` reads. Without Antistasi both features do nothing. "Copy from user" also needs Antistasi Ultimate (its loadout editor); without it the button is never added. Stuck recovery, squad perks, squad reactions, the T key and squad launchers work in any mission. Live vehicle markers only do something with Antistasi's vehicle markers.

## ACE APIs used

| Function or variable | Public? | Used for |
| --- | --- | --- |
| `ace_refuel_fnc_makeSource`, `ace_refuel_fnc_setFuel` | Yes (`refuel-framework.md`) | Infinite fuel sources |
| `ace_rearm_fnc_getSupplyCount`, `ace_rearm_fnc_setSupplyCount` | Yes (`rearm-framework.md`) | Limited-mode supply top-up |
| `ace_common_fnc_addSwayFactor` | Yes (`Public: Yes` in its header) | No sway |
| `ace_advanced_fatigue_fnc_addDutyFactor` | No (`Public: No`). ACE Advanced Fatigue itself uses it for its medical, dragging and weather factors. | Unlimited stamina, weightless running |
| `ace_movement_loadCoef`, `ace_movement_totalLoad` (unit variables) | Internal | Weightless running |
| `ace_refuel_enabled`, `ace_rearm_enabled`, `ace_rearm_supply`, `ace_repair_enabled`, `ace_advanced_fatigue_enabled`, `ace_common_enableSway` | CBA settings | Choosing the vanilla or ACE path |

If an ACE function is missing, AUQOL logs one warning and leaves that ACE path unchanged. The internal ones are the most likely to change between ACE releases.

## Multiplayer and locality

| Action | Command locality | Where AUQOL runs it |
| --- | --- | --- |
| Detect immobilization | `canMove` (global argument), `Dammaged` / `Fuel` / `GetIn` (global events) | Every machine adds the handlers. Only the vehicle's owner acts. |
| Eject a unit | `unassignVehicle` (local arg), `moveOut` (global arg), `leaveVehicle` (local group) | `CBA_fnc_targetEvent` to the unit's owner. `leaveVehicle` only runs if the group is local there. |
| Refill vanilla cargo | `setFuelCargo` / `setAmmoCargo` / `setRepairCargo` (local arg, global effect) | The service object's owner, either directly or through `CBA_fnc_targetEvent`, throttled to once per 2 s per object |
| ACE refuel and rearm sources | `makeSource` (server only), `setSupplyCount` (public variable) | Server |
| Antistasi garage | Garage state lives on the server | Server |
| Sway, stamina, loadCoef, recoil | `setCustomAimCoef` (local), `enableStamina` (local arg), `setUnitTrait` (local arg) | The player's own client, for the player and the AI of their group local to it |
| AI animation speed | `setAnimSpeedCoef` (local effect) | Every machine, for every AI, on spawn and every 15 s |
| Pistol swap and ladder boost | `setAnimSpeedCoef` (local effect) | The player's client decides, then a CBA global event applies it on every machine |
| Smart combat AI | `Suppressed` (local argument), `EnemyDetected` (group), `doMove`/`setUnitPos`/`doSuppressiveFire`/`forceWeaponFire` (local arg) | Every machine adds the handlers; only the group's owner (server, headless client) runs its 3 s pass, and only for members local to it |
| Faster AI reactions | `setSkill` (local arg) | Every machine, for the friendly AI local to it (squad AI on the player, garrisons on the server or a headless client), so each unit is handled once by its owner |
| T key, launchers | `doTarget`, `doFire`, `selectWeapon` (local arg), `reveal` (local effect) | The player's own client, for the AI of their group local to it |
| Self-treat | `action` `HealSoldierSelf`, `setDamage`, `Dammaged` handler | The player's own client, for the AI of their group local to it |
| Live vehicle markers | `setMarkerPosLocal` (local effect) on Antistasi's local markers | Each player's own client |
| Freeze parked vehicles and wrecks | `enableDynamicSimulation` (server only), `enableDynamicSimulationSystem` (global effect) | Server |
| Copy from user | UI only; edits Antistasi's editor state on the client and restores `rebelLoadouts` straight away | The player's own client. Antistasi's Save button publishes the result as usual. |
| Stuck checks and recovery | `expectedDestination`, `doMove`, `doFollow`, `doWatch`, `setCurrentWaypoint` (local arg); `doStop`, `setPosATL`, `setVehiclePosition` (global) | The machine the AI is local to: each machine only checks its own AI, so one unit is never handled twice. Messages to a player on another machine go through the `auqol_stuck_message` CBA target event. |

Cross-machine calls are named CBA events with fixed handlers, with one exception: the loot request is `remoteExecCall ["AUQOL_fnc_lootGather", 2]`, because a CBA server event does not tell the server who sent it and `remoteExecutedOwner` does. Antistasi Ultimate's `CfgRemoteExec` allows all functions (mode 2), the same way its own loot crate calls `SCRT_fnc_loot_gatherLoot`, and the static checks fail if that changes. The server checks the sender, the player and the object before anything is moved or deleted. With mode 2 any client can still call any function directly, so this protects against bad or stale requests, not against a cheating client.

AI reaction skills are saved in a public unit variable (`auqol_reactSkills`), so a unit that Antistasi moves between the server and a headless client keeps its true original values, and the new owner restores them when the feature is turned off.
