# Features

This is what the Antistasi Ultimate QoL Extension (AUQOL) does, and the rules each feature follows. Installation is in [docs/installation.md](docs/installation.md), every setting in [docs/configuration.md](docs/configuration.md) and compatibility in [docs/compatibility.md](docs/compatibility.md).

## Ground rules

- **Standalone addon.** No Antistasi mission files are edited. Everything hooks in from outside, through CBA and engine events.
- **CBA_A3 is the only hard dependency** (`requiredAddons[] = {"cba_main"}`).
- **ACE3, RHS and CUP are optional.** They are detected at runtime, and each feature works with or without them.
- **Compatible by design.** Every change is built to work alongside as many other mods as possible, and must always work with Antistasi Ultimate, RHS, CUP and ACE3.
- **Only verified APIs are used.** Every engine command, CBA function, ACE function and Antistasi global was checked against its source. `tests/static_checks.py` enforces this on every build.
- **Every feature is on by default (recoil at 100%, which is vanilla) except the emergency teleport and the "unit got stuck" messages, and each has its own CBA setting** under *Configure → Configure Addons → Antistasi Ultimate QoL by TchicX* (Esc menu), and can be toggled during a mission.
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
- A unit gets it when it spawns, again 5 seconds later once Antistasi has set its skills, when it moves between the server and a headless client, and when it joins your group. A check once a minute catches anything else. Only values that are too low are written. Enemy AI are never changed.
- When your group spots a new enemy, every AI in it gets the sighting at once, instead of waiting for the spoken contact report ("rifleman, 200 metres, front") to reach it through the radio queue. The voice reports still play.
- `auqol_squad_reaction` (on). Turning it off puts back the values AUQOL replaced, also for units that moved between the server and a headless client in the meantime.

## 14. Reveal target key (T) alerts your squad

Press T (the game's Reveal target key, whatever you bound it to) while looking at an enemy.

- You don't have to be exactly on him (1.20.5): with no enemy under the crosshair, T takes the one nearest to where you look, within 15 degrees and 1500 m, that you can see.

- Every unit in your group gets full knowledge of that enemy (soldier or vehicle) at once.
- They are told to fire at it when their combat mode allows firing (Fire at will or Engage at will), so Hold fire still holds.
- If you lead the group, that enemy becomes your AI's focus for 30 s. Every second, any AI that turned to another target is put back on it. A new T press always moves the focus to the new enemy; the old one stays known, so they still deal with it afterwards.
- A short notification on your screen ("<enemy> marked for your squad") confirms the press worked (1.20.5). Only you see it; nothing is sent over the network.
- Friendly, civilian, surrendered, empty and dead targets are ignored. `auqol_squad_revealKey` (on).

## 15. Squad switches to launchers at once

An AI in your group with an AT or AA launcher and a round for it takes it out as soon as an enemy vehicle is both known and shootable.

- Known: the unit knows about it, from its own (faster) spotting, its squad, or your T key.
- Shootable: the unit has a clear line of sight to it, and it is in range: ground vehicles within 500 m for AT, aircraft within 2000 m for AA. For aircraft any line of sight is enough (1.20.5), so the launcher is out before a jet's attack run is over; enemy parachutes are never targets. Which targets a launcher can hit comes from its ammo's AI usage flags, so RHS and CUP launchers work.
- The AI is told to fire as well as aim, unless your squad is on Hold fire (1.20.5).
- Checked the moment your group spots a new enemy, when you press T, and every 5 seconds for targets that only become visible later, every second while an enemy aircraft is known (1.20.5); the check is skipped while you know of no enemy vehicle. Units in vehicles and incapacitated units are skipped, and a unit already holding the launcher keeps its target while that target is still in the fight. Once the target is gone, the AI pick their own weapon again.
- No wasted rounds (1.15.0): a vehicle that is out of the fight is never picked. That is one with no living crew, an aircraft that can no longer fly (it is going down), or a ground vehicle that can neither move nor fire. An immobilized vehicle whose gun still works is still a target. Vehicles another gunner already has under his launcher come last, so two AA rounds go to two helicopters and two AT rounds to two vehicles.
- 1 second after each launcher round hits, the gunner is checked again: if his vehicle is out of the fight he turns to the next one, or puts the launcher away and the group forgets the wreck. The T key focus also ends when its vehicle is out of the fight.
- `auqol_squad_launchers` (on).

## 16. Live vehicle markers

Antistasi marks convoy objectives, mission vehicles, supply boxes and enemy vehicles your side has spotted, but moves those markers only once a minute. AUQOL checks them every second while your map or GPS is open (every 10 seconds otherwise, and at once when you open the map) and moves a marker whenever its vehicle has moved more than 5 m.

- New markers are picked up from the game's marker-created event, so AUQOL does not search the whole map's markers every second; a full search every 30 seconds catches anything missed.
- Antistasi still decides which markers exist and when they disappear. AUQOL reveals nothing new.
- Player markers already update every second and zone markers change when a zone changes hands, so they are left alone. Intercepted enemy support markers keep Antistasi's 5-second update, because the server owns them.
- `auqol_map_liveVehicles` (on).

## 17. Wounded squad AI treat themselves

AI in your group that get hurt treat themselves without being told. Since 1.14.0, members of AI groups in a fight (smart combat) treat themselves with their own first aid kits by the same rules; the light-damage clearing below stays for your squad only, since it is there for the hurt icon you see. A group medic healing a mate and the mate treating itself never start on each other.

Since 1.17.0, a really hurt unit that a known enemy within 500 m can see first runs to the nearest cover within 25 m (the same cover search smart combat uses, at most 20 s) and treats itself there. Your squad goes back into formation afterwards. With no cover near, or when held in place (Stop, Antistasi garrisons), it treats where it is. Only the automatic self-treatment does this; a "Treat yourself" you order from the command menu is the engine's own and runs at once.

- Really hurt means it limps and can't run (legs at 0.5 or more), any other body part is at 0.5 or more, or overall damage is above 0.25. Such a unit uses vanilla "Treat yourself" 3 s after being hit, with its first aid kit, or its medikit if it is a medic. Without either it waits for a medic, as before. RHS, CUP and other mods' first aid kits count, since kits are recognised by their item type.
- Lightly hurt means it can run and has at most 0.25 overall damage. That is what Antistasi's revive by a non-medic and a first aid kit leave behind, and what keeps the red hurt icon up. AUQOL clears it without using a kit. With `auqol_squad_selfTreatMedikit` (on) this only happens when that AI carries a medikit; turn it off to clear it on every AI.
- Left alone: units in vehicles, incapacitated units (Antistasi's revive handles them), units an Antistasi medic is coming to help or that are helping someone, captives and surrendered units.
- Off under ACE medical, which has its own AI self-treatment (ACE's medical AI settings).
- Checked 3 s after a hit, when a recruit joins, and every 15 seconds for damage that came without a hit.
- `auqol_squad_selfTreat` (on).

## 18. Freeze parked vehicles and settled wrecks

Empty vehicles standing still, and wrecks that have come to rest, stop being simulated while no player is within 500 m. They wake as soon as a player comes closer, so you never see one freeze. This saves CPU on the server, mostly at a busy HQ and after big fights.

- Uses Arma's own dynamic simulation. The server only marks which vehicles may sleep, every 30 seconds.
- Never marked: vehicles with living crew, moving ones, ones in the air, attached, towed or on a rope, static weapons, and anything hidden or already frozen by ACE cargo, Antistasi logistics or another mod.
- Only players wake a frozen vehicle. AI far from every player find it as it was left.
- `auqol_freeze_parked` (on) and `auqol_freeze_wrecks` (on).

## 19. Faster AI animations

Every AI soldier of every faction plays its animations 25% faster by default, adjustable from 1.0 (vanilla) to 2.0. They move, turn, change stance and get through actions sooner, so their next decision comes sooner. This is the idea of the Fast Reaction AI (FRAI) mod, rebuilt in AUQOL.

- No FSM, behaviour or skill is changed, so it sits under any AI mod (LAMBS, Vcom and others) and Antistasi's own AI.
- Players are never sped up.
- Reloading and other upper-body animations can't be sped up this way (engine limit).
- A new value reaches every AI within 15 seconds.
- `auqol_anim_ai` (on), `auqol_anim_aiSpeed` (1.25).

## 20. Faster pistol swap and faster ladders

Switching to or from your handgun plays twice as fast, and the moment the pistol comes up three times as fast. Climbing ladders is 1.5 times as fast. Hold the *Fast ladder climbing* key (Left Shift by default, under Controls > Configure Addons) to climb at 2.5 times, or to slide down at 4 times. All speeds can be set.

- Only your own character. Everyone else sees you at the same speed.
- Works with ACE Advanced Fatigue, which is told to leave the speed alone while the boost lasts.
- `auqol_anim_pistolSwap` (on), `auqol_anim_pistolSwapSpeed` (2), `auqol_anim_ladder` (on), `auqol_anim_ladderSpeed` (1.5), `auqol_anim_ladderFastSpeed` (2.5), `auqol_anim_ladderSlideSpeed` (4).

## 21. Smart combat AI

AI squads fight like a unit using cover, both sides, any faction:
- **Fire teams, cover to cover.** A squad in contact splits into two fire teams. One moves to the next covered spot while the other covers it, then they swap, so the squad advances in bounds instead of walking in the open. Cover is anything solid between the enemy and the soldier: walls, rocks, trees, sandbags, ruins, and building positions.
- **Buildings.** AI fight from inside houses, standing at the windows. An enemy hiding in a building within 80 m is cleared: two soldiers take the rooms nearest to it.
- **Flanking.** In squads of four or more, the second team swings out to one side of the enemy.
- **Suppressive fire.** Covering soldiers who can't see the enemy fire at where it was last seen. While the group is being shot at they do it every pass (about one in three otherwise), and a soldier who is shot at fires back at once at where he thinks the shooter is, to win the firefight.
- **Grenades.** A soldier 12 to 35 m from an enemy he can't see throws a hand grenade, if no friend is near that spot.
- **Smoke.** A soldier caught with no cover near throws smoke toward the enemy first.
- **Assault.** Within 50 m and at least twice the enemy's number, the moving team closes in on it.
- **Defend.** A group that isn't going anywhere (Antistasi defend orders, a hold waypoint, a stopped leader) takes cover around its leader, preferably in buildings, instead of advancing.
- **Armor.** Against a known tank or APC, AT gunners take out their launchers and target it, and everyone else takes cover further away.
- **Target spread.** The covering team splits the known enemies between them.
- **Contact reports.** A sighting by a group, or by your squad, reaches AI groups of the same side within 300 m, so they join the fight.
- **Grenade dodge.** AI within 10 m of a thrown grenade run away from it. With ACE Advanced Throwing, the dodge waits until the grenade has left the thrower's hand, so a cooked grenade does not send everyone away from the player.
- **Ammo sharing.** An AI down to its last magazine gets one from a nearby group mate.
- **Medics.** Once the enemy is more than 60 m away, a group's medic treats wounded mates. Downed soldiers stay with Antistasi's revive, and it's off under ACE medical.
- **Reacting to fire.** When rounds pass close, the group learns where they came from, and standing soldiers crouch (or go prone under heavy fire, unless no-prone is on) until 10 s after the fire stops.

Rules:
- **Antistasi stays in charge of its AI.** Group waypoints, behaviour, combat mode, formation and speed are never touched, and the leader is never moved. Only the members move between cover around where Antistasi sends the group, and they rejoin formation when the fight ends.
- Units Antistasi has busy are never moved: garrisons, statics, vehicles, incapacitated, surrendered, captive, fleeing, healing, rearming, or under one of its own move orders. During Antistasi's reaction to a kill (support call, suppressing fire, smoke charge) no new orders are given.
- Groups led by a player are left to the player.
- **No prone.** On by default, AUQOL never puts AI prone. Stances set by a no-prone mod or by Antistasi are never overridden either way.
- When LAMBS Danger or Vcom AI is loaded everything here stands down, since they run their own combat AI.
- Grenades are found by what their ammo does, so RHS, CUP and any other mod's grenades work.
- Not added: retreat and morale, because Antistasi already decides when its soldiers flee or surrender, and AUQOL taking over would fight it. Investigating heard gunfire, because that means moving the whole group, which is Antistasi's job (its PATCOM already sends groups toward contact).
- Event-driven: a group costs nothing until it detects an enemy or is shot at, and its 3 s pass stops 30 s after the fight.
- `auqol_combat_tactics`, `auqol_combat_buildings`, `auqol_combat_flank`, `auqol_combat_assault`, `auqol_combat_defend`, `auqol_combat_antiArmor`, `auqol_combat_spreadTargets`, `auqol_combat_shareContacts`, `auqol_combat_dodge`, `auqol_combat_resupply`, `auqol_combat_medics`, `auqol_combat_suppressiveFire`, `auqol_combat_grenades`, `auqol_combat_smoke`, `auqol_combat_revealShooter`, `auqol_combat_takeCover`, `auqol_combat_noProne`, `auqol_combat_yieldToAIMods` (all on), `auqol_combat_range` (500 m).

## 22. Clear scratches

A vehicle hit by a bullet or two that broke nothing no longer asks to be repaired. 2 s after the first hit of a burst, if the whole vehicle and every part are below the scratch level, it is set back to undamaged, so Repair (vanilla or ACE) only shows up when there is something to fix.

- Anything at or above the level stays, including the light damage next to it, and is repaired as usual.
- Any vehicle or static weapon from any mod; only damage values are read. Checked where the vehicle is local.
- `auqol_service_scratches` (on) and `auqol_service_scratchLevel` (0.1, from 0.01 to 0.3).

## 23. Night spotting

In the dark, enemy AI without night vision struggle to find you and your squad: you can get much closer before they notice you.

- Who: every AI hostile to your side, on every machine (server, headless client), with no night vision or thermal anywhere: head-mounted slot, helmet with a built-in visor, binoculars, rifle, launcher or pistol sight, or any sight of the vehicle or static weapon they are in. Gear and vehicles come from config, so RHS, CUP, ACE and any other mod's NVGs, thermal sights and vehicles count without a list. Your side's AI are never changed.
- How dark: from the sky, not the clock: sun and moon height, moon phase and cloud cover. A moonless, overcast night is full darkness; a clear full moon night is a bit over halfway back to normal; dusk and dawn fade in and out.
- What changes: only their `spotDistance` and `spotTime` skills, scaled down to `auqol_night_strength` (25%) in full darkness. Accuracy, courage, hearing gunfire, contact reports and all of Antistasi's AI work as before.
- Lights (`auqol_night_lights`, on) and, optionally, noise (`auqol_night_noise`, off) give you away. Inside these distances an enemy spots you as well as by day:

  | You are | Distance (default) |
  | --- | --- |
  | Noise: prone | 0.4 × setting (20 m) |
  | Crouched | 0.7 × (35 m) |
  | Walking upright | 1 × (50 m) |
  | Running (over 9 km/h, any stance) | 2 × (100 m) |
  | Sprinting (over 17 km/h) | 3 × (150 m) |
  | A vehicle with its engine on | 4 × (200 m) |
  | Light: your weapon light or headlights on, a working street lamp within 15 m, or a flare (hand, grenade-launcher or mortar, in the air or on the ground) within 120 m | 6 × (300 m) |

  The setting is `auqol_night_closeRange` (50 m). Firing is always heard, as the engine already does.
- Day: the values AUQOL replaced are put back, also for units that moved between the server and a headless client. If Antistasi or another mod changed the skills meanwhile, their value is kept.
- `auqol_night_enabled` (on), `auqol_night_strength` (25%, 5 to 100), `auqol_night_noise` (off), `auqol_night_lights` (on) and `auqol_night_closeRange` (50 m, 10 to 200). Checked when a unit spawns, changes owner and every 5 s.

## 24. Hide among the grass

The same rules, timings and indicator as the Hide Among The Grass (HATG) mod (its GitHub version), written for AUQOL so you can drop that mod, with partial camouflage on top. When HATG is loaded, AUQOL's version switches itself off and HATG does the job.

- **Hidden** means enemy AI can't see you: your camouflage is set near zero, so it works against every enemy, with or without night vision. It covers you and, with `auqol_conceal_squad`, the AI in your group.
- **You can hide** when you are on foot, on the ground (below 2 m unless under a roof), off roads, not on cooldown, and:
  - prone; or crouched at no more than 5 km/h (`auqol_conceal_crouch`, `auqol_conceal_crouchSpeed`); or standing under a roof;
  - with `auqol_conceal_surfaces` on: in grass or field clutter, next to a bush or under a roof (off by default, as in HATG);
  - no living enemy within the detection distance: 10 m prone (`auqol_conceal_distance`), twice that crouched, four times standing, halved for each of night, rain, fog, a roof and a ghillie suit, at least 5 m.
- **Revealed** for 15 s (`auqol_conceal_cooldown`, not extended by a second hit while it runs) when you are hit, when anyone fires within the detection distance, when you fire a launcher, or when you fire more than your allowed shots from one spot (within 10 m): a random 4 to 8 at the default `auqol_conceal_shots` of 4, plus as many again with a ghillie suit, plus 8 with a suppressor, and half without one, then divided by your uniform's camouflage value (a 0.5 camouflage uniform doubles it). Getting into a vehicle reveals you at once.
- **Partial camouflage** (`auqol_conceal_partial`, on): when you can't hide (enemy close, moving, not on cooldown), your camouflage is still lowered: prone ×0.5, crouched ×0.75, ×0.7 in grass, field clutter or next to a bush (not while running), ×0.6 in a ghillie suit. Gone on cooldown, on roads and in vehicles.
- **Indicator** (`auqol_conceal_hud`, per player): HATG's own hidden, revealed and disabled icons at HATG's place near the bottom centre of the screen, grey while hidden and white otherwise.
- **Hard to locate at range** (`auqol_conceal_locate`, on; also with the HATG mod loaded): an enemy group farther away than the distance where your shot gives you away doesn't learn where you or your squad are from the shot; it has to see you. Unless a soldier of the group saw you around the shot, or another group of its side close enough found you and passes it on by radio, it forgets you 1.5 s after the shot (it still heard the shot). The distance comes from your gear's own config values: 500 m for an unsuppressed rifle (`auqol_conceal_locateRange`), scaled by the round's loudness and your muzzle device (sound carries with the square root of loudness, so a suppressor brings it to about 100 to 160 m), muzzle flash in the dark (an open muzzle is seen 20 % farther on a dark night, a suppressor hides it; enemies with night vision see it as by day), your uniform's camouflage (ghillie ×0.6), prone ×0.8, 25 % more for every further shot from the same spot (up to ×3) and a random ×0.8 to 1.2. A suppressed sniper in a ghillie suit, prone at night, is pinned down by shots alone only within about 50 m for the first shot and about 110 m after five from the same spot; unsuppressed, about 290 m and 580 m (with a typical 0.1 suppressor and the default setting, on a dark night).
- **Toggle hiding** keybind (no default key, set it under Controls > Addon Options): switches hiding off and on for you and your squad, to be seen on purpose.

## 25. AI avoid going prone

- All AI avoid the prone stance, on every surface (`CfgSurfaces >> Default >> AIAvoidStance = 2` in `config.cpp`, the value the "AI avoids prone" mod sets). Applies to friendly, enemy and Antistasi AI alike.
- Static config: nothing runs, no setting. Remove AUQOL to undo it. A surface that sets its own `AIAvoidStance` (some terrain mods) keeps it.
- Orders still win: a stance set with `setUnitPos`, by you in the command menu or by a script can still be prone. `auqol_combat_noProne` (smart combat, on) only decides whether AUQOL's own suppression reaction may give that order; with it off, heavily suppressed AI can still be ordered down by AUQOL.
- Does not touch the player's own stance, hiding among the grass or stuck recovery.

## 26. Look to spot (1.22.0)

Look at enemies and your squad learns about them, without pressing T.

- Twice a second, every living enemy soldier or vehicle you can see within 1500 m and within 5 degrees of the centre of your view (`auqol_squad_lookAngle`, 1 to 15) is revealed to the AI of your group that run on your machine. Every enemy in the cone counts, not just the nearest.
- No focus is set: the squad's smart combat AI (fire team target split, launcher choice) decides which enemy is the bigger threat. T still sets a 30 s focus, so use it when you want them on one target.
- Skips enemies the group already knows at that level, so it does nothing while you keep looking at the same enemy. Nothing is shown and nothing goes over the network. Skipped with the map open or while you are down.
- Needs line of sight (the same visibility check as T). Squads on a headless client (high command) are not told, as with T.
- `auqol_squad_lookSpot` (on).

## Features working together

- Look to spot (26) only reveals, it never sets the 30 s T focus or touches orders, so T focus, smart combat target split, launcher switching, self-treat and stuck recovery work as before; the launcher check simply runs when a new enemy is revealed. Hard to locate and hiding only affect what enemies know about you, not what your squad knows about them.

Every AUQOL feature knows about the others:
- **Stuck recovery and smart combat.** Stuck recovery never moves a soldier that smart combat is moving to cover or away from a grenade. Smart combat has its own stuck handling for its movers: a soldier who makes no progress to its spot for 9 s gets a new one, and the stuck spot is avoided. After three failed spots it rejoins its leader for 30 s, and stuck recovery takes over from there once the fight is over.
- **Squad launchers and smart combat.** AI groups that know about an enemy vehicle use the same launcher switch as your squad: AT against armor and cars, AA against aircraft, with the same no-wasted-rounds rule. Smart combat's armor reaction ignores a tank or APC that is out of the fight. Spreading targets over the covering team never pulls a gunner with his launcher out off his vehicle.
- **Self-treatment and everything else.** A soldier treating himself, or being treated by a group medic, is not sent to cover, does not dodge, is not ordered back into formation, is not switched to his launcher and is not given the T key focus until the treatment is done.
- **T key and launchers.** When you mark a soldier with T, a squad gunner holding his launcher takes his rifle for him, unless his launcher is on a vehicle that is still in the fight: then he keeps it, whatever you mark (1.20.5), so an AA gunner stays on the jet.
- **Taking cover under fire and fire teams.** Both crouch soldiers; when the under-fire crouch ends behind outdoor cover the fire team keeps him crouched, so he never stands up in between.
- **Self-treatment, medics and smart combat.** Your squad treats itself (and gets the red icon cleared); AI groups in a fight treat themselves with the same rules, and their medics heal the worst hurt. A unit that is treating itself is not picked by a medic, and the other way round.
- **Your squad's sightings** and every T key press are shared with friendly AI groups near you through the contact reports. Sightings go out at most once every 10 s per group; a T key press always goes out (1.15.1).
- **Crew ejection and smart combat.** Enemy crew ejected from an immobilized vehicle start fighting from cover at once.
- **Smart combat leaves your squad alone,** so the T key focus, self-treatment, squad perks and launchers keep full control of it.
- **Night spotting and everything else.** Night spotting only lowers enemy spotting skills; faster reactions only raise friendly ones, and a unit that changes side gets its night values back before faster reactions look at it. Contacts shared by smart combat, the T key, the `Suppressed` reveal and gunfire still reach enemy AI at night, so a firefight plays as before: when they are shot at they still return fire and suppress where the shots came from, except from a shooter farther away than his shot gives him away (hard to locate).
- **Hard to locate and everything else.** It only removes what a far shot told an enemy group; their own eyes (with night spotting and hiding) still find you as usual, and a group that found you still shares it with its side by radio and through smart combat. Smart combat's `Suppressed` reveal and fire-back skip a shooter beyond that distance. Player-led groups are never touched. Antistasi's own reaction to a kill (support calls and artillery at the killer's position) is Antistasi's and unchanged.
- **Night spotting and hiding.** They stack: hiding (AUQOL's or HATG's) makes you invisible while you lie still, night spotting makes enemies without night vision worse at finding you when you move. Night also halves the hiding detection distance. Smart combat no longer counts HATG's hiding objects on your squad as buildings when looking for cover.
- **Hiding and your squad features.** Hiding only changes the camouflage trait; squad perks (load), faster reactions, the T key, launchers and self-treat work as before. Your AI firing counts against their own shots, so a squad that opens fire gets revealed like you would.
- **AI animation speed** makes every smart combat move faster too, and ACE medical's reset of a medic is re-applied.

## Less background work (1.10.0)

None of this changes what you see or how things play:
- Loot and service share one handler for new objects, and dropped weapons and body gear (the most common new objects) skip it.
- Faster AI reactions are applied by events instead of a 5-second check of every unit.
- Live vehicle markers do the per-second work only while the map or GPS is open.
- The launcher check only runs while you know of an enemy vehicle (every 5 seconds, every second with an aircraft).
- With `auqol_debug` on, each AUQOL timer's average and worst time is written to the RPT every 5 minutes.
- The timers start a fraction of a second apart, so the ones with matching periods never run in the same frame.

## How it works

- **Ejection** listens to the global `Dammaged`, `Fuel` and `GetIn` events on land vehicles, excluding static weapons, and acts only on the machine where the vehicle is local. That can be the server, a headless client or a player. A vehicle counts as immobilized when `canMove` is false, or, if enabled, when its fuel is exactly 0. Parked or waiting vehicles never qualify. The mod waits until the vehicle is below 3 km/h, then moves each eligible unit out on the machine that owns it, with `unassignVehicle`, `moveOut` and `leaveVehicle`. Nothing is damaged and ownership is unchanged.
- **Service stock** refills only the service cargo (`setFuelCargo`, `setAmmoCargo`, `setRepairCargo`) of objects whose config declares that service. It refills from the vanilla `Service` event while a vehicle is being serviced, and once when the object appears. A fuel truck's own engine fuel is never touched. Under ACE it uses ACE's own APIs instead.
- **Player features** are applied on settings change, on respawn or unit change (and again 3 seconds later, because Antistasi re-applies role traits shortly after respawn without raising an event), on loadout and group changes, and by a 15-second fallback re-check. They only restore values AUQOL itself changed.
- **Loot** adds a copy of the crate's hold action to vehicles and swaps it in on the crate. Completing it asks the server to run Antistasi's own `SCRT_fnc_loot_gatherLoot`, the crate's function, with the AUQOL radius. The server first checks the request: it must come from the machine of the player who held the action, and that player must be alive, on foot and within 10 m of a vehicle or crate that has the action. A second request for the same object within 10 s is refused, so a double send can't empty caches or run the gather twice. The 10-second cooldown, unlocked-item rule and money split are Antistasi's. Enemy item caches within 30 m (the supply crates at outposts, bases and airports) are emptied into a weapon holder first, so the same run picks their contents up, and the empty box is deleted. The enemies-nearby check is done by AUQOL with its own radius, using Antistasi's `A3A_fnc_enemyNearCheck`.
- **Withstand** sets `A3A_selfReviveTimeout`, the cooldown Antistasi's `A3A_fnc_selfRevive` reads, which defaults to 300 s.
- **Squad perks** run in the same player re-check over the AI in your group that are local to your machine. A recruit gets them the moment it joins (the group's `UnitJoined` event), with the 15-second re-check as fallback.
- **AI reactions** run every 5 seconds on every machine (server, headless clients, players) for the friendly AI local to it, and only raise skills that are below the floor, remembering the old values for when the setting is turned off. Those values are a public variable on the unit, so they stay correct when a unit moves between the server and a headless client. **The T key** is the engine's own Reveal target action, caught with `addUserActionEventHandler`. **Launchers** are checked when your group spots a new enemy (the group's `EnemyDetected` event), when you press T, and every 5 seconds as a fallback for targets that only become visible later (every second while an enemy aircraft is known). The T key and launchers only touch AI in your own group that are local to your machine.
- **Live vehicle markers** run every second on each player's machine over the markers already tracked, and only move a marker when its vehicle moved more than 5 m. New markers come from the `MarkerCreated` event, with a full marker scan every 30 seconds as fallback. Antistasi still creates and deletes the markers; AUQOL only moves them to their vehicle.
- **Copy from user** waits for Antistasi's loadout editor to finish opening, then turns the editor's empty third bottom-bar button into "Copy from user". It takes the loadout you wore when you opened the editor, drops anything the arsenal does not have unlimited (weapons stored in the uniform, vest or backpack are checked attachment by attachment and magazine by magazine too), and loads the rest through Antistasi's own "load this role" step, which switches the slot overrides on. Nothing is saved until you press Save.
- **AI stuck recovery** checks every 5 seconds, on each machine, only the AI local to that machine. For the wider scopes it keeps a list of that machine's friendly AI, rebuilt every 30 seconds and pruned on every check, instead of going through every unit each time. A unit is watched only while it has a destination more than 8 m away (25 m in a vehicle) and nothing else to do, and is stuck after the timeout with no progress. Units that are fighting, in COMBAT behaviour, healing, rearming, surrendered or captive, on a static weapon, attached, remote controlled or playing a scripted animation are never moved, and that is checked again right before any hop or teleport. Steps are tried one per timeout window, cheapest first; after the last enabled step the round fails, a cooldown follows, and after the maximum number of rounds the unit is left alone. Tracking is a variable on the unit, so nothing piles up over a long campaign. Details in [section 12](#12-ai-stuck-recovery).
- **No total weight limit** raises the engine's total soldier load cap (`maxSoldierLoad`, vanilla 1000) to 10,000,000 in config. That cap is what stops you adding items once you carry something heavy. Each container's own size is unchanged.

There are no per-frame handlers. The AI animation speed has a 15-second pass on every machine that only writes when a unit's speed is off. The only timers are a 1-second check of tracked live vehicle markers and a 1-second launcher fallback on each player's machine (a cheap check of the player's known vehicles; the launcher pass itself runs every 5 seconds, or every second with an enemy aircraft), the 15-second player fallback re-check, a 5-second AI reaction pass on every machine, the 5-second stuck-AI check, a 10-second garage-fuel check (fuel sources only, writes only when a source is not full), and a 30-second ACE rearm top-up, which runs only in ACE limited-supply mode.

## Known limitations

- Static weapons, aircraft and boats are never ejected. Ejecting from aircraft in flight would kill the crew.
- An overturned vehicle with no damage is left to the engine, which ejects crews from upside-down vehicles on its own.
- ACE rearm's "magazine supply" mode is a stockpile of specific magazines and is not made infinite.
- ACE limited rearm supply is set to 1,000,000 points and topped up every 30 seconds. ACE raises no event when supply is used, so this is effectively infinite rather than literally infinite.
- The total weight limit is a config value, so it applies to every unit, AI included, and has no in-game switch. Script can't change it per unit. See [docs/configuration.md](docs/configuration.md#total-weight-limit).
- Loot and Withstand need Antistasi Ultimate. Withstand also needs the mission's Withstand self-revive parameter turned on.
- The stuck check can't see why the engine's pathfinding failed, only that a unit with a destination made no progress. A unit that is legitimately waiting with a destination set (for example behind a closed gate a player will open) can be nudged. Raise the timeout if that happens.
- The emergency teleport is off by default, infantry only, and only to a leader within the maximum distance. Vehicles are only ever moved by the short hop.
- The T key and the launcher switch only cover AI in your own group. Faster reactions also cover all friendly AI unless `auqol_squad_reactionAll` is off. The only change to enemy AI is night spotting, which lowers two spotting skills and nothing else.
- The T key only alerts the squad about enemies. Your AI then fire under their current combat mode, so Hold fire still holds. Only the group leader's T press makes the AI focus the target, for 30 s or until it dies or you press T on another enemy.
- Self-treatment covers AI in your own group, and members of AI groups while smart combat runs for them, on foot, with a first aid kit (or a medikit for medics) for real wounds. It is off under ACE medical, whose own AI medical handles it.
- SQF scripts run on one thread per machine, so no mod can spread its scripts over CPU cores. AUQOL keeps its work event-driven instead, and the engine already runs AI, physics and rendering on its own threads.
- Freezing parked vehicles and wrecks uses Arma's dynamic simulation. Only players wake a frozen vehicle, so AI more than 500 m from every player find it as it was left. If the mission or another mod already runs dynamic simulation, AUQOL keeps its distances (the default wake distance for empty vehicles is then 250 m instead of 500 m).
- Live vehicle markers only speed up the markers Antistasi already shows. Player markers already update every second, and zone markers change when a zone changes hands. Intercepted enemy support markers keep Antistasi's 5-second update because the server owns them. Nothing new is revealed.
- Antistasi stores no link between a vehicle marker and its vehicle, so AUQOL pairs each marker with the nearest vehicle of the matching kind when it appears. In a tight convoy of same-kind vehicles two markers can still swap; Antistasi's own once-a-minute update then shows the swap and AUQOL re-pairs the marker, so a wrong pairing lasts at most about a minute.
- "Copy from user" keeps only items the arsenal has unlimited. Items with a limited count, and slots holding locked items, are left to Antistasi's random pick, and the chat line lists them.
- Animation speed (`setAnimSpeedCoef`) doesn't change reloading or other upper-body animations; that is an engine limit. Faster AI animations therefore don't speed up AI reloads.
- The pistol swap and ladder boosts recognise animations by their vanilla-style names (a weapon switch with `wpst` on one side, any state with `ladder` in it). Addon animations named differently play at normal speed.
- Smart combat AI moves group members, never the leader, so the group still goes where Antistasi (or the mission) sends it; members fight from cover around that. Cover is judged by a line from where the group believes the enemy is, so cover against a second enemy elsewhere is not guaranteed. It does not retreat or call for help: Antistasi does that.
- Night spotting judges overall darkness from the sky (sun, moon, clouds). Lights count only around you: your weapon light, headlights, a street lamp within 15 m or a flare within 120 m. Fires, burning wrecks and building lights do not. A soldier gets normal spotting back within 5 s of an enemy coming close or lit. Enemy groups still share sightings by radio, so one enemy with night vision who sees you can tell the others.
- Hide among the grass makes enemy AI unable to see you (very low camouflage), as the HATG mod does with its invisible screen. AI that already know where you are keep that knowledge until it fades, and contact reports between enemy groups still pass your last position. Ghillie suits are recognised by "ghillie" in the uniform's class name. A hidden AI that changes owner in multiplayer is only made visible again once it is in that player's squad.
- With infinite stock, selling a fuel or ammo utility item back to the Antistasi garage always refunds its full price, because Antistasi refunds based on the remaining stock.

Troubleshooting is in [docs/installation.md](docs/installation.md#troubleshooting).

## Status

Built and statically validated: the config, SQF and every API reference are checked. Sway, recoil, stamina, running, weight, service stock and looting have been reported working in game. Item caches have been reported working too. Crew ejection and Withstand have not been reported yet. Copy from user has been reported working, and squad perks and AI stuck recovery "seem fine". Squad reactions, the T key, squad launchers and live vehicle markers are new in 1.6.0, and faster reactions for all friendly AI in 1.7.0. Self-treatment, the recoil slider, the T key focus and instant contact sharing are new in 1.9.0. None of them is tested in game yet. Faster AI animations, pistol swap and ladders are new in 1.11.0, the full smart combat AI in 1.12.0, its remaining parts and the cross-feature links in 1.13.0, AI group self-treatment and AA launchers in 1.14.0, the no-wasted-rounds launcher rule in 1.15.0, and the cross-feature fixes in 1.15.1; none of them is tested in game yet. Night spotting is new in 1.18.0, hide among the grass in 1.19.0 and hard to locate at range in 1.20.0; none of them is tested in game yet. The in-game test plan is in [docs/testing.md](docs/testing.md).
