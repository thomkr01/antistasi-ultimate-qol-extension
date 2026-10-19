# Changelog

Versions are `MAJOR.MINOR.PATCH`, set in `addons/main/script_version.hpp`. A new feature bumps MINOR, a fix bumps PATCH, and a change that breaks existing settings bumps MAJOR.

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
