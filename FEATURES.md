# Features

This is what the Antistasi Ultimate QoL Extension (AUQOL) does, and the rules each feature follows. Version 1.9.0. The [README](README.md) covers installation and the settings table. The [docs](docs/) folder has the details.

## Ground rules

- **Standalone addon.** No Antistasi mission files are edited. Everything hooks in from outside, through CBA and engine events.
- **CBA_A3 is the only hard dependency** (`requiredAddons[] = {"cba_main"}`).
- **ACE3, RHS and CUP are optional.** They are detected at runtime, and each feature works with or without them.
- **Compatible by design.** Every change is built to work alongside as many other mods as possible, and must always work with Antistasi Ultimate, RHS, CUP and ACE3.
- **Only verified APIs are used.** Every engine command, CBA function, ACE function and Antistasi global was checked against its source. `tests/static_checks.py` enforces this on every build.
- **Every feature is on by default (recoil at 100%, which is vanilla) except the emergency teleport and the "unit got stuck" messages, and each has its own CBA setting** under *Addon Options → Antistasi Ultimate QoL by TchicX*, and can be toggled during a mission.
- **Multiplayer safe.** Each action runs on the machine that owns the object, as the command's locality requires. Cross-machine calls are named CBA events with fixed handlers. The one exception is the loot request, a `remoteExecCall` to the server, because only that tells the server which machine sent it.

## 1. Enemy AI crew ejection from immobilized vehicles

When an enemy AI land vehicle is immobilized, its living enemy AI crew get out and stop using it. They don't sit inside a dead tank or a stuck truck.

- **Immobilized** means the engine reports the vehicle can no longer move (`canMove` is false: tracks, wheels or engine destroyed). By default an empty fuel tank also counts (`auqol_eject_outOfFuel`). A vehicle that is only stopped or parked is not affected.
- **Who gets out:** only living AI on a side hostile to the rebels.
- **Who stays in:** players, friendly AI, captives, surrendered units (Antistasi convoy prisoners and POWs), ACE-handcuffed or ACE-surrendering units, and units or vehicles tagged with `auqol_noEject`. UAVs and static weapons are ignored.
- **No repeats or loops.** Triggering is event-driven, from the engine's damage, fuel and get-in events. There is no per-frame scan. Each vehicle has one pending check at a time and waits until it has nearly stopped, for at most a few retries. Right before ejecting, the setting, the vehicle and the crew are checked again, so turning the feature off stops a pending ejection. If the vehicle changes owner during the wait (for example to a headless client), the check is handed to the new owner. Ejected units are unassigned from the vehicle, so they don't climb back in.
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
- Turning it off puts back the aim coefficient the unit had before AUQOL changed it.
- **Setting:** `auqol_player_noSway`, server-wide, on by default.

## 4. Unlimited stamina

Your own character never runs out of stamina. AI is unchanged.

- **Vanilla:** stamina is disabled for the local player.
- **ACE Advanced Fatigue:** a duty factor of 0 is added, so ACE fatigue never builds up.
- **Setting:** `auqol_player_unlimitedStamina`, server-wide, on by default.

## 5. Running speed unaffected by weight

Carried weight no longer slows you down, forces you to walk or drains stamina faster.

- The `loadCoef` trait is set to 0. Antistasi resets it by role after respawn, so it is re-applied, and the role's value comes back if you turn the setting off.
- **ACE:** ACE's movement load base and the load it reports to fatigue are kept at 0 as well.
- **Setting:** `auqol_player_weightless`, server-wide, on by default.

## 6. Recoil slider

Sets how much weapon recoil your own character has, from 0% (no recoil) to 100% (vanilla). AI outside your squad is unchanged.

- Below 100% the recoil coefficient is set to the slider value. Back at 100%, the value the unit had before is put back, not a fixed 1.
- **Setting:** `auqol_player_recoil`, server-wide, **100%** by default, so nothing changes until you move it. It replaced the No recoil checkbox in 1.9.0; 0% is the same as the old setting.

## 7. No total weight limit

You can keep picking things up however heavy your load is. Normally the game stops you once your total load passes a cap, even if your backpack still has room.

- The cap (`maxSoldierLoad`, vanilla 1000) is raised to 10,000,000. Uniform, vest and backpack sizes are unchanged: a container still holds only what fits in it.
- It's a config value, so it applies to every unit, AI included, and has no in-game switch.

## 8. Loot from any vehicle

Every vehicle works like Antistasi's loot crate, so you don't have to buy and haul the crate around.

- **Same action as the crate:** "Gather Scattered Loot", a 2-second hold, on foot within 5 m. It is added to every land vehicle, aircraft and boat, but not static weapons.
- **Same behaviour as the crate:** the server runs Antistasi's own crate function. Loot from dead bodies, dropped weapons and surrender crates goes into the vehicle. Money is split between rebel players, unlocked items follow the mission's parameter, and there is a 10-second cooldown.
- **One radius for both:** vehicles and the loot crate use `auqol_loot_radius`, 10 to 2000 m, default 2000. Antistasi's own crate parameter only goes to 400.
- **Item caches:** enemy item caches (the supply crates at outposts, bases and airports) within 30 m of the vehicle or crate are emptied into it too, with the same unlocked-item and money rules, and the empty box is deleted. `auqol_loot_caches`, on by default.
- **Checked on the server:** the server only acts on a request from the machine of the player who held the action, while that player is alive, on foot and within 10 m of a vehicle or crate that has the action. Repeat requests for the same object within 10 s are refused, so caches can't be emptied twice or by a bad request.
- **Separate enemy check:** gathering is refused while an enemy in combat is within `auqol_loot_enemyRadius` of the vehicle, 10 to 2000 m, default 100. So you can gather from 2000 m while only nearby enemies block it.
- **Settings:** `auqol_loot_enabled` (on), `auqol_loot_radius` and `auqol_loot_enemyRadius`. All are server-wide. Turning loot off removes the vehicle action and puts the crate back on Antistasi's radius.

## 9. Short Withstand cooldown

Antistasi's Withstand self-revive normally has a 5-minute cooldown. AUQOL sets it to 1 second.

- The time is adjustable from 1 to 300 seconds (`auqol_withstand_timeout`, default 1). `auqol_withstand_enabled` (on) switches it, and off means Antistasi's 300 s.
- Antistasi ties Withstand's after-effects (grey screen, aim penalty) to the same timer, so they also end after 1 second.
- The mission's Withstand self-revive parameter still has to be turned on.

## 10. Your squad gets your perks

The AI in your own group get the same no sway, unlimited stamina, weight-independent running and recoil as you.

- Each of the four follows its own player setting, so recoil stays vanilla unless you lower the slider.
- `auqol_player_squad` (on) switches the squad part. Turning it off puts your AI back to normal.
- Applied on your machine to the AI local to it (your recruits are), as soon as they join.
- Under ACE the AI get the vanilla commands, because ACE sway and Advanced Fatigue only run for players.

## 11. "Copy from user" in the rebel loadout editor

In Antistasi's Set Rebel Loadout arsenal, the empty third button in the bottom bar becomes "Copy from user".

- It loads the loadout you were wearing when you opened the editor into the role you are editing. Press Save to keep it, as with any edit.
- Only items the arsenal has unlimited (shown with the infinity sign) are copied, the same rule the editor uses. A locked weapon, uniform, vest, backpack, helmet, facewear or assigned item leaves that slot to Antistasi's random pick; locked attachments, magazines and container items are just dropped. That includes weapons stored in the uniform, vest or backpack: each attachment and loaded magazine is checked on its own, and ammo counts and item quantities are kept. A chat line lists what was skipped.
- Every slot it fills gets its override switch turned on (the green slot icons), so recruits wear exactly that.
- Antistasi already forces the "set loadout" on recruits for every slot whose icon is green; black slots are rolled at random. AUQOL does not change that.
- `auqol_loadout_copyFromUser` (on).

## 12. AI stuck recovery

Friendly AI that should be moving but aren't get freed automatically, cheapest fix first.

**Who is watched** (`auqol_stuck_scope`): the AI in each player's own group (default), friendly AI within `auqol_stuck_scopeRadius` of any player, or all friendly AI. Each machine only checks the AI it owns, every 5 seconds, so the server, headless clients and players never act on the same unit twice. For the wider scopes each machine keeps a list of its friendly AI, rebuilt every 30 seconds; dead, deleted, transferred or no longer friendly units leave it at the next check.

**When a unit counts as stuck.** It needs somewhere to go and nothing else to do:

- the engine says it has a destination (`expectedDestination`), more than 8 m away on foot or 25 m when driving. Units that are "not moving" or doing a direct move such as getting in or resupplying are skipped;
- its only order is a move, or following its leader. Stop and Hold, attack, heal, get in, rearm and other commands are left alone, as are units with movement or pathfinding AI switched off;
- it is not fighting: no attack target, not suppressed, no known enemy within 300 m;
- it is not unconscious, incapacitated, surrendered or captive, and not healing someone or rearming from bodies (Antistasi's own flags);
- it is not attached to anything, not remote controlled by Zeus, and not playing an inventory, healing or scripted animation (the `Acts_` animations missions use for hostages and cutscenes);
- on foot it is on the ground, not swimming and not on a ladder. In a vehicle only the AI driver of a land vehicle that can still move and has fuel counts, and only with no player aboard. Passengers, static weapons, aircraft and boats are skipped;
- in groups led by AI (patrols, garrisons, high-command squads) it is not on a HOLD, GUARD, SENTRY, LOITER, DISMISS or SCRIPTED waypoint and not on a looping patrol route.

Then, if it neither moves `auqol_stuck_minProgress` metres (default 3) nor gets that much closer to its destination within `auqol_stuck_timeout` seconds (default 30), it is stuck. Moving only counts while the unit keeps reaching new closest points to a fixed destination: once it has not got any closer for three timeouts (90 s by default), moving around (circling an obstacle, going back and forth) stops counting and only getting closer does. Detours shorter than that are left alone, and units following a moving destination (their leader) keep the plain movement rule.

**Before moving a unit** (steps 3 and 4) every check above runs again at that moment, plus one more: the unit must not be in COMBAT behaviour. If anything fails, nothing is moved.

**Recovery steps**, each given another timeout window to work before the next one:

1. **Refresh the order** (`auqol_stuck_refreshOrders`, on): the same order to the same place again. A move order is re-issued, an AI leader's current waypoint is set again, a follower is told to follow its leader, a driver is sent on again. Formation, behaviour and waypoints are not changed.
2. **Rejoin formation** (`auqol_stuck_regroup`, on): only for units following their leader with no order of their own. Clears a stuck look target, then stop and follow the leader, which drops a stuck command queue.
3. **Short safe hop** (`auqol_stuck_reposition`, on): moves the unit up to 10 m (a vehicle up to 25 m, never more than `auqol_stuck_maxDistance`) toward its destination, or toward its leader if it is following. The spot must have room for it, be dry, not steep, not under a roof, not more than 3 m above or below, and have no hostile unit within 100 m. Then step 1 again.
4. **Emergency teleport** (`auqol_stuck_teleport`, off): infantry only, to a checked spot next to its squad leader, and only when the leader is within `auqol_stuck_maxDistance` (default 100 m). Never players, vehicles, or units parachuting, swimming or climbing.

The unit's health, gear, group, rank and role are never changed. When every enabled step has failed, the round counts as failed and the unit waits `auqol_stuck_cooldown` seconds (default 60). After `auqol_stuck_maxAttempts` failed rounds (default 3) it is left alone until it moves again by itself.

**Messages** go to the player leading the unit's group: `auqol_stuck_notifyResult` (on) when it moves again or a round fails, `auqol_stuck_notifyDetect` (off) when it gets stuck, with the likely reason (an obstacle in front, terrain, or no path), and for each step. With `auqol_debug` every event is also written to the RPT.

**Testing without a real stuck unit:** `[cursorObject] call AUQOL_fnc_stuckSimulate` in the debug console marks a unit as past the timeout. `tests/ingame/stuck_test.sqf` builds a real stuck case.

## 13. Faster AI reactions

The AI in your own group, and by default every friendly AI, spot enemies sooner, tell each other faster and turn onto targets quicker.

- Antistasi gives recruits low skills early in the campaign (about 0.2 to 0.4), which is why they react slowly. AUQOL raises four of them to at least `auqol_squad_reactionSkill` (default 0.8): spot time, spot distance, aiming speed and commanding (how fast sightings pass through the group).
- Accuracy and aim shake are not changed, so they react faster but don't hit better than Antistasi's rebel training allows. Skills already higher are left alone.
- `auqol_squad_reactionAll` (on) extends it to every friendly AI: garrisons, static and turret gunners at outposts and HQ, and high-command squads. Off: only AI in groups a player leads.
- Each machine checks the friendly AI it runs every 5 seconds (four skill reads per unit, writes only when a value is too low), so newly spawned garrisons get it within 5 seconds. Enemy AI are never changed.
- When your group spots a new enemy, every AI in it gets the sighting at once, instead of waiting for the spoken contact report ("rifleman, 200 metres, front") to reach it through the radio queue. The voice reports still play.
- `auqol_squad_reaction` (on). Turning it off puts back the values AUQOL replaced, also for units that moved between the server and a headless client in the meantime.

## 14. Reveal target key (T) alerts your squad

Press T (the game's Reveal target key, whatever you bound it to) while looking at an enemy.

- Every unit in your group gets full knowledge of that enemy (soldier or vehicle) at once.
- They are told to fire at it when their combat mode allows firing (Fire at will or Engage at will), so Hold fire still holds.
- If you lead the group, that enemy becomes your AI's focus for 30 s. Every second, any AI that turned to another target is put back on it. A new T press always moves the focus to the new enemy; the old one stays known, so they still deal with it afterwards.
- Friendly, civilian, surrendered, empty and dead targets are ignored. `auqol_squad_revealKey` (on).

## 15. Squad switches to launchers at once

An AI in your group with a loaded AT or AA launcher takes it out as soon as an enemy vehicle is both known and shootable.

- Known: the unit knows about it, from its own (faster) spotting, its squad, or your T key.
- Shootable: the unit has a clear line of sight to it, and it is in range: ground vehicles within 500 m for AT, aircraft within 2000 m for AA. Which targets a launcher can hit comes from its ammo's AI usage flags, so RHS and CUP launchers work.
- Checked the moment your group spots a new enemy, when you press T, and every 5 seconds for targets that only become visible later. Units in vehicles, incapacitated units and units already holding the launcher are skipped. Once the target is gone, the AI pick their own weapon again.
- `auqol_squad_launchers` (on).

## 16. Live vehicle markers

Antistasi marks convoy objectives, mission vehicles, supply boxes and enemy vehicles your side has spotted, but moves those markers only once a minute. AUQOL checks them every second and moves a marker whenever its vehicle has moved more than 5 m.

- New markers are picked up from the game's marker-created event, so AUQOL does not search the whole map's markers every second; a full search every 30 seconds catches anything missed.
- Antistasi still decides which markers exist and when they disappear. AUQOL reveals nothing new.
- Player markers already update every second and zone markers change when a zone changes hands, so they are left alone. Intercepted enemy support markers keep Antistasi's 5-second update, because the server owns them.
- `auqol_map_liveVehicles` (on).

## 17. Wounded squad AI treat themselves

AI in your group that get hurt treat themselves without being told.

- Really hurt means it limps and can't run (legs at 0.5 or more), any other body part is at 0.5 or more, or overall damage is above 0.25. Such a unit uses vanilla "Treat yourself" 3 s after being hit, with its first aid kit, or its medikit if it is a medic. Without either it waits for a medic, as before. RHS, CUP and other mods' first aid kits count, since kits are recognised by their item type.
- Lightly hurt means it can run and has at most 0.25 overall damage. That is what Antistasi's revive by a non-medic and a first aid kit leave behind, and what keeps the red hurt icon up. AUQOL clears it without using a kit.
- Left alone: units in vehicles, incapacitated units (Antistasi's revive handles them), units an Antistasi medic is coming to help or that are helping someone, captives and surrendered units.
- Off under ACE medical, which has its own AI self-treatment (ACE's medical AI settings).
- Checked 3 s after a hit, when a recruit joins, and every 15 seconds for damage that came without a hit.
- `auqol_squad_selfTreat` (on).

## Status

Built and statically validated: the config, SQF and every API reference are checked. Sway, recoil, stamina, running, weight, service stock and looting have been reported working in game. Item caches have been reported working too. Crew ejection and Withstand have not been reported yet. Copy from user has been reported working, and squad perks and AI stuck recovery "seem fine". Squad reactions, the T key, squad launchers and live vehicle markers are new in 1.6.0, and faster reactions for all friendly AI in 1.7.0. Self-treatment, the recoil slider, the T key focus and instant contact sharing are new in 1.9.0. None of them is tested in game yet. The in-game test plan is in [docs/testing.md](docs/testing.md).
