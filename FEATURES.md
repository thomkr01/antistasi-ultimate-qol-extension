# Features

This is what the Antistasi Ultimate QoL Extension (AUQOL) does, and the rules each feature follows. Version 1.2.2. The [README](README.md) covers installation and the settings table. The [docs](docs/) folder has the details.

## Ground rules

- **Standalone addon.** No Antistasi mission files are edited. Everything hooks in from outside, through CBA and engine events.
- **CBA_A3 is the only hard dependency** (`requiredAddons[] = {"cba_main"}`).
- **ACE3, RHS and CUP are optional.** They are detected at runtime, and each feature works with or without them.
- **Only verified APIs are used.** Every engine command, CBA function, ACE function and Antistasi global was checked against its source. `tests/static_checks.py` enforces this on every build.
- **Every feature is on by default and has its own CBA setting** under *Addon Options → Antistasi Ultimate QoL by TchicX*, and can be toggled during a mission.
- **Multiplayer safe.** Each action runs on the machine that owns the object, as the command's locality requires. Cross-machine calls are named CBA events with fixed handlers, never `remoteExec`.

## 1. Enemy AI crew ejection from immobilized vehicles

When an enemy AI land vehicle is immobilized, its living enemy AI crew get out and stop using it. They don't sit inside a dead tank or a stuck truck.

- **Immobilized** means the engine reports the vehicle can no longer move (`canMove` is false: tracks, wheels or engine destroyed). By default an empty fuel tank also counts (`auqol_eject_outOfFuel`). A vehicle that is only stopped or parked is not affected.
- **Who gets out:** only living AI on a side hostile to the rebels.
- **Who stays in:** players, friendly AI, captives, surrendered units (Antistasi convoy prisoners and POWs), ACE-handcuffed or ACE-surrendering units, and units or vehicles tagged with `auqol_noEject`. UAVs and static weapons are ignored.
- **No repeats or loops.** Triggering is event-driven, from the engine's damage, fuel and get-in events. There is no per-frame scan. Each vehicle has one pending check at a time and waits until it has nearly stopped, for at most a few retries. Ejected units are unassigned from the vehicle, so they don't climb back in.
- **Correct locality.** The vehicle's owner decides. Each unit is moved out on the machine that owns it, which covers headless clients.
- **Settings:** `auqol_eject_enabled` and `auqol_eject_outOfFuel`, both server-wide and on by default.

## 2. Infinite stock for service vehicles

Fuel, ammo and repair trucks, plus the other recognized service sources, never run out of what they hand out. This is based on an audit of every vanilla, Antistasi and ACE service: fuel, ammo, repair, medical and logistics. The full table is in [docs/service-audit.md](docs/service-audit.md).

- **Only depleting services are changed.** Services that are already unlimited are left alone: ACE unlimited rearm, Antistasi garage ammo and repair, ACE repair, and all medical and logistics.
- **The service truck's own engine fuel stays finite.** Only the stock it gives out is infinite. Ordinary vehicles keep normal fuel, ammo and damage.
- **Vanilla:** fuel, ammo and repair cargo are refilled as they are used, triggered by the engine's `Service` event.
- **ACE:** fuel sources use ACE's own infinite mode. In ACE's "limited" rearm mode, ammo supply is kept topped up. ACE's "magazine supply" mode is left alone, because it stores real magazines.
- **Antistasi garage:** fuel stored in garaged fuel sources is restored, so pulling vehicles out never drains them.
- **RHS and CUP** service trucks are covered through the same config fields. No class lists are needed.
- **Settings, one per category:** `auqol_service_fuel`, `auqol_service_ammo`, `auqol_service_repair` and `auqol_service_garageFuel`. All are server-wide and on by default. Turning one off restores normal stock behaviour.
- **Diagnostics:** `call AUQOL_fnc_diagnostics` prints which handler each feature uses (vanilla or ACE). `auqol_debug` logs each action.

## 3. No weapon sway

Weapon sway is removed for your own character only. AI and other players are unchanged.

- **Vanilla:** the aim coefficient is set to 0.
- **ACE:** when ACE sway is on, a sway factor of 0 is added through ACE's own API, so ACE doesn't override it.
- **Setting:** `auqol_player_noSway`, per client, on by default.

## 4. Unlimited stamina

Your own character never runs out of stamina. AI is unchanged.

- **Vanilla:** stamina is disabled for the local player.
- **ACE Advanced Fatigue:** a duty factor of 0 is added, so ACE fatigue never builds up.
- **Setting:** `auqol_player_unlimitedStamina`, per client, on by default.

## 5. Running speed unaffected by weight

Carried weight no longer slows you down, forces you to walk or drains stamina faster.

- The `loadCoef` trait is set to 0. Antistasi resets it by role after respawn, so it is re-applied, and the role's value comes back if you turn the setting off.
- **ACE:** ACE's movement load base and the load it reports to fatigue are kept at 0 as well.
- **Setting:** `auqol_player_weightless`, per client, on by default.

## 6. Carrying capacity multiplier

Your uniform, vest and backpack hold more, by a multiplier of 9999 by default.

- Applied on the server to the containers players are wearing, as the engine requires. Changing gear or respawning re-applies it. A dropped container goes back to its normal capacity, so anyone who picks it up gets the normal amount.
- **Total load cap:** the game caps a soldier's total load at `maxSoldierLoad` (vanilla 1000). Script can't change it per unit, so AUQOL raises it to 9999 in config. That applies to every unit, AI included, and has no in-game switch.
- **Settings:** `auqol_capacity_enabled` (on) and `auqol_capacity_multiplier` (1 to 9999, default 9999). Both are server-wide.

## 7. Loot from any vehicle

Every vehicle works like Antistasi's loot crate, so you don't have to buy and haul the crate around.

- **Same action as the crate:** "Gather Scattered Loot", a 2-second hold, on foot within 5 m. It is added to every land vehicle, aircraft and boat, but not static weapons.
- **Same behaviour as the crate:** the server runs Antistasi's own crate function. Loot from dead bodies, dropped weapons and surrender crates goes into the vehicle. Money is split between rebel players, unlocked items follow the mission's parameter, and there is a 10-second cooldown.
- **One radius for both:** vehicles and the loot crate use `auqol_loot_radius`, 10 to 2000 m, default 2000. Antistasi's own crate parameter only goes to 400.
- **Separate enemy check:** gathering is refused while an enemy in combat is within `auqol_loot_enemyRadius` of the vehicle, 10 to 2000 m, default 500. So you can gather from 2000 m while only nearby enemies block it.
- **Settings:** `auqol_loot_enabled` (on), `auqol_loot_radius` and `auqol_loot_enemyRadius`. All are server-wide. Turning loot off removes the vehicle action and puts the crate back on Antistasi's radius.

## 8. Short Withstand cooldown

Antistasi's Withstand self-revive normally has a 5-minute cooldown. AUQOL sets it to 1 second.

- The time is adjustable from 1 to 300 seconds (`auqol_withstand_timeout`, default 1). `auqol_withstand_enabled` (on) switches it, and off means Antistasi's 300 s.
- Antistasi ties Withstand's after-effects (grey screen, aim penalty) to the same timer, so they also end after 1 second.
- The mission's Withstand self-revive parameter still has to be turned on.

## Status

Built and statically validated: the config, SQF and every API reference are checked. None of it has been tested in game yet. The in-game test plan is in [docs/testing.md](docs/testing.md).
