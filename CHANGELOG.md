# Changelog

Versions are `MAJOR.MINOR.PATCH`, set in `addons/main/script_version.hpp`. A new feature bumps MINOR, a fix bumps PATCH, and a change that breaks existing settings bumps MAJOR.

## 1.9.0

None of this has been tested in game yet.

- New: wounded squad AI treat themselves (`auqol_squad_selfTreat`, on). An AI in your group that is really hurt (limping and can't run, or badly hit) uses its own first aid kit, or medikit if it is a medic, 3 s after being hit, instead of waiting for you to order it. Light leftover damage that only keeps the red hurt icon up (Antistasi's non-medic revive leaves 0.25, and so does a first aid kit) is cleared without a kit, by default only on AI that carry a medikit (`auqol_squad_selfTreatMedikit`, on; off clears it on every AI). Units Antistasi's medical is already handling are left alone, and the feature is off under ACE medical, whose own AI medical treats AI.
- Recoil is now a slider, `auqol_player_recoil`, 0 to 100%, instead of the No recoil checkbox. 100% (the default) is vanilla recoil, 0% is the old No recoil. The old `auqol_player_noRecoil` setting is gone: if you had it on, set the slider to 0%.
- Reveal target (T) fix: the enemy you reveal now becomes your squad's focus for 30 s. Every second any AI that turned to another target is put back on it, and is told to fire when its combat mode allows (Fire at will or Engage at will). A new T press always moves the focus to the new enemy, and the old one stays known. Before, the AI got one `doTarget` that their own target choice could override at once.
- Contact reports: when your group spots a new enemy, every AI in it gets the sighting at once instead of waiting for the spoken contact report to reach it through the radio queue (part of `auqol_squad_reaction`).
- Asynchronous work: SQF runs on one thread per machine, so scripts can't be spread over CPU cores. The engine already runs AI, physics and rendering in its own threads. What a mod can do is avoid work and avoid waiting, so the new features are event-driven (a hit, a key press, a sighting) with the existing 15 s player pass as the only fallback, and nothing new polls.

## 1.8.1

Fixes for edge cases found in a review of 1.8.0. Nothing from 1.8.0 changed otherwise; none of these fixes has been tested in game yet.

- Loot: the server now checks every request before it empties caches or gathers: it must come from the machine of the player who held the action, and that player must be alive, on foot and within 10 m of a vehicle or crate that has the action. The request is sent with `remoteExecCall` for this, the only one in the mod. A second request for the same object within 10 s is refused, so double sends can no longer empty caches twice or start two gathers.
- Copy from user: weapons stored in the uniform, vest or backpack are now checked like weapons in hand: as their base class, then each attachment and loaded magazine on its own. Before, a locked optic or magazine on a stored weapon was copied along. Ammo counts and quantities are kept. New regression test `tests/ingame/loadout_test.sqf`.
- Faster AI reactions: the original skills are saved once and as a public unit variable, so a unit moving between the server and a headless client no longer takes the raised values as its originals, and turning the feature off restores the real ones.
- No sway and no recoil: turning them off now puts back the value the unit had before, instead of always 1.
- Crew ejection: a pending ejection rechecks the setting, vehicle and crew right before it runs, so turning the feature off stops it. If the vehicle changes owner during the wait, the check is handed to the new owner instead of being dropped.
- AI stuck recovery: a unit that keeps moving without getting closer to a fixed destination (circling an obstacle, going back and forth) is now detected once it has not got closer for three timeouts. Shorter detours and formation followers behave as before.
- Live vehicle markers: a marker is only paired with a vehicle of the matching kind (the icon Antistasi chose), and a marker that Antistasi's own minute update moves away from its paired vehicle is re-paired from there, so a wrong pairing fixes itself without the marker jumping.
- Rule added to the contributing guide: build for compatibility with as many mods as possible, and always with Antistasi Ultimate, RHS, CUP and ACE3.

## 1.8.0

- Loot gathering: the enemy check radius default is now 100 m (was 500 m). The gather radius stays 2000 m.
- AI stuck recovery is more conservative. Units that are captive, attached, remote controlled, in an inventory, healing or scripted (`Acts_`) animation, or on a SCRIPTED waypoint are never watched. Right before a hop or teleport the unit is checked again, and is not moved if it is now fighting, in COMBAT behaviour, healing, rearming, surrendering, on a static weapon or in a vehicle (teleport).
- Fewer recurring scans:
  - Stuck recovery keeps a list of each machine's friendly AI for the wider scopes, rebuilt every 30 s and pruned every check, instead of filtering every unit each time.
  - Launchers are checked when your group spots a new enemy and on the T key, with a 5 s fallback (was every second).
  - Live vehicle markers: new markers come from the marker-created event (full scan every 30 s as fallback), and a marker is only moved when its vehicle moved more than 5 m.
  - Player perks follow unit, loadout and group changes and recruits joining, with a 15 s fallback (was every 5 s).
  - Garage fuel: each class's full value is cached; nothing is written for sources already full.
- Withstand and crew ejection reported working in game.

## 1.7.1

- Live vehicle markers: the 1-second pass no longer searches the whole map marker list for every tracked marker to see whether Antistasi deleted it. Same behaviour, less work on maps with many markers.

## 1.7.0

- Faster AI reactions can cover every friendly AI, not just your squad: garrisons, static and turret gunners and high-command squads (`auqol_squad_reactionAll`, on by default). Each machine applies it to its own AI every 5 seconds. Accuracy is still unchanged.

## 1.6.0

- Faster squad reactions: the AI in your group get spot time, spot distance, aiming speed and commanding raised to at least 0.8 (`auqol_squad_reaction`, `auqol_squad_reactionSkill`). Accuracy is unchanged.
- The Reveal target key (T) now alerts your squad: your whole group knows about the enemy you look at, and your AI target it when you lead (`auqol_squad_revealKey`).
- Squad AI switch to a loaded AT or AA launcher as soon as they know about an enemy vehicle they can see and hit (`auqol_squad_launchers`).
- Live vehicle markers: Antistasi's markers on convoy objectives, mission vehicles, supply boxes and spotted enemy vehicles follow their vehicle every second instead of once a minute (`auqol_map_liveVehicles`).
- All four are on by default.

## 1.5.0

- Squad perks: no sway, unlimited stamina, weightless running and no recoil also apply to the AI in your group (`auqol_player_squad`, on by default). Each still follows its own player setting.
- "Copy from user" button in Antistasi's Set Rebel Loadout arsenal: loads your own loadout into the role being edited, unlocked items only, with the slot overrides switched on (`auqol_loadout_copyFromUser`, on by default).
- AI stuck detection and recovery: friendly AI with somewhere to go that make no progress are freed in steps (refresh order, rejoin formation, short safe hop, optional emergency teleport to the squad leader), with cooldowns, a round limit and optional chat messages. Your squad only by default. 14 new `auqol_stuck_*` settings; the teleport and the "got stuck" messages are off by default.

## 1.4.1

- Item caches emptied by loot gathering are now deleted instead of left behind empty.

## 1.4.0

- Loot gathering also empties enemy item caches (outpost, base and airport supply crates) within 30 m of the vehicle or loot crate (`auqol_loot_caches`, on by default).

## 1.3.0

- No total weight limit: `maxSoldierLoad` raised to 10,000,000, so heavy items no longer stop you picking up more.
- Removed the container capacity feature (`auqol_capacity_enabled`, `auqol_capacity_value`). Uniforms, vests and backpacks keep their normal size.
- No recoil option for the local player (`auqol_player_noRecoil`), off by default.

## 1.2.4

- Carrying capacity is a fixed value per worn container (`auqol_capacity_value`, default 9999) instead of a multiplier. It replaces `auqol_capacity_multiplier`, so a saved multiplier value no longer applies.

## 1.2.3

- No sway, unlimited stamina and weightless running are now server settings (`isGlobal = 1`): the server decides for every player. They still run on each player's machine.

## 1.2.2

- Carrying capacity multiplier default and maximum raised from 1000 to 9999 (`auqol_capacity_multiplier`).

## 1.2.1

- In-game name is now "Antistasi Ultimate QoL Extension by TchicX" (launcher, mod list and Addon Options). Setting names are unchanged, so saved settings keep working.
- Releases are published to GitHub automatically when the version changes.

## 1.2.0

- Loot gathering: separate enemy-check radius (`auqol_loot_enemyRadius`, default 500 m), centred on the vehicle or crate. The gather radius now defaults to 2000 m.

## 1.1.0

- Loot from any vehicle: every vehicle gets the loot crate's "Gather Scattered Loot" action, and vehicles and the crate share one radius up to 2000 m (`auqol_loot_enabled`, `auqol_loot_radius`).
- Antistasi Withstand self-revive cooldown set to 1 second, adjustable to 300 (`auqol_withstand_enabled`, `auqol_withstand_timeout`).
- Total soldier load limit raised to 9999 in the main addon. The optional `auqol_maxload` addon is gone.
- Simpler version numbers: three parts, no build number.

## 1.0.0

First version.

- Enemy crew ejection from immobilized land vehicles (`auqol_eject_enabled`, `auqol_eject_outOfFuel`).
- Infinite fuel, ammunition and repair service stock for vanilla, ACE3 (refuel infinite mode, rearm limited-mode top-up) and the Antistasi Ultimate garage fuel sources (`auqol_service_*`).
- No weapon sway, unlimited stamina and weight-independent running for the local player, with ACE3 sway and Advanced Fatigue integration (`auqol_player_*`).
- Carrying-capacity multiplier for worn containers, default 1000x (`auqol_capacity_*`), and the total soldier load limit (`maxSoldierLoad`) raised to 9999.
- Diagnostics (`AUQOL_fnc_diagnostics`, `auqol_debug`), HEMTT build, static checks and CI.
