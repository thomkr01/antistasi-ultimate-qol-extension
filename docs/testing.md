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
| Enemy crew ejection | Works (reported 2026-10-19) |
| Short Withstand cooldown | Works (reported 2026-10-19) |
| Item caches within 30 m | Works (1.4.0). 1.4.1 now deletes the empty box, not yet reported. |
| Squad perks (1.5.0) | "Seems fine" (2026-10-19) |
| Copy from user (1.5.0) | Works (reported 2026-10-18) |
| AI stuck recovery (1.5.0) | "Seems fine" (2026-10-19) |
| Squad reactions, T key, squad launchers (1.6.0) | Not tested yet |
| Live vehicle markers (1.6.0) | Not tested yet |
| Faster reactions for all friendly AI (1.7.0) | Not tested yet |
| Self-treat, recoil slider, T key focus, instant contact sharing (1.9.0) | Not tested yet. Thomas reported the 1.6.0 T key "doesn't really work"; 1.9.0 is the fix. |
| Safer stuck recovery and leaner scans (1.8.0) | Not tested yet |
| Edge-case fixes (1.8.1) | Not tested yet, see test 13 |
| Vehicle freeze and less background work (1.10.0) | Not tested yet, see test 14 |

Details such as single player, hosted or dedicated, and whether ACE was loaded, were not reported.

## Static checks

Run all of them with `tools/build.sh --sources <dir>`. CI (`.github/workflows/ci.yml`) runs the same steps on every push.

| Check | Tool | What it catches |
| --- | --- | --- |
| Config preprocess and rapify | `hemtt check --pedantic --error-on-all` | Config syntax errors, bad macros, unknown includes |
| SQF compile and lints | `hemtt check --pedantic --error-on-all` | SQF syntax errors and HEMTT's SQF lints, with warnings treated as errors |
| PBO build and signing | `hemtt release` | Packaging problems. Produces `@auqol`. |
| In-game test scripts compile | `tools/check_ingame_scripts.sh` | Syntax errors in `tests/ingame/*.sqf` |
| Regression guards | `tests/static_checks.py` | The 1.8.1 safeguards are still in the code: the loot sender and caller check comes before any cache is emptied or gather runs, nested container weapons are filtered, reaction skills are saved once and publicly, sway and recoil restore saved values, ejection rechecks the setting and hands pending checks to a new owner, stuck movement needs a recent closest point, marker pairing matches the icon and re-pairs markers Antistasi moved. Each guard was confirmed to fail on the 1.8.0 code. They prove the code is there, not that it works in game. |
| CfgFunctions consistency | `tests/static_checks.py` | Missing function files, unregistered `fn_` files, calls to undefined or unused `AUQOL_fnc_` functions |
| Dependencies and paths | `tests/static_checks.py` | `requiredAddons` must be exactly `cba_main`. XEH script paths and the PBO prefix must match. |
| File map | `tests/static_checks.py` | Every code folder and doc must be listed in `FILEMAP.md` |
| Settings | `tests/static_checks.py` | Duplicate settings, settings missing from README or `configuration.md`, `auqol_` globals read but never declared |
| Command existence | `tests/static_checks.py --wiki` | Every bare identifier in the addon and test scripts must be a real Arma 3 command or a known symbol. This catches invented commands. |
| Event handler names and parameters | `tests/static_checks.py --wiki` | `Dammaged`, `Fuel`, `GetIn` and `Service` must exist, and the parameter positions the code reads must match the wiki |
| Locality (heuristic) | `tests/static_checks.py --wiki` | A file using a local-argument command (per the wiki) must contain a `local`, `isServer` or `hasInterface` guard |
| CBA API | `tests/static_checks.py --cba` | Every `CBA_fnc_` function used must exist. So must `CBA_settingsInitialized`, the XEH config classes, the `InitPost` class event, and the `unit` and `loadout` player events. |
| ACE API | `tests/static_checks.py --ace` | Every `ace_*_fnc_` function used must exist. Every `ace_*` variable or setting name must exist as a `GVAR` in that ACE component, `REFUEL_INFINITE_FUEL` must be -10, the jerry can class must exist, and the RHS/CUP CfgPatches names must be ones ACE uses. |
| Antistasi API | `tests/static_checks.py --antistasi` | Every `HR_GRG_fnc_` function used must exist, along with `HR_GRG_Vehicles`, `HR_GRG_Sources`, `A3A_hasAce`, `teamPlayer`, `surrendered`, the source category index and the stored fuel layout. For Copy from user: the loadout editor's `applyInitialLoadout`, `OverrideTab` and `commanderLoadout` code, the blanked Random button, the arsenal's -1 unlimited marker, JNA's `arsenalOpened` handler and loading screen. For stuck recovery: the `incapacitated`, `helping` and `rearming` unit variables. For live vehicle markers: the marker name format, icon types and the order of its vehicle-kind rules, text and 60 s loop of `A3A_fnc_vehicleMarkers`. For the loot request: `CfgRemoteExec` allows all functions (mode 2) and the cooldown message key exists. |

The checks were themselves tested by mutation. Adding an invented command, an invented event handler, a missing CBA function, a misspelled ACE variable, an undefined `AUQOL_fnc_` call and an undeclared global each made the matching check fail.

### Results of the last run

Run on 2026-10-19 for 1.8.1 against CBA_A3 `cd4361a`, ACE3 `a17210f`, Antistasi Ultimate `ac4eb28`, arma3-wiki `dist` `b414af7`, HEMTT 1.22.0:

```
PASS  CfgFunctions: every function has a file, every file is registered, every call is defined
PASS  config.cpp: XEH paths exist, PBO prefix matches, CBA is the only hard dependency
PASS  FILEMAP.md lists every code folder and doc
PASS  CBA settings: unique, documented in README and docs, no undeclared auqol_ globals
PASS  Regression guards: loot request, nested loadout items, skill baselines, sway/recoil restore, ejection, stuck progress, marker pairing
PASS  SQF: every command used exists in the Arma 3 wiki command list
PASS  Event handlers: names exist and the parameter positions used match the wiki
PASS  Locality (heuristic): local-argument commands are guarded
PASS  CBA_A3: every CBA function, event and config class used exists
PASS  ACE3: every ACE function, variable, constant and class used exists
PASS  Antistasi Ultimate: garage, loot, Withstand, loadout editor, vehicle marker and unit state names used exist
hemtt check --pedantic --error-on-all: 1 addon config rapified, 45 SQF files compiled, no warnings
tools/check_ingame_scripts.sh: 5 SQF files compiled, no warnings
hemtt release: 1 PBO built (auqol_main), signed with HEMTT's generated key, releases/auqol-1.8.1.zip
```

The `expectedDestination` planning modes the stuck check relies on ("DoNotPlan", "LEADER DIRECT", "FORMATION PLANNED", "DoNotPlanFormation") are not in the parsed wiki data, so they were checked by hand against the BI wiki page for `expectedDestination`. The Random button IDC 44150 used for "Copy from user" (`IDC_RSCDISPLAYARSENAL_CONTROLSBAR_BUTTONRANDOM` in the game's `defineResinclDesign.inc`, which no source here contains) was taken from a Bohemia forums thread that disables that button by this IDC. The static check only confirms Antistasi blanks the Random button; the IDC itself is confirmed in game by test 9.

### Not covered by static checks

- **The Reveal target action name** `revealTarget` used with `addUserActionEventHandler` is from the BI wiki's input action list, which is not in the parsed wiki data or any source here. Test 11 confirms it in game.
- **Runtime behaviour.** No SQF was executed. Logic errors that compile cleanly can only show up in game.
- **The Windows build script** (`tools/build.ps1`) was written but not run: no PowerShell was available. The GitHub Actions workflow has not run yet either, because no repository existed when this was written.
- **RHS and CUP** were not loaded. Their coverage rests on their service trucks using vanilla and ACE config fields, as ACE3's compat configs show. See [service-audit.md](service-audit.md#rhs-and-cup).
- **Two engine behaviours inferred from documentation:** whether the `Service` event fires on the machine owning the service vehicle or the serviced vehicle (AUQOL handles both), and whether the total soldier load cap stops you adding items beyond `maxSoldierLoad`. The `load` command's wiki page says load is "usually in range 0..1" except via commands that ignore load values.

## In-game test plan

Run this in single player first, then on a dedicated server with a second client, and once with ACE3 loaded. The scripts in `tests/ingame/` go in the debug console. Each prints `[AUQOL test]` lines to system chat and the RPT. Set `auqol_debug` on to see AUQOL's own per-action lines.

### 1. Startup and diagnostics

1. Start Antistasi Ultimate with CBA and AUQOL, without ACE.
2. Check the RPT for the `[AUQOL] Version 1.5.0 ...` block. Run `call AUQOL_fnc_diagnostics` and check every feature shows the vanilla handler.
3. Open Addon Options and check the 33 settings listed in the README.

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

1. Run `tests/ingame/player_test.sqf`. Expected: aim coef `0`, stamina enabled `false`, loadCoef `0`, recoil coef `1` (the Recoil slider is at 100% by default) and a total carry limit of 10000000.
2. Aim down sights while standing after a sprint: there should be no sway. Sprint for several minutes: there should be no exhaustion. Fill a backpack with heavy items and sprint: no slowdown or forced walking.
3. Respawn, with Antistasi re-applying your role, and run `player_test.sqf` again. The same values should come back within about 3 s.
4. Toggle each player setting off. Sway, stamina and loadCoef should return to normal: aim coef 1, stamina on, and loadCoef back to the role's value.
5. Set `auqol_player_recoil` to 0% and fire a full magazine: the muzzle should not climb. At 50% it climbs about half as much, and at 100% recoil is back to normal.
6. **With ACE3:** the stamina bar should stay full while sprinting with a full load, and there should be no sway, with ACE sway on and off.

### 5. Total weight limit

1. Put something very heavy in your inventory (a launcher and rockets, or several machine guns) until you are past 1000 mass (`loadAbs player`). You should still be able to add more items as long as the container has room.
2. Your backpack should not hold more than its normal size.
3. `call AUQOL_fnc_diagnostics` should show a total carry limit of 10000000.

### 6. Loot from vehicles

1. Kill a few enemies, walk up to any vehicle on foot and hold "Gather Scattered Loot". Their gear and dropped weapons should end up in the vehicle's inventory and the bodies should be stripped.
2. Set `auqol_loot_radius` to 2000 and check that bodies far away are gathered too. Set it to 10 and check that they aren't.
3. Buy a loot crate. It should show one "Gather Scattered Loot" action, not two, and use the same radius as the vehicles.
4. Use it twice within 10 seconds: the second try should say it was used recently. With an enemy in combat within 100 m it should say enemies are nearby. With one at 300 m it should still gather, including bodies out to 2000 m.
5. Capture or clear an outpost, park a vehicle within 30 m of its supply crate and gather. The crate should disappear and its contents end up in the vehicle. Park more than 30 m away and the crate should keep its contents. The HQ box should never be emptied.
6. Turn `auqol_loot_enabled` off: vehicles lose the action, and the crate still works with Antistasi's own radius.

### 7. Withstand

1. In a mission with the Withstand self-revive parameter on, get downed and press H with a first aid kit.
2. Get downed again right away. The countdown hint should say Withstand is ready, and H should work again after about 1 second.
3. Turn `auqol_withstand_enabled` off. The next cooldown should be 5 minutes.

### 8. Squad perks

1. Recruit two AI into your squad. Right after they join, run in the debug console: `units group player apply { [name _x, getCustomAimCoef _x, isStaminaEnabled _x, _x getUnitTrait "loadCoef"] }`. Expected for the AI: `0`, `false`, `0`.
2. Turn `auqol_player_squad` off. The AI should go back to `1`, `true` and their previous loadCoef. Your own values stay as they were.
3. Set `auqol_player_recoil` to 0% with the squad setting on: `unitRecoilCoefficient` of the AI should read `0`.
4. **With ACE3:** the AI still read `0`, `false`, `0` (they use the vanilla commands).

### 9. Copy from user

1. Wear a full loadout of unlocked items. Open the commander menu, Set Rebel Loadouts, and press the arsenal button of a role (for example Rifleman).
2. The third bottom-bar button (between HIDE and the empty slots) should read COPY FROM USER. Press it: the model should wear your loadout, and the slot icons on the left of every filled slot should be green.
3. Press Save, close, and recruit that role. It should wear your loadout exactly.
4. Repeat while wearing one locked item (for example a looted uniform with a limited count). The chat line should name it, that slot's icon should stay black, and recruits should get a random item for it.
5. Close the editor without saving after a copy. The role should keep its old loadout and you should get your own loadout back.

### 10. AI stuck recovery

Turn on `auqol_stuck_notifyDetect` and `auqol_debug` for these tests so every step shows in chat and the RPT.

1. **Against a wall:** run `tests/ingame/stuck_test.sqf`. After about 30 s: "seems stuck (blocked by ...)", step 1, then step 3 after another 30 s (step 2 is skipped because the unit has its own move order), then "is moving again after a short hop". Clean up with the line in the script header.
2. **Rock or terrain:** order a squad AI into a gap between rocks or onto a steep slope it can't climb. Expect the same sequence with "blocked by terrain" or "cannot find a way to its destination".
3. **Can't follow the squad:** walk somewhere a squad AI can't path to (over a fence line with no gap) and wait. Expect "cannot keep up with its squad", step 1, step 2 (rejoin formation), then step 3 toward you.
4. **Not stuck:** order a squad AI to Stop or Hold, put AI in a garrison, and stand still with your squad around you. None of them should ever be reported.
5. **Busy:** during a firefight, while a medic heals someone, while AI reload, board or leave a vehicle, swim or parachute: no reports. With the teleport on, a unit that enters combat (enemy spotted, COMBAT behaviour) between its stuck report and the hop or teleport must not be moved; the step reports "not carried out".
6. **Down or captive:** incapacitated, surrendered or dead units are never reported; a deleted unit leaves no error in the RPT.
7. **Group change:** move a stuck AI to another group (or dismiss it): its tracking restarts; it is not handled twice.
8. **Repeated failure:** turn `auqol_stuck_reposition` off and run `stuck_test.sqf` again. Expect three failed rounds, 60 s apart, then "leaving it alone until it moves". Delete the walls: once it moves it is watched normally again.
9. **Teleport:** with the hop still off, turn on `auqol_stuck_teleport` and run the test again. After step 1, the unit should appear next to you with the same health and gear. With the teleport off it never teleports, and if you walk more than 100 m away it doesn't either.
10. **Vehicles and RHS:** wedge an AI-driven RHS truck (no player inside) against a building with a move order. Expect step 1, then a hop of up to 25 m. A vehicle is never teleported.
11. **Scopes:** set the scope to "Friendly AI near players" and "All friendly AI" on a dedicated server with a headless client; check the RPT of each machine: each unit appears only in its owner's RPT.
12. **Long session:** play an hour with the default scope and run `diag_activeScripts` now and then: the numbers should not grow because of AUQOL.

### 11. Squad reactions, T key and launchers

1. Recruit two AI. Within 5 s run `units group player apply { [name _x, _x skill "spotTime", _x skill "aimingSpeed", _x skill "aimingAccuracy"] }`. Expected for the AI: spot time and aiming speed at least 0.8, accuracy unchanged. Turn `auqol_squad_reaction` off: they go back to their old values.
2. Look at an enemy soldier far away that your squad hasn't seen and press T. Your AI should turn and engage him (with `auqol_debug` on, the RPT shows a "Reveal:" line). While they fight him, press T on a second enemy: they should switch to the second one and keep on it, and deal with the first afterwards. Set the squad to Hold fire and repeat: they should aim but not shoot. If nothing happens at all and no "Reveal:" line appears, the Reveal target action name may be wrong; please report it.
3. Give an AI an AT launcher (RHS RPG-7 or M136) and let an enemy APC drive into view within 500 m. The AI should take out the launcher as soon as the squad spots it, at most about 5 s if it was spotted behind cover first. Repeat with an AA launcher and a helicopter within 2000 m. A vehicle behind a hill or a building should not trigger it.
4. Go to a garrisoned outpost with a static gunner. On the server (or host) debug console run `(allUnits select { side group _x == teamPlayer && !(isPlayer leader group _x) }) apply { _x skill "spotTime" }` within 5 s of them spawning: every value at least 0.8. Turn `auqol_squad_reactionAll` off: within 5 s they go back, your own squad keeps 0.8.
5. **Contact sharing:** with `auqol_squad_reaction` on, when one AI calls out a new contact, `units group player apply { _x knowsAbout <enemy> }` should be above 0 for every unit right away, not one by one as the callouts play.

### 11b. Wounded AI treat themselves

1. Shoot a squad AI in the legs (`(units group player select 1) setHitPointDamage ["HitLegs", 0.6]`, then hit it once so the event fires). Within about 3 s it should play the treat-yourself animation and use one first aid kit, then run normally. With `auqol_debug` on, the RPT shows "Self-treat:" lines.
2. Remove its first aid kits and repeat: it should not treat itself.
3. Give an AI a medikit, get it downed and revive it with a non-medic. Within 15 s its red hurt icon should go away without using a kit (`damage` reads 0). Repeat with an AI without a medikit: the icon stays. Turn `auqol_squad_selfTreatMedikit` off: it goes away on that AI too.
4. **With ACE medical:** nothing from AUQOL should happen; ACE's own medical AI decides.

### 12. Live vehicle markers

1. Start a convoy mission (or wait for a revealed enemy vehicle) and open the map. The vehicle's marker should follow it every second while it drives, instead of jumping once a minute. A parked vehicle's marker should stay still.
2. Turn `auqol_map_liveVehicles` off: the marker goes back to jumping once a minute.
3. When the vehicle is destroyed, the marker disappears as before (within Antistasi's minute).

### 13. Edge cases fixed in 1.8.1

Static checks only show the fixes are in the code. These need a person in game, ideally on a dedicated server with a second client and a headless client.

1. **Loot request:** hold "Gather Scattered Loot" on a vehicle: it works as before. Hold it twice within 10 s (or with two players at once): the second gets Antistasi's cooldown line and caches are emptied once. With `auqol_debug` on, a request sent while dead, in a vehicle or more than 10 m away logs "Refused loot request". Test on a hosted game too: the host's own request must work.
2. **Copy from user, nested items:** run `tests/ingame/loadout_test.sqf` (works anywhere, no Antistasi needed): every line must say PASS. Then in the loadout editor carry an unlocked rifle with a locked optic and locked magazine in your backpack and press Copy from user: the rifle stays in the backpack without the optic and magazine, and the chat line names both.
3. **Reaction skills and the headless client:** on a dedicated server with a headless client, note a garrison unit's `spotTime` before AUQOL raises it (turn `auqol_squad_reaction` off, read it, turn it on). Let Antistasi hand the group to the HC (or back), then turn the setting off: the value must return to the noted one, not 0.8.
4. **Sway and recoil restore:** run `player setCustomAimCoef 0.5`, turn `auqol_player_noSway` on and then off: `getCustomAimCoef player` reads 0.5 again. Same with `player setUnitRecoilCoefficient 0.7` and `auqol_player_recoil` at 0% and back to 100%. Respawn and change loadout with both on: values stay 0, and turning off afterwards gives the right value back.
5. **Pending ejection:** shoot the wheels of a moving enemy truck and turn `auqol_eject_enabled` off within a second: nobody is ejected. With a headless client, damage an HC-owned vehicle while it is changing owner: the crew is still ejected once.
6. **Stuck, circling:** put a squad AI on a move order to a point behind a long wall with no gap that it walks along back and forth. After about 90 s plus one timeout it is reported stuck and recovery starts. A unit taking a long but working detour (around a large compound, under 90 s) is not reported. Formation followers walking with you are never reported.
7. **Vehicle markers in a convoy:** watch a convoy of several vehicles on the map. Every marker follows its own vehicle. If one ever follows the wrong vehicle, it should correct itself within about a minute, staying on Antistasi's position rather than jumping back.

### 14. Performance (1.10.0)

1. **Vehicle freeze:** park an empty car, walk more than 500 m away, then run `dynamicSimulationEnabled _car` on the server: true. Come back: it behaves normally, can be driven, towed, loaded with ACE cargo and Antistasi logistics, and put in the garage. Save and reload with frozen vehicles at HQ: they are still there. Shoot down a helicopter far away: it falls and only freezes once it lies still.
2. **Wrecks:** destroy a vehicle and leave: it is marked once it stops moving. Antistasi's garbage clean still deletes it.
3. **Reactions:** recruit an AI and run `(units group player select 1) skill "spotTime"`: 0.8 within 5 s. A newly spawned garrison unit (server) gets it within 5 s too.
4. **Markers:** with the map closed for a while, open it: tracked markers jump to their vehicles at once, then follow every second.
5. **Timings:** turn `auqol_debug` on and play 5 minutes: the RPT shows `Timing:` lines for each AUQOL timer.

Please report results, including anything that didn't behave as written here, as GitHub issues with your mod list and whether it was SP, hosted or dedicated.
