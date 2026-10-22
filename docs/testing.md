# Testing

The Arma 3 engine can't run in CI or in the environment this mod was written in. Validation is split into static checks, which run automatically, and in-game tests, which a person has to run. Nothing in this repository claims an in-game result that nobody observed.

This file is the whole test list. Every feature in [FEATURES.md](../FEATURES.md) has a numbered test below, with what the feature does, the steps to run and what you should see. Nothing you need is kept in other files. Test scripts for the debug console are in `tests/ingame/`.

**Marks.** ✅ means confirmed working in game. ❌ means not tested yet, or not confirmed. Change a ❌ to ✅ on the heading (and in the results table) once you have seen the test pass.

**Setup.** Run each test in single player first, then on a dedicated server with a second client (and a headless client where a test mentions one), and once with ACE3 loaded. Turn on `auqol_debug` (Esc, Configure, Configure Addons, AUQOL) to get per-action lines in the RPT; quick switch from the debug console: `auqol_debug = true;`. Look in the RPT for `[AUQOL]` lines and for any script error naming `auqol` or `AUQOL_fnc_`.

## In-game results

Reported by Thomas on 2026-10-18 (version 1.4.0, Antistasi Ultimate). ✅ = confirmed working in game, ❌ = not tested or not confirmed yet (same marks on each test heading below):

| Feature | Result |
| --- | --- |
| No weapon sway | Works |
| No recoil | ✅ Works |
| Unlimited stamina and weightless running | ✅ Works |
| No total weight limit | ✅ Works |
| Infinite service stock | ✅ Works |
| Loot from vehicles and the loot crate | ✅ Works |
| Enemy crew ejection | ✅ Works (reported 2026-10-19) |
| Short Withstand cooldown | ✅ Works (reported 2026-10-19) |
| Item caches within 30 m | ✅ Works (1.4.0). 1.4.1 now deletes the empty box, not yet reported. |
| Squad perks (1.5.0) | ❌ "Seems fine" (2026-10-19) |
| Copy from user (1.5.0) | ✅ Works (reported 2026-10-18) |
| AI stuck recovery (1.5.0) | ❌ "Seems fine" (2026-10-19) |
| Squad reactions, T key, squad launchers (1.6.0) | ❌ Not tested yet |
| Live vehicle markers (1.6.0) | ❌ Not tested yet |
| Faster reactions for all friendly AI (1.7.0) | ❌ Not tested yet |
| Self-treat, recoil slider, T key focus, instant contact sharing (1.9.0) | ❌ Not tested yet. Thomas reported the 1.6.0 T key "doesn't really work"; 1.9.0 is the fix. |
| Safer stuck recovery and leaner scans (1.8.0) | ❌ Not tested yet |
| Edge-case fixes (1.8.1) | ❌ Not tested yet, see test 13 |
| Vehicle freeze and less background work (1.10.0) | ❌ Not tested yet, see test 14 |

Details such as single player, hosted or dedicated, and whether ACE was loaded, were not reported.

## Static checks

Run all of them with `tools/build.sh --sources <dir>`. CI (`.github/workflows/ci.yml`) runs the same steps on every push.

| Check | Tool | What it catches |
| --- | --- | --- |
| Config preprocess and rapify | `hemtt check --pedantic --error-on-all` | Config syntax errors, bad macros, unknown includes |
| SQF compile and lints | `hemtt check --pedantic --error-on-all` | SQF syntax errors and HEMTT's SQF lints, with warnings treated as errors |
| PBO build and signing | `hemtt release` | Packaging problems. Produces `@auqol`. |
| In-game test scripts compile | `tools/check_ingame_scripts.sh` | Syntax errors in `tests/ingame/*.sqf` |
| Regression guards | `tests/static_checks.py` | The 1.8.1 safeguards are still in the code: the loot sender and caller check comes before any cache is emptied or gather runs, nested container weapons are filtered, reaction skills are saved once and publicly, sway and recoil restore saved values, ejection rechecks the setting and hands pending checks to a new owner, stuck movement needs a recent closest point, marker pairing matches the icon and re-pairs markers Antistasi moved, and night spotting saves the original skills publicly and keeps values others set later (1.18.0). Each guard was confirmed to fail on the 1.8.0 code. They prove the code is there, not that it works in game. |
| CfgFunctions consistency | `tests/static_checks.py` | Missing function files, unregistered `fn_` files, calls to undefined or unused `AUQOL_fnc_` functions |
| Dependencies and paths | `tests/static_checks.py` | `requiredAddons` must be exactly `cba_main`. XEH script paths and the PBO prefix must match. |
| File map | `tests/static_checks.py` | Every code folder and doc must be listed in `FILEMAP.md` |
| Settings | `tests/static_checks.py` | Duplicate settings, settings missing from `configuration.md`, `auqol_` globals read but never declared |
| Command existence | `tests/static_checks.py --wiki` | Every bare identifier in the addon and test scripts must be a real Arma 3 command or a known symbol. This catches invented commands. |
| Event handler names and parameters | `tests/static_checks.py --wiki` | `Dammaged`, `Fuel`, `GetIn` and `Service` must exist, and the parameter positions the code reads must match the wiki |
| Locality (heuristic) | `tests/static_checks.py --wiki` | A file using a local-argument command (per the wiki) must contain a `local`, `isServer` or `hasInterface` guard |
| CBA API | `tests/static_checks.py --cba` | Every `CBA_fnc_` function used must exist. So must `CBA_settingsInitialized`, the XEH config classes, the `InitPost` class event, and the `unit` and `loadout` player events. |
| ACE API | `tests/static_checks.py --ace` | Every `ace_*_fnc_` function used must exist. Every `ace_*` variable or setting name must exist as a `GVAR` in that ACE component, `REFUEL_INFINITE_FUEL` must be -10, the jerry can class must exist, and the RHS/CUP CfgPatches names must be ones ACE uses. |
| Antistasi API | `tests/static_checks.py --antistasi` | Every `HR_GRG_fnc_` function used must exist, along with `HR_GRG_Vehicles`, `HR_GRG_Sources`, `A3A_hasAce`, `teamPlayer`, `surrendered`, the source category index and the stored fuel layout. For Copy from user: the loadout editor's `applyInitialLoadout`, `OverrideTab` and `commanderLoadout` code, the blanked Random button, the arsenal's -1 unlimited marker, JNA's `arsenalOpened` handler and loading screen. For stuck recovery: the `incapacitated`, `helping` and `rearming` unit variables. For live vehicle markers: the marker name format, icon types and the order of its vehicle-kind rules, text and 60 s loop of `A3A_fnc_vehicleMarkers`. For the loot request: `CfgRemoteExec` allows all functions (mode 2) and the cooldown message key exists. |

The checks were themselves tested by mutation. Adding an invented command, an invented event handler, a missing CBA function, a misspelled ACE variable, an undefined `AUQOL_fnc_` call and an undeclared global each made the matching check fail.

### Results of the last run

The CI run on each push is the record: it runs every check above against the current CBA_A3, ACE3, Antistasi Ultimate and arma3-wiki sources. A local run on 2026-10-21 (1.29.0, wiki and Antistasi sources) passed every check it could run; the CBA and ACE checks were skipped there.

### Not covered by static checks

- **The Reveal target action name** `revealTarget` used with `addUserActionEventHandler` is from the BI wiki's input action list, which is not in the parsed wiki data or any source here. Test 11 confirms it in game.
- **Runtime behaviour.** No SQF was executed. Logic errors that compile cleanly can only show up in game.
- **The Windows build script** (`tools/build.ps1`) was written but not run: no PowerShell was available. The GitHub Actions workflow has not run yet either, because no repository existed when this was written.
- **RHS and CUP** were not loaded. Their coverage rests on their service trucks using vanilla and ACE config fields, as ACE3's compat configs show. See [service-audit.md](service-audit.md#rhs-and-cup).
- **Two engine behaviours inferred from documentation:** whether the `Service` event fires on the machine owning the service vehicle or the serviced vehicle (AUQOL handles both), and whether the total soldier load cap stops you adding items beyond `maxSoldierLoad`. The `load` command's wiki page says load is "usually in range 0..1" except via commands that ignore load values.

## In-game test plan

Every test has the same parts: **Setup** (what to have ready), **Steps** (exact action, then what you must see) and **Fail if** (what counts as a failure; report it with your mod list and whether it was SP, hosted or dedicated).

### Common setups used below

- **Debug console.** Open it with Esc (Zeus or editor), or in Antistasi with the admin debug console. "Local exec" runs on your machine, "Server exec" on the server. Single player and hosted: Local exec is the same as Server exec.
- **Settings.** Esc, Configure, Addon Options (CBA), pick AUQOL. Every setting name below (for example `auqol_player_recoil`) is shown with its tooltip there. Quick switch from the console: `auqol_debug = true;`. Server-controlled settings must be changed as admin.
- **Hostile side.** In the snippets below `_side` is the side that fights you. In Antistasi it is the occupants (usually `west` or `east`). Find it: aim at a known enemy and run `side group cursorTarget`.
- **Enemy squad, 4 men, 200 m ahead of you (Local exec):** `private _side = east; private _g = createGroup [_side, true]; private _p = player getPos [200, getDir player]; for "_i" from 1 to 4 do { _g createUnit ["O_Soldier_F", _p, [], 10, "NONE"] }; _g setBehaviour "AWARE"; _g setCombatMode "RED"; ` (remove them afterwards with `{ deleteVehicle _x } forEach units _g;` when `_g` is still set).
- **Squad.** Recruit two AI with Antistasi (or in the editor, group them to you).
- **Night.** `skipTime` to night: `skipTime ((24 - daytime + 1) % 24);` then wait; overcast makes it darker.
- **RPT.** The log file `arma3_x64_*.rpt` in `%LOCALAPPDATA%\Arma 3`. Search for `[AUQOL]` and for `Error`.

### ❌ 1. Startup and diagnostics

What it does: Checks the mod loads and reports itself.

Setup: Antistasi Ultimate with CBA and AUQOL, no ACE.

1. Start the mission. Open the RPT and find the line block starting `[AUQOL] Version`. Expected: the version equals the one in `addons/main/script_version.hpp`, and no line with `Error` that mentions `auqol`.
2. Run Local exec `call AUQOL_fnc_diagnostics`. Expected: a list of features; each service handler line says `vanilla`.
3. Esc, Configure, Addon Options, AUQOL. Expected: 96 settings (listed in `docs/configuration.md`), grouped under categories, all with tooltips.

Fail if: no `[AUQOL] Version` block, any `auqol` error in the RPT, or fewer settings than listed.

### ✅ 2. Enemy crew ejection

What it does: Enemy crews climb out of vehicles that can no longer move, so you can capture them (1.1.0, aircraft 1.24.0).

Setup: single player, a mission with enemy vehicles (Antistasi outpost or patrol).

1. Run `tests/ingame/eject_test.sqf` in the console. Expected in system chat: the damaged MRAP reports `canMove=false` and `crew now=0`; the parked MRAP keeps its crew.
2. Find an enemy APC or tank. Shoot out its tracks or engine without destroying it. Expected: the crew climbs out within a few seconds and does not get back in.
3. Negative checks. A friendly AI vehicle you shoot (do not do this in a real mission; use Zeus or the editor), a vehicle you are in, a convoy truck with prisoners (captive), and an enemy that already surrendered: none are ejected. A vehicle that is merely stopped keeps its crew.
4. Dedicated server with a headless client: repeat step 2 on a vehicle whose group is owned by the headless client. Expected: same result.
5. Downed aircraft (1.24.0): `private _h = createVehicle ["O_Heli_Light_02_F", player getPos [150, 0], [], 0, "FLY"]; createVehicleCrew _h;` then `_h setHitPointDamage ["HitEngine", 1];` Expected: it falls; once on the ground the crew climbs out within about 10 s and its guns stay silent. A healthy landed enemy helicopter keeps its crew. A crashed friendly aircraft and a surrendered crew are untouched. Turn `auqol_eject_aircraft` off and repeat: nobody is ejected.

Fail if: crew stay inside an immobilized land vehicle for more than 15 s, or a healthy, prisoner or friendly vehicle loses its crew.

### ✅ 3. Service stock

What it does: Ammo, repair and fuel trucks never run out of stock (1.0.0).

Setup: single player, a repair truck, an ammo truck and a fuel truck (or one multi-service truck).

1. Run `tests/ingame/service_test.sqf`. Expected after 30 s in chat: truck service stock `1`, truck engine fuel still `0.5`, and the car's fuel above 0.
2. Rearm a vehicle from the ammo truck five times. Then run `getAmmoCargo _truck` (with `_truck = cursorObject;` aimed at it). Expected: `1`. Repeat for repair with `getRepairCargo` and for fuel with `getFuelCargo`.
3. Drive a normal car for two minutes with a full tank. Expected: `fuel _car` drops. (Only service vehicles are infinite.)
4. Antistasi garage: garage a fuel truck, then pull out several vehicles with near-empty tanks. Expected: each comes out refuelled and the garage's fuel indicator stays green.
5. Turn `auqol_service_fuel` off mid-mission. Expected: the fuel truck starts to deplete again from where it is.
6. With ACE3: `cursorObject getVariable "ace_refuel_capacity"` on a fuel truck reads `-10`; ACE's "Check fuel" shows no draining amount. Set ACE rearm to "Limited ammo supply based on caliber": the truck's supply reads 1,000,000 and refills every 30 s. Turn `auqol_service_fuel` off: the normal capacity returns.

Fail if: any stock number goes down for good after use, or an ordinary vehicle stops using fuel.

### ✅ 4. Player features

What it does: No weapon sway, unlimited stamina, running not slowed by weight, and a Recoil slider for you (1.0.0 to 1.9.0).

Setup: single player, a rifle with a scope.

1. Run `tests/ingame/player_test.sqf`. Expected in chat: aim coef `0`, stamina enabled `false`, loadCoef `0`, recoil coef `1` (slider at 100% by default), total carry limit `10000000`.
2. Sprint for 20 s, then aim down the sight standing. Expected: the sight stays still, no sway at all.
3. Sprint continuously for 3 minutes carrying a heavy backpack. Expected: no exhaustion, no forced walk, the same speed as unloaded.
4. Respawn (Antistasi re-applies your role), run `player_test.sqf` again. Expected: the same values within about 3 s.
5. Turn each player setting off one by one (`auqol_player_noSway`, `auqol_player_unlimitedStamina`, `auqol_player_weightless` as listed in the settings menu). Expected after each: `getCustomAimCoef player` reads 1, `isStaminaEnabled player` true, `player getUnitTrait "loadCoef"` reads the role's normal value.
6. Set `auqol_player_recoil` to 0% and fire a full magazine on full auto. Expected: the muzzle does not climb. At 50% it climbs about half as far as vanilla, at 100% it is as vanilla.
7. With ACE3: sprint with a full load. Expected: the stamina bar stays full and there is no sway, with ACE sway on and off.

Fail if: sway, exhaustion or slowdown is visible, or the values do not return after toggling or respawning.

### ✅ 5. Total weight limit

What it does: There is no limit on how much you can carry (1.2.0).

Setup: single player with an arsenal or a crate of items.

1. Put items in your inventory until `loadAbs player` is over 1000 (a launcher with rockets and several machine guns). Expected: you can keep adding items while containers have room.
2. Try to fill a backpack past its normal volume. Expected: the engine still refuses (containers keep their vanilla size).
3. Run `call AUQOL_fnc_diagnostics`. Expected: a total carry limit of `10000000`.

Fail if: the game stops you adding items at a total weight, or a container holds more than its normal size.

### ✅ 6. Loot from vehicles

What it does: Any vehicle gets a Gather Scattered Loot action that pulls gear from nearby bodies and item caches (1.2.0 to 1.4.1).

Setup: an Antistasi mission, a vehicle near you, a few dead enemies with gear within 100 m, a captured outpost with a supply crate.

1. Walk up to the vehicle on foot and hold "Gather Scattered Loot" (scroll menu). Expected: the bodies' gear and dropped weapons end up in the vehicle inventory and the bodies are stripped.
2. Set `auqol_loot_radius` to 2000 and gather with bodies 500 m away: they are gathered. Set it to 10 and repeat: they are not.
3. Buy a loot crate. Expected: one "Gather Scattered Loot" action (not two) with the same radius.
4. Use the action twice within 10 s. Expected: the second try says it was used recently. With an enemy in combat within 100 m of the vehicle: it says enemies are nearby. With one at 300 m: it gathers.
5. Park a vehicle within 30 m of an outpost supply crate (an Antistasi item cache) and gather. Expected: the crate's contents end up in the vehicle and the empty crate is deleted. Park more than 30 m away: the crate keeps its contents. The HQ box and player boxes are never emptied.
6. Turn `auqol_loot_enabled` off. Expected: vehicles lose the action; the crate keeps working with Antistasi's own radius.

Fail if: gear stays on bodies in range, the HQ box is emptied, or the action appears twice on the crate.

### ✅ 7. Withstand

What it does: A downed player can self-revive again after 1 second instead of 5 minutes (1.3.0).

Setup: Antistasi with the Withstand (self-revive) parameter on, a first aid kit in your inventory.

1. Get downed (set `player setDamage 0.9` and wait, or let an enemy shoot you). Press H to self-revive.
2. Get downed again right away. Expected: the hint says Withstand is ready and H works again after about 1 second.
3. Turn `auqol_withstand_enabled` off and repeat. Expected: the next cooldown is 5 minutes.

Fail if: the second H press is refused for more than a few seconds with the setting on.

### ❌ 8. Squad perks

What it does: Your squad AI get your perks: no sway, stamina and weight (1.5.0).

Setup: two recruited AI in your squad.

1. Right after they join, Local exec: `units group player apply { [name _x, getCustomAimCoef _x, isStaminaEnabled _x, _x getUnitTrait "loadCoef"] }`. Expected for the AI rows: `0`, `false`, `0`. (Your own row also reads those.)
2. Turn `auqol_player_squad` off. Expected: the AI go back to `1`, `true` and their earlier loadCoef; yours stays at your perks.
3. Turn it on again and set `auqol_player_recoil` to 0%. Local exec: `units group player apply { unitRecoilCoefficient _x }`. Expected: `0` for the AI.
4. With ACE3: repeat step 1. Expected: the AI still read `0`, `false`, `0`.

Fail if: an AI keeps vanilla values after joining, or keeps the perks after the setting is off.

### ✅ 9. Copy from user

What it does: The rebel loadout editor gets a button that copies your own loadout onto a role (1.5.0).

Setup: Antistasi, you wear a full loadout of unlocked arsenal items.

1. Commander menu, Set Rebel Loadouts, press the arsenal button of a role (for example Rifleman). Expected: the third bottom-bar button (between HIDE and the empty slots) reads COPY FROM USER.
2. Press it. Expected: the model wears your loadout and the icon left of every filled slot turns green.
3. Press Save, close, recruit that role. Expected: the recruit wears your loadout exactly.
4. Repeat with one locked item on you (for example a looted uniform with a limited count). Expected: the chat line names the item, that slot's icon stays black and recruits get a random item for it.
5. Press Copy, then close the editor without saving. Expected: the role keeps its old loadout and you get your own loadout back.

Fail if: the button is missing, a locked item is copied silently, or your gear is lost after closing.

### ❌ 10. AI stuck recovery

What it does: Detects friendly AI that cannot move and gets them going again in careful steps (1.5.0 to 1.8.1).

Setup: turn on `auqol_stuck_notifyDetect` and `auqol_debug` so every step shows in chat and the RPT.

1. **Against a wall.** Run `tests/ingame/stuck_test.sqf`. Expected after about 30 s: "seems stuck (blocked by ...)", step 1; after another 30 s step 3 (step 2 is skipped because the unit has its own move order); then "is moving again after a short hop".
2. **Rock or terrain.** Order a squad AI into a gap between rocks or onto a steep slope it cannot climb. Expected: the same sequence with "blocked by terrain" or "cannot find a way to its destination".
3. **Cannot follow.** Walk somewhere the AI cannot path to (over a fence line with no gap) and wait. Expected: "cannot keep up with its squad", step 1, step 2 (rejoin formation), then step 3 toward you.
4. **Not stuck.** Order a squad AI to Stop or Hold; put AI in a garrison; stand still with your squad. Expected: none is ever reported.
5. **Busy.** During a firefight, while a medic heals someone, while AI reload, board or leave a vehicle, swim or parachute: no report. With `auqol_stuck_teleport` on, a unit that enters combat between its report and the hop must not be moved; the step says "not carried out".
6. **Down or captive.** Incapacitated, surrendered or dead units are never reported; deleting a stuck unit leaves no error in the RPT.
7. **Group change.** Move a stuck AI to another group or dismiss it. Expected: tracking restarts; it is not handled twice.
8. **Repeated failure.** Turn `auqol_stuck_reposition` off and run `stuck_test.sqf` again. Expected: three failed rounds 60 s apart, then "leaving it alone until it moves". Delete the walls: once it moves it is watched normally again.
9. **Teleport.** With the hop off, turn on `auqol_stuck_teleport` and run the test. Expected: after step 1 the unit appears next to you with the same health and gear. With teleport off it never teleports; if you are more than 100 m away it does not either.
10. **Vehicles and RHS.** Wedge an AI-driven RHS truck (no player inside) against a building with a move order. Expected: step 1, then a hop of up to 25 m. A vehicle is never teleported.
11. **Scopes.** Set `auqol_stuck_scope` to "Friendly AI near players", then "All friendly AI" on a dedicated server with a headless client. Expected: each unit appears only in its owner's RPT.
12. **Long session.** Play an hour with the default scope and run `diag_activeScripts` every 15 minutes. Expected: the numbers do not keep growing because of AUQOL.

Fail if: a busy, down or garrisoned unit is reported or moved, a unit is teleported while engaging, or the sequence in step 1 does not run.

### ❌ 11. Squad reactions, T key and launchers

What it does: The squad reacts faster, shares contacts, the T key marks an enemy for them, and AT/AA soldiers switch to launchers at once (1.6.0 to 1.15.1).

Setup: two AI in your squad, one with an AT launcher (RHS RPG-7 or M136) and one with an AA launcher; the enemy squad snippet from the common setups; Zeus or the console for enemy vehicles and helicopters.

1. **Reaction skills.** Within 5 s of an AI joining, Local exec `units group player apply { [name _x, _x skill "spotTime", _x skill "aimingSpeed", _x skill "aimingAccuracy"] }`. Expected for the AI: spot time and aiming speed at least 0.8, accuracy unchanged. Turn `auqol_squad_reaction` off: the old values return.
2. **T key.** Spawn the enemy squad 200 m ahead, out of your squad's sight. Look at one enemy and press T (default Reveal target). Expected: your AI turn and engage; with `auqol_debug` on the RPT shows a "Reveal:" line. While they fight him, press T on a second enemy: they switch to the second one and deal with the first afterwards. Set the squad to Hold fire and repeat: they aim but do not shoot. Fail if nothing happens at all and no "Reveal:" line appears (the Reveal target action name may be wrong; report it).
3. **AT launcher.** Spawn an enemy APC within 500 m in view (`createVehicle ["O_APC_Wheeled_02_rcws_F", player getPos [400, getDir player], [], 0, "NONE"]` plus `createVehicleCrew`). Expected: the AT soldier has his launcher out as soon as the squad spots it, at most about 5 s after it was first seen behind cover. A vehicle behind a hill or building does not trigger it.
4. **AA launcher.** Spawn an enemy helicopter within 2000 m. Expected: the AA soldier takes out his launcher, and fires when it locks. Same for a jet making attack runs on you: launcher out within a second or two of it coming into view.
5. **Garrison reactions.** Go to a garrisoned outpost with a static gunner. On the server within 5 s of the garrison spawning: `(allUnits select { side group _x == teamPlayer && !(isPlayer leader group _x) }) apply { _x skill "spotTime" }`. Expected: every value at least 0.8. Turn `auqol_squad_reactionAll` off: within 5 s they go back; your own squad keeps 0.8.
6. **Contact sharing.** With `auqol_squad_reaction` on, when one AI calls out a new contact, run `units group player apply { _x knowsAbout _enemy }` (with `_enemy` the contact). Expected: above 0 for every unit right away.

Fail if: skills stay at the old values, launcher switching takes longer than the times above, or a squad does not react to T.

### ❌ 11b. Wounded AI treat themselves

What it does: A wounded squad AI treats itself with a first aid kit, going to cover first (1.6.0 to 1.17.0).

Setup: a squad AI with first aid kits (check in its inventory), `auqol_debug` on.

1. Local exec `private _ai = (units group player) select 1; _ai setHitPointDamage ["HitLegs", 0.6];` then shoot it once in the leg (or let an enemy hit it) so the damage event fires. Expected within about 3 s: it plays the treat-yourself animation, uses one first aid kit, then runs normally. The RPT shows "Self-treat:" lines.
2. Remove all its first aid kits and repeat. Expected: it does not treat itself.
3. Give an AI a medikit, get it downed and revive it with a non-medic. Expected within 15 s: its red hurt icon is gone without using a kit (`damage _ai` reads 0). Repeat with an AI without a medikit: the icon stays. Turn `auqol_squad_selfTreatMedikit` off: the icon is not cleared on the medikit AI either.
4. With ACE medical: nothing from AUQOL happens; ACE's own medical AI decides.

Fail if: a wounded AI with a kit never treats itself within 10 s, or uses a kit it does not have.

### ❌ 12. Live vehicle markers

What it does: Map markers of tracked vehicles follow them every second instead of once a minute (1.6.0).

Setup: a convoy mission or a revealed enemy vehicle, map open.

1. Watch the marker of a driving vehicle. Expected: it moves smoothly, about every second; a parked vehicle's marker stays still.
2. Turn `auqol_map_liveVehicles` off. Expected: the marker goes back to jumping about once a minute.
3. Destroy the vehicle. Expected: the marker disappears as before (within Antistasi's minute).

Fail if: markers do not move between Antistasi's updates with the setting on, or a destroyed vehicle's marker stays.

### ❌ 13. Edge cases fixed in 1.8.1

What it does: Fixes for rare cases found in a review of 1.8.0. Static checks only show the fixes are in the code.

Setup: ideally a dedicated server with a second client and a headless client; `auqol_debug` on.

1. **Loot request.** Hold "Gather Scattered Loot" on a vehicle: it works as before. Hold it twice within 10 s (or with two players at once). Expected: the second gets Antistasi's cooldown line and caches are emptied once. A request sent while dead, in a vehicle or more than 10 m away logs "Refused loot request". On a hosted game the host's own request works.
2. **Copy from user, nested items.** Run `tests/ingame/loadout_test.sqf` (works anywhere). Expected: every line says PASS. Then in the loadout editor carry an unlocked rifle with a locked optic and a locked magazine in your backpack and press Copy from user. Expected: the rifle stays in the backpack without the optic and magazine, and the chat line names both.
3. **Reaction skills and the headless client.** Turn `auqol_squad_reaction` off, read a garrison unit's `skill "spotTime"`, turn it on. Let Antistasi hand the group to the headless client (or back), then turn the setting off. Expected: the value returns to the first one noted, not 0.8.
4. **Sway and recoil restore.** `player setCustomAimCoef 0.5;` then turn `auqol_player_noSway` on and off. Expected: `getCustomAimCoef player` reads 0.5 again. Same with `player setUnitRecoilCoefficient 0.7;` and `auqol_player_recoil` at 0% and back to 100%. Respawn and change loadout with both on: values stay 0; turning off afterwards gives the right value back.
5. **Pending ejection.** Shoot the wheels of a moving enemy truck and turn `auqol_eject_enabled` off within a second. Expected: nobody is ejected. With a headless client, damage an HC-owned vehicle while it changes owner: the crew is ejected exactly once.
6. **Stuck, circling.** Put a squad AI on a move order to a point behind a long wall with no gap. Expected: after about 90 s plus one timeout it is reported stuck and recovery starts. A unit on a long but working detour under 90 s is not reported. Formation followers walking with you are never reported.
7. **Vehicle markers in a convoy.** Watch a convoy of several vehicles on the map. Expected: every marker follows its own vehicle; a marker on the wrong vehicle corrects itself within about a minute.

Fail if: any expected value above is not seen.

### ❌ 14. Performance (1.10.0)

What it does: Parked empty vehicles and settled wrecks sleep when no player is near, and timers are spread out to save server time (1.10.0).

Setup: single player, then a dedicated server; `auqol_debug` on for step 5.

1. **Vehicle freeze.** Park an empty car, walk more than 500 m away, then on the server run `dynamicSimulationEnabled _car` (with `_car` set to it). Expected: `true`. Come back. Expected: it can be driven, towed, loaded with ACE cargo and Antistasi logistics and put in the garage. Save and reload with frozen vehicles at HQ: they are still there.
2. **Falling helicopter.** Shoot down a helicopter far away. Expected: it falls normally and is frozen only once it lies still.
3. **Wrecks.** Destroy a vehicle and leave. Expected: the wreck is marked (frozen) once it stops moving; Antistasi's garbage clean still deletes it.
4. **Reactions.** Recruit an AI and run `(units group player select 1) skill "spotTime"`. Expected: 0.8 within 5 s. A newly spawned garrison unit (server) gets it within 5 s too.
5. **Markers.** With the map closed for a while, open it. Expected: tracked markers jump to their vehicles at once, then follow every second.
6. **Timings.** Play 5 minutes. Expected: the RPT shows `Timing:` lines for each AUQOL timer.

Fail if: a frozen vehicle cannot be used, a falling aircraft freezes mid-air, or timings are missing.

### ❌ 15. Animations and smart combat AI (1.11.0)

What it does: Faster AI animation, faster pistol swap, and the full smart combat AI: suppression reactions, fire teams, flanking, grenades, smoke, anti-armor and anti-air launchers (1.11.0 to 1.15.1).

Setup: the enemy squad snippet, Antistasi mission for step 6, a ladder (tower) for test 28.

1. **AI speed.** Local exec `getAnimSpeedCoef (allUnits select { !isPlayer _x } select 0)`. Expected: 1.25. `getAnimSpeedCoef player`: 1. Set `auqol_anim_aiSpeed` to 2: AI move visibly faster within 15 s. Turn `auqol_anim_ai` off: back to 1.
2. **Pistol swap.** Switch from rifle to pistol and back (default keys). Expected: both are about twice as fast as vanilla. Reloading is unchanged.
3. **Ladders.** See test 28.
4. **Suppression.** Shoot near (not at) a standing enemy patrol from cover. Expected: they crouch (prone only with `auqol_combat_noProne` off) and turn toward you; about 10 s after you stop firing they stand again. Your own squad's stance does not change. With LAMBS loaded, behaviour is LAMBS's own.
5. **Fire teams.** Run `tests/ingame/combat_test.sqf`. Expected in the hint: two teams taking turns, one team's soldiers getting spots and walking to them while the other stays. They stop behind walls, rocks or trees and crouch, or stand at building positions. Hide in a house within 80 m: two of them come into it. Stay hidden 12 to 35 m from one: a grenade comes in. Break contact for 30 s: "Tactics running: false" and they rejoin formation.
6. **Antistasi.** Attack an outpost. Expected: garrison soldiers in buildings stay where Antistasi put them; a QRF or patrol still goes where Antistasi sends it, with members moving between cover around the leader. Kill one of a patrol: Antistasi's own reaction (smoke, suppressing fire) still happens.
7. **Grenades and launchers (1.13.0).** Throw a grenade next to an enemy group: the ones near it run. Drive a tank at an enemy squad with an AT soldier: he takes out the launcher, the others back off to cover. Get spotted by one patrol: a second patrol within 300 m turns toward you.
8. **Features together.** With smart combat running, `auqol_stuck_notifyDetect` on and a soldier walking into a wall to reach cover: smart combat picks him another spot within about 10 s; stuck recovery reports nothing during the fight.
9. **1.14.0.** Fly a helicopter near an enemy squad with an AA soldier: he takes out the AA launcher. Wound an enemy in contact in the legs (`_e setHitPointDamage ["HitLegs", 0.6]`): within about 10 s it treats itself. Press T on an enemy: `(group _ai) knowsAbout _enemy` is above 1 for a friendly AI group within 300 m.
10. **1.15.0 launchers.** Give a squad AA soldier two rounds and fly two enemy helicopters in. Expected: after the first hit sends one down, the second round goes to the other helicopter. Same with an AT soldier and two APCs: once one can neither move nor fire, the next round goes to the other. Shoot only the tracks of a tank whose gun still works: it still gets rounds. Press T on a helicopter and shoot it down: the squad stops firing at it. With ACE Advanced Throwing, cook a grenade next to your squad: nobody runs until you throw it. Let an Antistasi medic revive an enemy AI, keep fighting that group: no script errors, the soldiers keep moving between cover.
11. **1.15.1 together.** A squad AT soldier with his launcher out and no enemy vehicle around: press T on an enemy soldier. Expected: he switches to his rifle (with a vehicle still in the fight he stays on it). Wound a squad AI so it treats itself, then press T on an enemy at once: it finishes treating first. Get spotted, then within 10 s press T on a different enemy: a friendly AI group within 300 m still learns about it. Suppress an enemy patrol fighting from behind walls: the soldiers stay crouched behind the walls when the fire stops.

Fail if: speeds are wrong, soldiers fight in the open when cover is near, Antistasi's garrison or patrols are moved, or any script error appears.

### ❌ 16. Smart combat cover and scratches (1.16.0)

What it does: Smart combat soldiers take real cover behind trees, rocks and walls, and light vehicle scratches are repaired (1.16.0).

Setup: a spot with trees, rocks or walls; an empty car.

1. **Cover at contact.** Run `tests/ingame/combat_test.sqf` there. Expected: within a few seconds of contact every soldier of the enemy team is behind something, including the covering team; the ones moving go from cover to cover. They keep returning fire.
2. **Behind the object.** Expected: a soldier behind a tree or rock stands right at its back, not a few metres away.
3. **Defending.** Attack a group holding a position. Expected: soldiers stay at the covered spots they took instead of swapping places every 20 s.
4. **Scratches.** Shoot a car once in the body. Expected: after 2 s `damage _car` is 0 and no Repair action is offered. Shoot a wheel until it is flat: Repair is offered as usual.

Fail if: soldiers stand in the open with cover within 20 m, or a flat wheel is "repaired".

### ❌ 17. Cover before self-treatment (1.17.0)

What it does: A wounded AI runs to cover before treating itself, and soldiers you shoot at answer harder (1.17.0).

Setup: trees or walls near you, an enemy squad that can see your AI, `auqol_debug` on.

1. Let a squad AI get hit in the legs while an enemy can see it. Expected: it runs to cover first, plays the treat-yourself animation there, then rejoins formation; the RPT shows "Self-treat: ... runs to cover before treating".
2. Order it to Stop first, then let it get hit. Expected: it treats where it stands.
3. **Fire back.** From cover, fire bursts near an enemy group. Expected: the soldiers you shoot at answer at once, and the covering team keeps suppressing your position for about 15 s after your last burst.

Fail if: it treats itself in the open under fire, or the enemy does not answer.

### ❌ 18. Night spotting (1.18.0)

What it does: Enemies without night vision spot you late in the dark (1.18.0).

Setup: night with no moon (or overcast), an enemy patrol without NVGs, Server exec for the console lines.

1. **Dark.** Aim at an enemy without NVGs and run `[cursorTarget skill "spotDistance", cursorTarget getVariable "auqol_nightSkills"]`. Expected: the skill value is about a quarter of the first number in the saved array. An enemy with NVGs has no saved array.
2. **Range.** Approach the patrol without NVGs and note the distance at which it reacts: crawling about 20 m, crouched about 35 m, walking about 50 m, running about 100 m, sprinting about 150 m, a vehicle with the engine on about 200 m. Switch on your weapon light, stand under a street lamp or fire a flare over yourself: about 300 m. By day it notices you much farther out. Fire a shot: it reacts as before.
3. **Vehicles.** An enemy gunner on a static or in a vehicle with a thermal or NV sight spots as by day; a truck driver without NVGs does not.
4. **Morning.** `skipTime` to day. Expected: within 5 s the saved array is gone and the skills are back.
5. **HATG.** With Hide Among The Grass loaded, lie prone in grass at night. Expected: both work at once and the RPT shows no script errors.

Fail if: ranges are more than about 30% off, NV enemies are blind, or skills stay lowered in daylight.

### ❌ 19. Hide among the grass (1.19.0)

What it does: Lying still in grass hides you and your squad, like the Hide Among The Grass mod (1.19.0).

Setup: a grassy field, enemy patrol, the HATG mod NOT loaded (step 6 loads it).

1. Lie down in the field with no enemy within 10 m. Expected: the grey hidden icon shows and `player getUnitTrait "camouflageCoef"` is about 0.01. A patrol walking past at 20 m does not react.
2. Let an enemy come within 10 m, or fire 2 to 4 unsuppressed shots, or fire a launcher. Expected: the revealed icon (white) shows for 15 s.
3. Crouch and walk slowly (under 5 km/h): stays hidden; jog: revealed. Stand in the open: revealed; stand inside a house: hidden. With an enemy close while prone, `camouflageCoef` is about half its normal value.
4. Your squad AI lying down are hidden too (`_ai getUnitTrait "camouflageCoef"`) and get revealed when they fire.
5. Bind Toggle hiding (Controls, Configure Addons), press it. Expected: the disabled icon shows and nobody in your squad hides.
6. With HATG loaded: no AUQOL icon, HATG's own indicator works and the RPT diagnostics line says AUQOL's concealment is off.

Fail if: you are visible to a patrol at 20 m while hidden, or hiding stays on after firing.

### ❌ 20. Hard to locate at range (1.20.0)

What it does: After you shoot from far away, enemies find you slowly, depending on suppressor and distance (1.20.0).

Setup: `auqol_debug` on (the RPT shows "Hard to locate" lines), night, a ghillie suit, a suppressed rifle, an enemy patrol that has not seen you.

1. Lie prone 300 m from the patrol and shoot one of them. Expected: the rest go alert but do not fire back at you or move straight at you; the RPT shows "Hard to locate: ... lost ..."; `_enemy knowsAbout player` (server) is 0 after about 2 s.
2. Same without the suppressor. Expected: after a few shots from the same spot they find you (the distance grows with each shot) and fire back.
3. Same at 50 m with the suppressor. Expected: they find you.
4. With the Hide Among The Grass mod loaded instead of AUQOL's concealment: step 1 behaves the same.
5. Antistasi may still call support on the position after a kill; that is Antistasi's own reaction and is not a fail.

Fail if: a suppressed shot from 300 m is answered at once with accurate fire.

### ❌ 21. Optimization pass (1.20.1)

What it does: Server, client and headless client optimizations; nothing should look or play differently from 1.20.0 (1.20.1 to 1.20.4).

Setup: a dedicated server with a headless client and two players; `auqol_debug` on.

1. **Night spotting.** Repeat test 18 on this setup. Expected: enemies without night vision still spot late, and with a weapon light on they notice you from the light distance.
2. **Timings.** Play 5 minutes at night near a garrison. Expected: the `night spotting` line in the RPT is lower than in 1.20.0 (was about 7 ms worst case).
3. **Self-treat and loot.** A wounded squad AI with a first aid kit still treats itself, and every vehicle still offers Gather Scattered Loot.
4. **Concealment in MP.** Repeat test 19 with two players. Expected: each player's indicator and hiding work; squad AI handed to another machine (the leader leaves) are restored there.
5. **Night pass spread.** Expected: the `night spotting` line shows about 300 runs per 5 minutes and its worst time stays well under 7 ms. Recruiting AI and pressing T leave no AUQOL errors in the RPT.

Fail if: a feature from tests 18 or 19 stops working on the dedicated setup, or the timings are worse than the numbers above.

### ✅ 22. AA launchers against jets and T key feedback (1.20.5)

What it does: Squad AA soldiers fire at jets and helicopters, and the T key picks the enemy nearest your view and shows a notification (1.20.5).

Setup: an AA soldier in your squad (RHS Igla or Stinger, CUP or vanilla Titan), an enemy jet (A-10 or Su-25) via Zeus, enemy soldiers.

1. **Jets.** Have the enemy jet attack you, in the open and next to buildings. Expected: within a second or two of it coming into view the AA soldier takes out his launcher and fires once it locks. `auqol_debug` shows a "Launcher:" line. Set the squad to Hold fire: he takes it out and aims, but does not fire.
2. **T while the jet is up.** With the AA soldier holding his launcher on the jet, press T on an enemy soldier. Expected: he stays on the jet and the rest of the squad takes the soldier.
3. **Paratroopers.** Enemy parachutists in the air draw no AA round.
4. **T near an enemy.** Aim a little beside an enemy soldier you can see and press T. Expected: he is marked (notification shows his name) and the squad engages him. An enemy hidden behind a wall is not picked.
5. **T feedback.** Press T on an enemy. Expected: a small notification "<enemy> marked for your squad" appears for you only, centred horizontally at the height CBA notifications use (about a quarter down from the top) and fades after a few seconds. Press T on two different enemies quickly: the second text replaces the first. Pressing T on nothing or on a friendly shows nothing.

Fail if: the AA soldier ignores a jet that is attacking, or the notification appears for other players or off-centre.

### ❌ 23. AI avoid prone (1.21.0)

What it does: AI in combat crouch or stand instead of going prone, like the AI Avoids Prone mod (1.21.0).

Setup: the "AI avoids prone" mod NOT loaded; open ground and tall grass; enemy squad snippet.

1. Start a firefight with the enemy squad on open ground and in grass (shoot at them from 150 m). Expected: they crouch or stand to fight and move; none lies flat (`stance _x` is never "PRONE" for them).
2. Watch your squad in the same fight. Expected: the same. Order Prone yourself in the command menu: it still goes prone.
3. Turn `auqol_combat_noProne` off and suppress them heavily. Expected: AI may go prone again.

Fail if: AI go prone with the setting on, or ignore your Prone order.

### ❌ 24. Look to spot (1.22.0)

What it does: Looking at an enemy with the crosshair reveals it to your squad and to friendly groups within 300 m (1.22.0, 1.26.0).

Setup: `auqol_debug` on, a squad, two enemies about 150 m apart in the open that your squad has not seen, a friendly garrison or AI squad within 300 m for step 4.

1. Put the crosshair between the two enemies, within the look angle (default 5 degrees), without pressing T. Expected: the RPT shows "Look to spot: 2 enemies revealed"; the squad turns and engages; they split targets on their own.
2. Look away and back at an already known enemy. Expected: no new RPT line within 20 s. Press T on one: it becomes the focus as before.
3. Open the map, or turn `auqol_squad_lookSpot` off. Expected: nothing is revealed.
4. Stand within 300 m of a friendly garrison or AI squad and look at an enemy neither group has seen. Expected: they turn to face it and fight from cover within seconds.

Fail if: nothing is revealed in step 1, or the same enemy is announced more than once in 20 s.

### ❌ 25. Primary weapon after getting up (1.25.0)

What it does: After you wake from unconsciousness your rifle comes up, not your launcher (1.25.0).

Setup: Withstand on (test 7), a rifle and a launcher in your inventory.

1. Get downed, then self-revive. Expected: you get up with the rifle in hand and can move at once, no launcher animation.
2. Repeat with the launcher selected when you go down: still the rifle. With no rifle but a pistol: the pistol comes up. With neither: nothing is switched.
3. Turn `auqol_player_wakePrimary` off. Expected: the old behaviour returns (the launcher comes up).
4. With ACE medical: wake from ACE unconsciousness. Expected: rifle in hand.

Fail if: the launcher is in hand after getting up with the setting on.

### ❌ 26. AI edge cases (1.27.0)

What it does: Fixes from the AI edge-case review: no friendly suppressive fire, grenade dodge keeps waypoints, no frag at close walls, medics stay put, courage floor (1.27.0).

Setup: squad AI, an Antistasi patrol, a small room with a wall.

1. Stand a friendly AI next to a squadmate and let the squadmate fire bursts past him. Expected: he crouches but does not start suppressive fire at his squadmate's position.
2. Throw a grenade next to an Antistasi patrol leader. Expected: he runs and afterwards walks on along his waypoint (`currentWaypoint group _leader` unchanged, he is not idle).
3. Put an AI soldier in a small room, 12 m from an enemy he cannot see, with a wall right in front of him. Expected: no frag is thrown at the wall.
4. A group medic treating a wounded mate with no enemy within 60 m. Expected: he is not sent to cover mid-treatment.
5. `units group player apply { _x skill "courage" }` is at least the floor. Turn `auqol_squad_reaction` off: the old values return.

Fail if: a friendly is shot at, a patrol stops its route, or a grenade bounces off a close wall.

### ❌ 27. Squad tactics (1.28.0)

What it does: Squad tactics: call-outs, ambush hold-fire, overwatch cover, breach and clear, night light discipline (1.28.0).

Setup: a squad of 3 to 4 AI, enemy snippet, a building with an enemy in it, night with NVGs on the squad.

1. Press T on an enemy. Expected: group chat shows "Contact! ..." from one AI with a plausible clock position.
2. Set the squad to Stealth behaviour with Open fire. Let an enemy walk past. Expected: they hold fire. Fire one shot yourself: all open up. Leaving Stealth also ends the hold.
3. In contact, stop for 3 s. Expected: free AI move to nearby cover (within 15 m). Walk off: they rejoin. An AI you told to move or stay is not touched.
4. Mark an enemy inside a house with T (within 80 m by default). Expected: two AI go into the house to positions near him; after 30 s they rejoin.
5. At night with NVGs on the squad and a weapon light on a rifle. Expected: the light stays off; by day it is Auto again.
6. Throughout, with `auqol_debug`: no script errors; stuck recovery reports nothing for overwatch or breach units.

Fail if: an ambush hold continues after you shoot, or AI you ordered are moved.

### ❌ 28. Ladders (1.29.0)

What it does: Climbing is 2.5 times as fast for you and every AI (engine `ladderSpeed` set in config, so the climb itself is faster, not only the animation). Ctrl+S slides you down a ladder (`auqol_anim_ladderSlide`).

Setup: a tall ladder (Altis tower), a stopwatch.

1. Time a climb from bottom to top without AUQOL (vanilla), then with AUQOL. Expected: AUQOL is about 2.5 times faster. `getAnimSpeedCoef player` reads 1 and `getNumber (configFile >> "CfgAnimation" >> "ladderSpeed")` reads 1.25.
2. On a ladder press Ctrl+S (rebind under Controls, Configure Addons). Expected: you step off and reach the foot in a second or two, taking no damage. Off a ladder, nothing happens. Turn `auqol_anim_ladderSlide` off: nothing happens on a ladder either.
3. Order a squad AI up the ladder (move order to the top). Expected: it climbs and is not slower than vanilla. Stuck recovery does not report it while it climbs.
4. With Ladder Tweak Remastered loaded as well: the speed is the same as with AUQOL alone. Use only one of the two slide keys.

Fail if: the climb is not clearly faster, the slide hurts you, or the AI refuses the ladder.

### ❌ 29. Covering fire (1.23.0)

What it does: Smart combat covering AI fire more often (`auqol_combat_fireChance`, default 80%, was 35%).

Setup: `tests/ingame/combat_test.sqf` or an enemy squad you attack.

1. Watch the covering team for 30 s at the default 80%. Expected: most of them are shooting at the enemy at any moment.
2. Set the slider to 10% and watch again. Expected: far fewer fire.
3. Set it to 100%. Expected: every covering AI that can see an enemy fires each pass (every 3 s). Ammo resupply (`auqol_combat_resupply`) still works.
4. Soldiers on Hold fire, or in a Stealth ambush (test 27), do not fire.

Fail if: the slider has no visible effect.

### ❌ 30. Downed aircraft and AI across machines (1.24.0, 1.29.1, 1.29.2)

What it does: Enemy aircraft that crash intact lose their crew, and the grenade dodge, vehicle freeze and night spotting work on every machine in multiplayer.

Setup: a dedicated server, one client (you), ideally a headless client. `auqol_combat_dodge` on; LAMBS and Vcom not loaded (they stand dodge down).

1. Shoot down an enemy crewed helicopter and a plane without destroying them (test 2.5). Expected: the crew gets out.
2. **Grenade dodge.** Throw a grenade next to enemy AI on the server. Expected: they run. Have an enemy throw one next to your squad on your client (Zeus). Expected: your squad runs.
3. **Vehicle freeze per machine.** As the client, drive a car, leave it and go over 500 m away. Expected: on your machine `dynamicSimulationEnabled _car` is true, and on the server the same for vehicles it owns.
4. **Night skills on the headless client.** At night, move an AI group to the headless client (or let Antistasi hand it over). Expected: its night spotting applies after about 2 s and no RPT error appears.
5. **Ambush across groups.** Put the squad in Stealth with Open fire, then join an AI to another group. Expected: the hold-fire stays active until you shoot.
6. Check the RPT of every machine for script errors.

Fail if: grenades only make AI dodge on the machine that threw them, or any step shows an error.

### ❌ 31. Audit follow-ups to look at (1.29.0 to 1.29.2)

What it does: Items the full audit could not decide without a game run. Record the result next to each.

Setup: `auqol_debug` on; enemy snippet; a building; a ladder.

1. **AI on ladders.** Time an AI climbing a tall ladder (move order to the top) with `auqol_anim_aiSpeed` 1.25, then with `auqol_anim_ai` off. Write both times down. Fail if the AI is slower with the setting on.
2. **Throw aim.** Make an AI throw a frag or smoke at an enemy spot (use test 15 step 5). Place a marker at the target (`createMarker`) and watch the landing point. Fail if it lands more than 15 m from the target or is thrown sideways.
3. **Breach range.** Put an enemy in a building at 80 m, 120 m and 150 m and press T on each. Expected: AI are sent in only within the configured range. Say whether 80 m or 40 m feels right.
4. **Fired handler cost.** In a large firefight for 5 minutes read the RPT `Timing:` lines for the grenade dodge and launcher re-check. Expected: well under 1 ms average.
5. **Look to spot repeat limit.** Look at the same enemy repeatedly. Expected: it is announced again only after 20 s.

Fail if: any value is outside what is written; report the numbers.

### ❌ 32. Combat AI handoffs (1.30.0)

What it does: Smart combat, squad features and squad tactics hand units to each other cleanly.

Setup: `auqol_debug` on, `tests/ingame/combat_test.sqf`, a squad of 3 AI, an Antistasi mission.

1. **Cover walk.** Start a fight with `combat_test.sqf`. Expected: units sent to cover walk there before firing; none stands in the open firing while its cover is 10 m away.
2. **T focus on walkers.** Stop in contact so overwatch sends AI to cover, then press T on an enemy. Expected: they finish the walk, then fire at it.
3. **Treat and return.** Hurt a smart combat soldier so it treats itself. Expected: afterwards it takes a new spot (RPT "Tactics" lines) with no "rests 30 s" after a single treatment.
4. **Blocked overwatch.** Put a wall between a squad AI and its cover spot. Expected: after 15 s it rejoins formation and is not re-sent for 30 s.
5. **Ambush.** In Stealth, fire one shot. Expected: the squad opens up and stays free to fire until you leave and re-enter Stealth. Breach with T while holding fire: the hold ends.
6. **Modes.** Set your squad to Safe and stop in contact: no overwatch. Stealth: they hold fire and take cover. An allied AI group on Stealth (Zeus) near an enemy moves between cover without shooting until shot at. Aware and Combat: everything runs as before.
7. **Settings menu.** Expected: the three groups appear together as "Combat AI: ...".

Fail if: a unit fires in the open with cover near, is re-sent immediately after a blocked walk, or keeps the hold after you shot.
