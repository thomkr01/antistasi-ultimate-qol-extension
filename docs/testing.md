# Testing

The Arma 3 engine can't run in CI or in the environment this mod was written in. Validation is split into static checks, which run automatically, and in-game tests, which a person has to run. Nothing in this repository claims an in-game result that nobody observed.

## In-game results

Reported by Thomas on 2026-10-18 (version 1.4.0, Antistasi Ultimate):

| Feature | Result |
| --- | --- |
| No weapon sway | Works |
| No recoil | Works |
| Unlimited stamina and weightless running | Works |
| No total weight limit | Works |
| Infinite service stock | Works |
| Loot from vehicles and the loot crate | Works |
| Enemy crew ejection | Not reported yet |
| Short Withstand cooldown | Not reported yet |
| Item caches within 30 m | Not reported separately |

Details such as single player, hosted or dedicated, and whether ACE was loaded, were not reported.

## Static checks

Run all of them with `tools/build.sh --sources <dir>`. CI (`.github/workflows/ci.yml`) runs the same steps on every push.

| Check | Tool | What it catches |
| --- | --- | --- |
| Config preprocess and rapify | `hemtt check --pedantic --error-on-all` | Config syntax errors, bad macros, unknown includes |
| SQF compile and lints | `hemtt check --pedantic --error-on-all` | SQF syntax errors and HEMTT's SQF lints, with warnings treated as errors |
| PBO build and signing | `hemtt release` | Packaging problems. Produces `@auqol`. |
| In-game test scripts compile | `tools/check_ingame_scripts.sh` | Syntax errors in `tests/ingame/*.sqf` |
| CfgFunctions consistency | `tests/static_checks.py` | Missing function files, unregistered `fn_` files, calls to undefined or unused `AUQOL_fnc_` functions |
| Dependencies and paths | `tests/static_checks.py` | `requiredAddons` must be exactly `cba_main`. XEH script paths and the PBO prefix must match. |
| File map | `tests/static_checks.py` | Every code folder and doc must be listed in `FILEMAP.md` |
| Settings | `tests/static_checks.py` | Duplicate settings, settings missing from README or `configuration.md`, `auqol_` globals read but never declared |
| Command existence | `tests/static_checks.py --wiki` | Every bare identifier in the addon and test scripts must be a real Arma 3 command or a known symbol. This catches invented commands. |
| Event handler names and parameters | `tests/static_checks.py --wiki` | `Dammaged`, `Fuel`, `GetIn` and `Service` must exist, and the parameter positions the code reads must match the wiki |
| Locality (heuristic) | `tests/static_checks.py --wiki` | A file using a local-argument command (per the wiki) must contain a `local`, `isServer` or `hasInterface` guard |
| CBA API | `tests/static_checks.py --cba` | Every `CBA_fnc_` function used must exist. So must `CBA_settingsInitialized`, the XEH config classes, the `InitPost` class event, and the `unit` and `loadout` player events. |
| ACE API | `tests/static_checks.py --ace` | Every `ace_*_fnc_` function used must exist. Every `ace_*` variable or setting name must exist as a `GVAR` in that ACE component, `REFUEL_INFINITE_FUEL` must be -10, the jerry can class must exist, and the RHS/CUP CfgPatches names must be ones ACE uses. |
| Antistasi API | `tests/static_checks.py --antistasi` | Every `HR_GRG_fnc_` function used must exist, along with `HR_GRG_Vehicles`, `HR_GRG_Sources`, `A3A_hasAce`, `teamPlayer`, `surrendered`, the source category index and the stored fuel layout |

The checks were themselves tested by mutation. Adding an invented command, an invented event handler, a missing CBA function, a misspelled ACE variable, an undefined `AUQOL_fnc_` call and an undeclared global each made the matching check fail.

### Results of the last run

Run on 2026-10-18 against CBA_A3 `cd4361a`, ACE3 `a17210f`, Antistasi Ultimate `ac4eb28`, arma3-wiki `dist` (game 2.22), HEMTT 1.22.0:

```
PASS  CfgFunctions: every function has a file, every file is registered, every call is defined
PASS  config.cpp: XEH paths exist, PBO prefix matches, CBA is the only hard dependency
PASS  CBA settings: unique, documented in README and docs, no undeclared auqol_ globals
PASS  SQF: every command used exists in the Arma 3 wiki command list
PASS  Event handlers: names exist and the parameter positions used match the wiki
PASS  Locality (heuristic): local-argument commands are guarded
PASS  CBA_A3: every CBA function, event and config class used exists
PASS  ACE3: every ACE function, variable, constant and class used exists
PASS  Antistasi Ultimate: garage, loot and Withstand functions, variables and data layout used exist
hemtt check --pedantic --error-on-all: 1 addon config rapified, 32 SQF files compiled, no warnings
tools/check_ingame_scripts.sh: 3 SQF files compiled, no warnings
hemtt release: 1 PBO built (auqol_main), signed with HEMTT's generated key, releases/auqol-1.4.0.zip
```

### Not covered by static checks

- **Runtime behaviour.** No SQF was executed. Logic errors that compile cleanly can only show up in game.
- **The Windows build script** (`tools/build.ps1`) was written but not run: no PowerShell was available. The GitHub Actions workflow has not run yet either, because no repository existed when this was written.
- **RHS and CUP** were not loaded. Their coverage rests on their service trucks using vanilla and ACE config fields, as ACE3's compat configs show. See [service-audit.md](service-audit.md#rhs-and-cup).
- **Two engine behaviours inferred from documentation:** whether the `Service` event fires on the machine owning the service vehicle or the serviced vehicle (AUQOL handles both), and whether the total soldier load cap stops you adding items beyond `maxSoldierLoad`. The `load` command's wiki page says load is "usually in range 0..1" except via commands that ignore load values.

## In-game test plan

Run this in single player first, then on a dedicated server with a second client, and once with ACE3 loaded. The scripts in `tests/ingame/` go in the debug console. Each prints `[AUQOL test]` lines to system chat and the RPT. Set `auqol_debug` on to see AUQOL's own per-action lines.

### 1. Startup and diagnostics

1. Start Antistasi Ultimate with CBA and AUQOL, without ACE.
2. Check the RPT for the `[AUQOL] Version 1.4.0 ...` block. Run `call AUQOL_fnc_diagnostics` and check every feature shows the vanilla handler.
3. Open Addon Options and check the 17 settings listed in the README.

### 2. Enemy crew ejection

1. Run `tests/ingame/eject_test.sqf`. Expected: the damaged MRAP reports `canMove=false` and `crew now=0`. The parked MRAP keeps its crew.
2. In a real Antistasi fight, immobilize an enemy APC or tank by tracks or engine, without destroying it. The crew should climb out within a few seconds and not get back in.
3. Negative checks: friendly AI, or a vehicle with you in it, is not ejected. Prisoners in a convoy truck (captive) stay inside. An enemy that surrendered stays. A vehicle that is merely stopped or parked keeps its crew.
4. Dedicated server with a headless client, if you use one: ejection still happens for HC-owned groups.

### 3. Service stock

1. Run `tests/ingame/service_test.sqf`. Expected after 30 s: truck service stock `1`, truck engine fuel still `0.5`, and the car's fuel above 0.
2. Rearm a vehicle from an ammo truck several times, then check `getAmmoCargo` on the truck. It should be 1. Repeat for repair with `getRepairCargo`.
3. Check that an ordinary vehicle still burns fuel: drive a car for a while, `fuel` drops.
4. Antistasi garage: garage a fuel truck, pull several vehicles out with near-empty tanks, and check they come out refuelled and that the garage's fuel source indicator stays green.
5. Turn `auqol_service_fuel` off mid-mission. The truck should start depleting again from where it is.
6. **With ACE3:** check that a fuel truck's capacity reads `-10` (`cursorObject getVariable "ace_refuel_capacity"`) and that ACE's "Check fuel" menu doesn't show a draining amount. Set ACE rearm to "Limited ammo supply based on caliber": the truck's supply should read 1,000,000 and refill every 30 s. Turning `auqol_service_fuel` off should restore the normal capacity.

### 4. Player features

1. Run `tests/ingame/player_test.sqf`. Expected: aim coef `0`, stamina enabled `false`, loadCoef `0`, recoil coef `1` (no recoil is off by default) and a total carry limit of 10000000.
2. Aim down sights while standing after a sprint: there should be no sway. Sprint for several minutes: there should be no exhaustion. Fill a backpack with heavy items and sprint: no slowdown or forced walking.
3. Respawn, with Antistasi re-applying your role, and run `player_test.sqf` again. The same values should come back within 5 s.
4. Toggle each player setting off. Sway, stamina and loadCoef should return to normal: aim coef 1, stamina on, and loadCoef back to the role's value.
5. Turn `auqol_player_noRecoil` on and fire a full magazine: the muzzle should not climb. Turn it off and recoil should come back.
6. **With ACE3:** the stamina bar should stay full while sprinting with a full load, and there should be no sway, with ACE sway on and off.

### 5. Total weight limit

1. Put something very heavy in your inventory (a launcher and rockets, or several machine guns) until you are past 1000 mass (`loadAbs player`). You should still be able to add more items as long as the container has room.
2. Your backpack should not hold more than its normal size.
3. `call AUQOL_fnc_diagnostics` should show a total carry limit of 10000000.

### 6. Loot from vehicles

1. Kill a few enemies, walk up to any vehicle on foot and hold "Gather Scattered Loot". Their gear and dropped weapons should end up in the vehicle's inventory and the bodies should be stripped.
2. Set `auqol_loot_radius` to 2000 and check that bodies far away are gathered too. Set it to 10 and check that they aren't.
3. Buy a loot crate. It should show one "Gather Scattered Loot" action, not two, and use the same radius as the vehicles.
4. Use it twice within 10 seconds: the second try should say it was used recently. With an enemy in combat within 500 m it should say enemies are nearby. With one at 1000 m it should still gather, including bodies out to 2000 m.
5. Capture or clear an outpost, park a vehicle within 30 m of its supply crate and gather. The crate should end up empty and its contents in the vehicle. Park more than 30 m away and the crate should keep its contents. The HQ box should never be emptied.
6. Turn `auqol_loot_enabled` off: vehicles lose the action, and the crate still works with Antistasi's own radius.

### 7. Withstand

1. In a mission with the Withstand self-revive parameter on, get downed and press H with a first aid kit.
2. Get downed again right away. The countdown hint should say Withstand is ready, and H should work again after about 1 second.
3. Turn `auqol_withstand_enabled` off. The next cooldown should be 5 minutes.

Please report results, including anything that didn't behave as written here, as GitHub issues with your mod list and whether it was SP, hosted or dedicated.
