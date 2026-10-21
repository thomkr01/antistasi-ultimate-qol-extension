# File map

Where everything lives. Update this file whenever a file is added, moved or removed.

## Mod code (`addons/main/`, packed into `auqol_main.pbo`)

| Path | What it is |
| --- | --- |
| `config.cpp` | CfgPatches (name, CBA dependency), `maxSoldierLoad` (no total weight limit), `AIAvoidStance` (AI avoid prone), XEH registration, CfgFunctions list. Every new function needs a `class` line here. |
| `script_version.hpp` | The version, `MAJOR.MINOR.PATCH`. Changing it on `main` publishes a GitHub release. |
| `$PBOPREFIX$` | PBO prefix `z\auqol\addons\main`. |
| `XEH_preInit.sqf` | All CBA settings (names, defaults, ranges, tooltips) and global state (concealment state and Hide Among The Grass detection, night vision cache, service cache, launcher flag cache, tracked and pending vehicle markers, tracked stuck-AI list, garage fuel cache, frozen vehicle list, debug timings, LAMBS/Vcom detection, grenade and ammo caches, ACE medical flag, item type and loot vehicle class caches). |
| `XEH_postInit.sqf` | Event wiring: CBA network events, class InitPost handlers (one for every non-man object except weapon holders, one per unit for the faster reactions and their `Local` event, the AI animation speed, the `Suppressed` handler and the group `EnemyDetected` hook), the `Fired` class handler for the grenade dodge and the launcher re-check after each round, the smart combat reveal CBA event, the player animation speed CBA event, the arsenal's `arsenalOpened` scripted event, the vanilla `Service` event, settings-ready hook. |
| `functions/common/` | `fn_settingsInitialized` (starts timers, each 0.15 s after the previous one so they never share a frame, and hooks: the 5 s stuck-AI pass, the 1 s vehicle marker pass with the marker created/deleted and map opened events, the launcher fallback (5 s while an enemy vehicle is known, 1 s while an enemy aircraft is), the 60 s AI reaction fallback, the 30 s vehicle freeze pass, the 1 s night spotting pass (a fifth of the AI each time, so each every 5 s), the 0.5 s look-to-spot pass, the 1 s concealment pass and its toggle keybind, the player unit/loadout/group events with a 15 s fallback that also runs self-treat, the Reveal target key handler, the 15 s AI animation speed pass, the player `AnimStateChanged` hook, and applies everything once settings are final), `fn_diagnostics` (RPT report), `fn_perfRun` (runs a timer pass and, with debug logging, times it), `fn_log`, `fn_isHostileSide`. |
| `functions/eject/` | Enemy crew ejection (land vehicles and downed aircraft): vehicle event handlers (`fn_ejectInitVehicle`), the immobilized and eligibility checks, and moving units out. |
| `functions/service/` | Infinite service stock: config detection (`fn_serviceConfig`), vanilla refills from the `Service` event, applying to all vehicles, the Antistasi garage fuel restore, clearing scratches (`fn_serviceScratches`). |
| `functions/player/fn_playerApply.sqf` | No sway, unlimited stamina, weightless running and the recoil slider for the local player, and for the AI in their group when `auqol_player_squad` is on. |
| `functions/squad/` | Squad reactions: raising the reaction skills of squad and friendly AI on each machine (`fn_squadReactApply`), the Reveal target (T) key with its on-screen confirmation (`fn_squadRevealTarget`) and the 30 s focus on the revealed enemy (`fn_squadRevealFocus`), looking at enemies to spot them (`fn_squadLookSpot`), wounded AI treating themselves and clearing stale hurt damage (`fn_squadSelfTreat`), the switch to AT or AA launchers (`fn_squadLaunchers`), whether an enemy is out of the fight and worth no more rounds (`fn_squadIsOutOfFight`) and the player group's `EnemyDetected` and `UnitJoined` hooks (`fn_squadGroupHooks`), radio call-outs (`fn_squadCallout`), ambush discipline (`fn_squadAmbush`), overwatch (`fn_squadOverwatch`) and breach and clear (`fn_squadBreach`). |
| `functions/map/fn_mapVehicleMarkers.sqf` | Live vehicle markers: recognises the markers Antistasi's `A3A_fnc_vehicleMarkers` makes (new ones from `MarkerCreated`, full scan every 30 s), pairs each with a vehicle of the matching icon kind, re-pairs one that Antistasi moved elsewhere, and moves them to their vehicle when it moved more than 5 m. |
| `functions/loadout/` | "Copy from user" in Antistasi's rebel loadout editor: adding the button when the editor opens (`fn_loadoutCopyInit`), copying the player's loadout (`fn_loadoutCopyFromUser`) and removing locked items from a loadout, including attachments and magazines on weapons stored in containers (`fn_loadoutFilter`). |
| `functions/stuck/` | AI stuck detection and recovery: the 5 s pass over the chosen scope with its tracked unit list (`fn_stuckMonitor`), the eligibility and before-moving checks (`fn_stuckIsEligible`), per-unit progress and step choice (`fn_stuckEvaluate`), the four recovery steps (`fn_stuckRecover`), safe-spot search (`fn_stuckFindPosition`), messages (`fn_stuckNotify`) and the debug-console test helper (`fn_stuckSimulate`). |
| `functions/loot/` | Loot from any vehicle: which objects get the action (`fn_lootIsTarget`), adding it (`fn_lootInitObject`, `fn_lootAddAction`), the server run, which checks the sender, player and object first (`fn_lootGather`) and emptying nearby item caches (`fn_lootCaches`). |
| `functions/anim/` | Animation speed: faster AI animations on every machine (`fn_animAiApply`) and the local player's pistol swap boost, and the primary weapon after getting up from unconscious, from their `AnimStateChanged` event (`fn_animPlayerState`). |
| `functions/combat/` | Smart combat AI: the group `EnemyDetected` hook (`fn_combatGroupHook`), starting a group's 3 s pass (`fn_combatStart`), the pass with its two fire teams, building clearing, flanking, suppressive fire and grenades (`fn_combatTick`), which members may be moved (`fn_combatIsEligible`), finding covered spots (`fn_combatFindCover`), throwing frags and smoke (`fn_combatThrow`), handing units back (`fn_combatRelease`), contact reports between groups (`fn_combatShareContact`), the grenade dodge (`fn_combatDodge`), magazine sharing and medics (`fn_combatSupport`) and the `Suppressed` handler that reveals the shooter and makes standing AI get low (`fn_combatSuppressed`). |
| `functions/conceal/` | Hide among the grass: the 1 s pass and trait changes with the hit, near-shot and get-in events (`fn_concealTick`), the hiding rules and partial camouflage (`fn_concealFactor`), shot counting (`fn_concealOnFired`), the hidden / revealed indicator (`fn_concealHud`), uniform camouflage (`fn_concealCamo`) and hard to locate at range: the give-away distance of a shot (`fn_concealLocateShot`) and the check on hostile groups (`fn_concealLocateCheck`). |
| `data/conceal/` | The indicator icons from Hide Among The Grass (APL-SA, credited in README). |
| `functions/night/` | Night spotting: scaling enemy AI spotting skills by darkness and nearby noise (`fn_nightApply`) and whether a unit has night vision or thermal in its gear or vehicle (`fn_nightHasVision`). |
| `functions/freeze/fn_freezeVehicles.sqf` | Marks parked empty vehicles and settled wrecks for Arma's dynamic simulation (server), and unmarks them. |
| `functions/withstand/fn_withstandApply.sqf` | Antistasi Withstand cooldown. |
| `compat/ace/` | ACE3 only: infinite refuel sources, limited rearm top-up, sway and fatigue factors. |

## Docs

| Path | What it is |
| --- | --- |
| `README.md` | Short overview: what the mod does, how it works, install, links to the docs, credits. |
| `FEATURES.md` | What each feature does and its rules, how it works, known limitations. |
| `CHANGELOG.md` | One section per version, plus the versioning rules. |
| `FILEMAP.md` | This file. |
| `docs/installation.md` | Install steps, building from source, troubleshooting. |
| `docs/configuration.md` | Every setting in detail, with what it changes and what it leaves alone. |
| `docs/compatibility.md` | ACE, Antistasi, RHS and CUP integration and multiplayer locality. |
| `docs/service-audit.md` | Audit of every fuel, ammo, repair, medical and logistics service, and what AUQOL does with each. |
| `docs/testing.md` | Static checks, in-game results and the in-game test plan. |
| `CONTRIBUTING.md` | Code conventions and how to release. |
| `mod.cpp` | Launcher name, description and link. |

## Build and tests

| Path | What it is |
| --- | --- |
| `.hemtt/project.toml` | HEMTT project: prefix, version source, files included in the release. |
| `tools/build.sh` | Runs the static checks, `hemtt check` and `hemtt release`. `tools/build.ps1` is the Windows version. |
| `tools/check_ingame_scripts.sh` | Compiles the in-game test scripts. |
| `tests/static_checks.py` | Checks functions, settings and docs, Arma commands and events, every CBA, ACE and Antistasi name the code uses against their sources, and regression guards for fixed edge cases. |
| `tests/ingame/*.sqf` | Debug-console scripts for testing ejection, service stock, player features, AI stuck recovery (`stuck_test.sqf`), smart combat tactics (`combat_test.sqf`) and the Copy from user filter (`loadout_test.sqf`) in game. |
| `.github/workflows/ci.yml` | CI: checks and build on every push. Publishes a GitHub release when `main` has a new version. |
