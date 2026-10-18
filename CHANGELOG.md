# Changelog

Versions are `MAJOR.MINOR.PATCH`, set in `addons/main/script_version.hpp`. A new feature bumps MINOR, a fix bumps PATCH, and a change that breaks existing settings bumps MAJOR.

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
