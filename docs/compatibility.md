# Compatibility

## Dependencies

| Mod | Required? | How it is referenced |
| --- | --- | --- |
| CBA_A3 | **Yes** | `requiredAddons[] = {"cba_main"}`, the same dependency class ACE3 declares. It provides the settings (`CBA_fnc_addSetting`), XEH (`Extended_PreInit_EventHandlers`, `Extended_PostInit_EventHandlers`, `CBA_fnc_addClassEventHandler`), events (`CBA_fnc_addEventHandler`, `CBA_fnc_targetEvent`, `CBA_fnc_serverEvent`, `CBA_fnc_addPlayerEventHandler`) and timers (`CBA_fnc_addPerFrameHandler` with a delay, `CBA_fnc_waitAndExecute`, `CBA_fnc_waitUntilAndExecute`). |
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
| Carrying capacity | `setMaxLoad` on worn containers, run on the server | Antistasi's loadout screen draws its bars from config capacity, so it can show more than 100% | n/a | n/a | ACE dragging and carrying of objects is untouched |

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
| Carrying capacity | `setMaxLoad` ("should be executed on the server") | The client asks with `CBA_fnc_serverEvent`. The server applies its own multiplier, only to player units. |
| Sway, stamina, loadCoef | `setCustomAimCoef` (local), `enableStamina` (local arg), `setUnitTrait` (local arg) | The player's own client |

AUQOL uses no `remoteExec` of its own. All cross-machine calls are named CBA events with fixed handlers, so a client can't make another machine run arbitrary code through them.
