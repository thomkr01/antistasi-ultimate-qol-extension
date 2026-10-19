# File map

Where everything lives. Update this file whenever a file is added, moved or removed.

## Mod code (`addons/main/`, packed into `auqol_main.pbo`)

| Path | What it is |
| --- | --- |
| `config.cpp` | CfgPatches (name, CBA dependency), `maxSoldierLoad` (no total weight limit), XEH registration, CfgFunctions list. Every new function needs a `class` line here. |
| `script_version.hpp` | The version, `MAJOR.MINOR.PATCH`. Changing it on `main` publishes a GitHub release. |
| `$PBOPREFIX$` | PBO prefix `z\auqol\addons\main`. |
| `XEH_preInit.sqf` | All CBA settings (names, defaults, ranges, tooltips) and global state (service cache, launcher flag cache, tracked and pending vehicle markers, tracked stuck-AI list, garage fuel cache). |
| `XEH_postInit.sqf` | Event wiring: CBA network events, class InitPost handlers, the arsenal's `arsenalOpened` scripted event, the vanilla `Service` event, settings-ready hook. |
| `functions/common/` | `fn_settingsInitialized` (starts timers and hooks: the 5 s stuck-AI pass, the 1 s vehicle marker pass with the marker created/deleted events, the 5 s launcher fallback, the 5 s AI reaction pass, the player unit/loadout/group events with a 15 s fallback, the Reveal target key handler, and applies everything once settings are final), `fn_diagnostics` (RPT report), `fn_log`, `fn_isHostileSide`. |
| `functions/eject/` | Enemy crew ejection: vehicle event handlers (`fn_ejectInitVehicle`), the immobilized and eligibility checks, and moving units out. |
| `functions/service/` | Infinite service stock: config detection (`fn_serviceConfig`), vanilla refills from the `Service` event, applying to all vehicles, the Antistasi garage fuel restore. |
| `functions/player/fn_playerApply.sqf` | No sway, unlimited stamina, weightless running and no recoil for the local player, and for the AI in their group when `auqol_player_squad` is on. |
| `functions/squad/` | Squad reactions: raising the reaction skills of squad and friendly AI on each machine (`fn_squadReactApply`), the Reveal target (T) key (`fn_squadRevealTarget`), the switch to AT or AA launchers (`fn_squadLaunchers`) and the player group's `EnemyDetected` and `UnitJoined` hooks (`fn_squadGroupHooks`). |
| `functions/map/fn_mapVehicleMarkers.sqf` | Live vehicle markers: recognises the markers Antistasi's `A3A_fnc_vehicleMarkers` makes (new ones from `MarkerCreated`, full scan every 30 s) and moves them to their vehicle when it moved more than 5 m. |
| `functions/loadout/` | "Copy from user" in Antistasi's rebel loadout editor: adding the button when the editor opens (`fn_loadoutCopyInit`) and copying the player's loadout, unlocked items only (`fn_loadoutCopyFromUser`). |
| `functions/stuck/` | AI stuck detection and recovery: the 5 s pass over the chosen scope with its tracked unit list (`fn_stuckMonitor`), the eligibility and before-moving checks (`fn_stuckIsEligible`), per-unit progress and step choice (`fn_stuckEvaluate`), the four recovery steps (`fn_stuckRecover`), safe-spot search (`fn_stuckFindPosition`), messages (`fn_stuckNotify`) and the debug-console test helper (`fn_stuckSimulate`). |
| `functions/loot/` | Loot from any vehicle: which objects get the action (`fn_lootIsTarget`), adding it (`fn_lootInitObject`, `fn_lootAddAction`), the server run (`fn_lootGather`) and emptying nearby item caches (`fn_lootCaches`). |
| `functions/withstand/fn_withstandApply.sqf` | Antistasi Withstand cooldown. |
| `compat/ace/` | ACE3 only: infinite refuel sources, limited rearm top-up, sway and fatigue factors. |

## Docs

| Path | What it is |
| --- | --- |
| `README.md` | Overview, install, full settings table, compatibility summary, limitations. |
| `FEATURES.md` | What each feature does and its rules, in plain words. |
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
| `tests/static_checks.py` | Checks functions, settings and docs, Arma commands and events, and every CBA, ACE and Antistasi name the code uses against their sources. |
| `tests/ingame/*.sqf` | Debug-console scripts for testing ejection, service stock, player features and AI stuck recovery (`stuck_test.sqf`) in game. |
| `.github/workflows/ci.yml` | CI: checks and build on every push. Publishes a GitHub release when `main` has a new version. |
