# Changelog

Versions are `MAJOR.MINOR.PATCH`, set in `addons/main/script_version.hpp`. A new feature bumps MINOR, a fix bumps PATCH, and a change that breaks existing settings bumps MAJOR.

## 1.32.2

Not tested in game yet. Thomas: his squad sometimes stands still in combat, ignoring new orders.

- Cause (likely): look to spot and the Reveal target focus gave `doFire` to idle AI for enemies up to 1500 m away, re-sent as the group's knowledge faded. A fire order keeps a unit on the spot shooting, so a target it cannot reach planted it, and overwatch, push and release only sent units back with `doFollow` after a move command, never after a fire order. Stuck recovery ignores units in a fight on purpose, so it never saw them.
- Fix 1: look to spot and T focus give `doFire` only for an enemy within 400 m with line of sight (checkVisibility over 0.3); farther away the AI only aim (`doTarget`). Look to spot no longer re-orders a unit that already carries a fire order.
- Fix 2: new `auqol_squad_unpin` (on): a unit of your squad that has held a fire or attack order for 8 s, with you more than 25 m away and no target it can really see (none, over 400 m or checkVisibility under 0.1), is sent back with `doFollow` (`AUQOL_fnc_squadUnpin`, 1 s pass, your machine). Your own orders come later and win. Never for overwatch, breach or push units, units walking to a spot, treating, stopped or in a vehicle.
- Fix 3: `AUQOL_fnc_combatRelease` (used by overwatch, push, smart combat) sends the unit back to formation also when it still carries a fire order.
- Checked against: stuck recovery (unchanged, conservative rules stand), overwatch, breach and push (their units excluded), launchers (gunners with a visible vehicle target pass the sight check), self-treat and medics (treatUntil), ambush hold-fire (combat mode untouched), T focus and look to spot cooldowns, Antistasi and PATCOM (no waypoints or AI-led groups touched).

## 1.32.1

Not tested in game yet. Thomas: Ctrl+S on a ladder did nothing.

- Fix attempt: the ladder slide only looked at objects within 4 m of you and ladder lines within 0.8 m, which misses tall buildings (their position is far from the ladder) and the offset you hang from the rungs. It now looks at objects within 40 m and ladder lines within 2 m. With `auqol_debug` on, the RPT says why it did nothing ("not on a ladder (animation ...)", "no ladder within 2 m found among N objects") or which ladder it used. If it still does nothing, send those lines.
- Checked against: faster ladder climb (config, unchanged), AI animation speed and stuck recovery (unchanged), ACE (no overlap), Ladder Tweak Remastered (same key, use one).

## 1.32.0

Not tested in game yet. Thomas: the squad rarely pushes with him in bigger fights.

- **Push with you** (`auqol_squad_push`, on). In contact on Aware or Combat, when you move toward a known enemy within 300 m (speed over 2 m/s and closing in), your free AI fight as two teams that leapfrog with you: one moves to cover just ahead of you (within 15 m of a point up to 20 m toward the enemy) while the other suppresses where the enemy was last seen (fire chance setting, YELLOW or RED only). They swap when the movers have arrived or after 8 s. Six seconds after you stop pushing they return to formation. Stop for 3 s and overwatch takes over as before.
- Fix: a unit that treated itself or was healed by a medic mid-fight was released without a return to formation and waited where it stopped (audit N1). Treatment now marks it so the release sends it back.
- Docs: look to spot shares with allies at level 4, not 3 (audit N2).
- Checked against: overwatch and breach (units with their orders are never taken, push marks dropped if they take a unit over), orders of yours, treating and stopped units (combatIsEligible), ambush hold-fire and Stealth (push is off on Safe and Stealth), smart combat (player-led groups still skipped), stuck recovery (spot variables), look to spot and T focus (unchanged), launchers, Antistasi and PATCOM (no waypoints, behaviour or leader touched), ACE, RHS, CUP (no class use), dedicated server and HC (player machine only, early exit with no enemy).

## 1.31.2

Not tested in game yet. Thomas: disembark was still one by one.

- AI dismount all at once: the 1.31.0 version used the vanilla get-out action, which the engine queues one unit at a time (same as the get-out order), and it only acted on units without a vehicle assignment, which units given a get-out order still have. Now the others of the group that were told to leave (get-out order or unassigned) are moved out with `moveOut`: instant, no get-out animation. Units marked `incapacitated` by Antistasi are skipped too.
- Checked against: crew ejection (`moveOut` as before, 5 s mark prevents repeats), drivers and gunners who stay (assigned and not ordered out), moving vehicles and aircraft in the air (skipped), ACE captives and unconscious units (skipped), Antistasi QRF unloading, smart combat and stuck recovery (unchanged).

## 1.31.1

The logo shows where Arma uses mod.cpp images, not in the Arma 3 Launcher: `logo` is the main menu icon, `picture` the Expansions menu picture (new `picture.paa`, 2048x1024), `logoSmall` the small icon (now 64 px). The Launcher does not read these for local mods, so its tile stays the default "LOCAL FILE" card. The Launcher's Author field now says TchicX (was "AUQOL Contributors") in `mod.cpp`, `config.cpp` and the HEMTT project. No code change.

## 1.31.0

Not tested in game yet.

- New: AI dismount all at once (`auqol_anim_fastDismount`, on). When AI are told to leave a vehicle, the whole group starts the normal get-out animation together, the way they board, instead of one by one. Drivers or gunners who stay, players, captives, unconscious units, moving vehicles and aircraft in the air are left alone. Test 33.
- Look to spot now acts like the T key: enemies you look at are revealed with full knowledge (level 4, was 3) to your squad and to friendly groups within 300 m, and squad AI that are not shooting at anything yet open fire on the enemy nearest your crosshair at once (combat mode respected). No 30 s focus or notification, those stay T only. Test 24.
- Docs: `docs/testing.md` results table lists every test with its number; tests 8 (squad perks), 12 (live vehicle markers), 13 (1.8.1 fixes), 24 (look to spot) and 28 (ladders) rewritten in plain steps; new test 10b for the 1.8.0 safer stuck recovery and leaner scans. Marked confirmed by Thomas (2026-10-22): T key and nearby allies, contact sharing, faster reactions, launcher switch, faster AI animations.
- Checked against: Antistasi AI and PATCOM (no orders, waypoints or assignments changed; only units the engine or Antistasi already told to leave), crew ejection (`moveOut` already leaves the group; the extra get-out action is a no-op for units already out), smart combat (dismounted groups start their tactics through their own EnemyDetected as before), stuck recovery (units leaving vehicles are already skipped), vehicle freeze (only empty vehicles), ACE captives and unconscious units (skipped), RHS and CUP vehicles (vanilla get-out action, any vehicle class), headless client (each machine handles its own units). Look to spot: Hold fire and Stealth ambush (doFire only under YELLOW or RED), overwatch and breach walks (aim only until arrival), self-treat (skipped while treating), T focus (look to spot only touches AI with no target, so a T focus is never replaced), launchers (rifle for a soldier, as with T).

## 1.30.2

The mod has a logo: a hex nut around a scope bore with an orange cross (service, aim, healing). The launcher shows it in the mod list (`logo.paa` 512 px, `logo_small.paa` 128 px, both from `logo.svg`, original artwork) and the README shows it. No code change.

## 1.30.1

Docs only. Every test in `docs/testing.md` now has Setup, numbered Steps with the exact action and expected result, and a Fail-if line; common setups (enemy squad snippet, settings menu, night, RPT) are listed once at the top of the test plan. No code change.

## 1.30.0

Not tested in game yet. Thomas: smart combat and the squad AI should supplement each other, not overlap, as one "Combat AI" featureset. Review: `/mnt/project-files/reports/auqol-1.30-combat-ai-handoffs.md`.

- One "Combat AI" featureset: the settings menu groups smart combat, squad reactions and squad tactics together ("Combat AI: ..."). Names and defaults are unchanged.
- Fix: a covering unit still walking to its cover got a fire order from smart combat that cancelled the walk. Fire orders now wait until it arrives (or has made no progress for 9 s). The T key focus does the same for units walking to overwatch or breach spots.
- Fix: self-treat and medic treatment drop the unit's old spot, so it picks a new one afterwards instead of counting a failed spot.
- Fix: overwatch and breach units that cannot reach their spot in 15 s are handed back (30 s rest, stuck recovery can see them).
- Fix: ambush discipline came back within a second of your first shot while still in Stealth. It now stays ended until you leave Stealth. Breach also ends it.
- Behaviour modes: overwatch is off on Safe; smart combat groups on Stealth keep quiet (cover and movement only, no suppression, frags, smoke or fire orders) until shot at. Table in FEATURES.md section 29.
- Checked against: every pairing of smart combat, T focus, look to spot and ally sharing, launchers, self-treat and medics, overwatch, breach, ambush, call-outs, light discipline, dodge, stuck recovery and Antistasi's flags (see the report). Player-led groups are still skipped by smart combat; Antistasi PATCOM is never touched.

## 1.29.5

Docs only. `docs/testing.md` is now the complete test list: every feature has a test with what it does and what to look for, the audit's open checks (tests 28 to 31) were moved in from the reports, and the test order is fixed. No code change.

## 1.29.4

Not tested in game yet.

- The "marked for your squad" notification after pressing T now shows in the centre of the screen, at the same height as before, instead of at the right edge. Same look, fade and time as a CBA notification; a new press replaces the old text. Only you see it.

## 1.29.3

Docs only. `docs/testing.md` marks every in-game result and test with ✅ (confirmed working in game) or ❌ (not tested or not confirmed yet). No code change.

## 1.29.2

Not tested in game yet. Second step of the full audit fixes.

- Grenade dodge works across machines: the thrower's machine sends the grenade position to everyone, each machine moves its own AI. On a dedicated server, enemy grenades now make your squad dodge and yours make server AI dodge.
- Vehicle freeze runs on the server and each player machine for the vehicles local to them (the engine flag only acts where it is set).
- Night spotting no longer publishes its saved skills on every change; the old owner publishes them when an AI changes machine, and the new owner waits 2 s before reading them. Less network traffic at night.
- Look to spot checks the view angle before the side lookup (cheaper on big maps).
- Checked against: smart combat and stuck recovery (dodgers still skipped), ACE Advanced Throwing (wait for the grenade to leave the hand kept), hard to locate and reactions (unchanged), headless client moves (night baseline), Antistasi dynamic-simulation props (unchanged), LAMBS and Vcom (dodge still stands down).

## 1.29.1

Not tested in game yet. Fixes from the full audit (`/mnt/project-files/reports/auqol-1.29-full-audit.md`).

- Requires Arma 3 2.14 (config, README): `remoteControlled`, used by smart combat and stuck recovery, is 2.14.
- Ambush hold fire: if you change group while the squad is held, the old group gets its combat mode back.
- Look to spot: the call-out, ally share and log repeat for the same enemy only after 20 s (the reveal itself still refreshes).
- Debug logging: smart combat and overwatch log how many AI can be moved (every 15 s per group), to answer "why did nobody move".
- Docs: stale status and test-run text replaced, ejection table fixed, `mod.cpp` overview shortened.
- Checked against: T key and breach (unchanged, cooldown only on look to spot), ambush and overwatch (same group variable use), smart combat (log only), LAMBS and Vcom (unchanged).

## 1.29.0

Not tested in game yet. Thomas wants ladders to climb as fast as with Ladder Tweak Remastered, which he reports really does.

- Faster ladders again, this time in config: `CfgAnimation >> ladderSpeed` is 1.25 (vanilla 0.5, 2.5 times), the engine's own climb speed, same value that mod uses. No setting; applies to every unit.
- New: *Slide down ladder* key (Ctrl+S, `auqol_anim_ladderSlide`, on), written from scratch; Ladder Tweak Remastered's slide script and animation files are not copied (no reusable licence).
- Checked against: AI animation speed (stacks for AI), stuck recovery (still skips ladders), pistol swap and wake primary (unchanged), ACE fatigue, the real Ladder Tweak loaded too (identical value).

## 1.28.0

Not tested in game yet. Thomas asked for the DEVGRU tactics ideas from the 1.27 review (not casualty drag).

- Radio call-outs, ambush discipline (Stealth = hold fire until you shoot), overwatch when you stop in contact, breach and clear on T at an enemy in a building, and light discipline at night (NV users: weapon lights off, IR on). Five settings, all on, in "Squad tactics".
- Checked against: smart combat (player-led groups still skipped; overwatch reuses its cover search and spot variables), stuck recovery (skips these units), self-treat, launchers, T focus (breach adds orders, focus unchanged), grenade dodge (drops the spot; the unit then rejoins), hard to locate and night spotting (enemy side only), reactions (courage etc. unchanged), Antistasi PATCOM (never involved), ACE medical, LAMBS and Vcom (these only order your own squad, as the player's helper).

## 1.27.1

Thomas tested in game: the ladder animation played faster but the climb itself was slower than vanilla. Nothing else in AUQOL changes the player's speed on a ladder; the engine times each step itself, so a faster animation cannot speed up the climb. The ladder boost is removed.

- Removed: faster ladders, the Fast ladder climbing key, the ladder slide and the settings `auqol_anim_ladder`, `auqol_anim_ladderSpeed`, `auqol_anim_ladderFastSpeed`, `auqol_anim_ladderSlideSpeed` (old saved values are ignored). Ladders are vanilla again.
- Kept: the pistol swap speed-up, the primary weapon after getting up, and AI animation speed (AI ladder use was never changed).
- Checked against: AI animation speed (players still skipped), stuck recovery (still skips ladders), smart combat, ACE Advanced Fatigue exclusion (still used by the pistol swap), wake primary (same handler, unchanged).

## 1.27.0

Not tested in game yet. Thomas asked for an edge-case review of friendly and enemy AI and a DEVGRU feel. Findings: `/mnt/project-files/reports/auqol-1.27-ai-tactics-review.md`.

- Friendly rounds no longer count as a shooter: smart combat's `Suppressed` handler ignored who fired, so a squadmate's burst past a friendly AI could make it suppress his position. Only hostile shooters are answered now.
- Grenade dodge: an AI group's leader who dodged was sent `doFollow` on himself, which could leave a PATCOM leader off his waypoint. He now gets his current waypoint set again (the stuck recovery's refresh).
- Frag safety: a soldier no longer throws a frag when a wall or ceiling is within 4 m in front of him.
- Group medics are marked busy while treating, so smart combat no longer moves the medic away mid-treatment (the patient already was).
- Faster reactions now also raise courage (same floor, same restore), so friendly AI hold the line instead of breaking and fleeing out of formation.
- Look to spot skips captive enemies.
- Checked against: Antistasi PATCOM (waypoints, behaviour, leader orders untouched; only the dodge's waypoint refresh added), stuck recovery (dodgers and treating units still skipped), self-treat, T key and look to spot (knowledge only), hard to locate and night spotting (enemy-only, unchanged), launchers, ACE medical (medic step off as before), LAMBS and Vcom (all still stand down).

## 1.26.0

Not tested in game yet. Thomas wants what he looks at to reach nearby allies, not only his squad, and a hard answer on contact.

- Look to spot now also tells friendly AI groups within 300 m (the same range, 6 group cap and `auqol_combat_shareContacts` switch as the T key and contact reports) about up to three of the enemies it reveals, at reveal level 3 instead of 1.5. Their own smart combat starts from that and fights as before: cover, suppressive fire, target split. Only knowledge is shared, so Antistasi's and PATCOM's orders are untouched.
- No new firepower system: the allies' reaction is the existing fire team and return-fire logic, now triggered sooner.

## 1.25.0

Not tested in game yet. Thomas: after reviving himself the launcher came out, a slow animation that locks movement.

- Getting up from unconscious now brings up your primary weapon, or your handgun if you have none, instead of the launcher (`auqol_player_wakePrimary`, default on). Antistasi's revive and Withstand never pick the launcher; it is the engine's get-up, so this watches your unit's animation state (the existing `AnimStateChanged` handler, no new timer).
- Checked against: Withstand (same revive, nothing else touched), ACE medical (its unconscious states also contain `unconscious`), pistol swap speed (a handgun fallback gets the same boost), AI animation speed (player only), launcher logic and self-treat (AI only, never the player), smart combat and stuck recovery (AI only), hide among the grass (no change to stance), and vehicles (skipped).

## 1.24.0

Not tested in game yet. Thomas: a shot down helicopter or jet that did not explode kept shooting from the ground.

- Downed aircraft: an enemy AI helicopter or plane that is on the ground and cannot fly any more (`canMove` false) or is over 80 % damaged has its enemy AI crew moved out, like immobilized land vehicles, so nobody is left to fire its guns. A falling aircraft is checked every 3 s until it lands (`auqol_eject_aircraft`, default on).
- Checked against: ejection of land vehicles (same code path, same eligibility, same opt-out `auqol_noEject`), Antistasi air support (healthy landed aircraft keep their crew; UAVs skipped), scratch clearing (only below 10 % damage, so it never repairs a downed aircraft), vehicle freezing (only empty parked vehicles), launcher/AA logic (a grounded wreck is out of the fight once crewless), smart combat (ejected crew fight from cover), stuck recovery (not involved: crew leaves on its own), surrendered and captive crew (never ejected).

## 1.23.0

Not tested in game yet. Thomas wants his squad to put out more fire (overwhelming firepower).

- New slider `auqol_combat_fireChance` (default 80 %, was a fixed 35 %): how often each covering AI is ordered to fire every 3 s pass. Covering AI that can see an enemy are now told to fire at it (`doFire`, only if their combat mode allows firing), and those that can't still suppress where it was last seen. Still 100 % while the group is under fire.
- Checked against: Antistasi (waypoints, behaviour and combat mode untouched, still stands down during its kill reaction), launcher gunners and the T focus (skipped when a launcher is out), spread targets (same enemy list), self-treat, stuck recovery and hide among the grass (eligibility check unchanged, firing reveals as before).

## 1.22.0

Not tested in game yet. Thomas asked to spot by looking.

- Look to spot: enemies near the centre of your view that you can see (within 5 degrees, 1500 m, adjustable) are revealed to your squad without pressing T, all of them, and the squad's combat AI picks which to fight. T works as before (`auqol_squad_lookSpot`, `auqol_squad_lookAngle`).

## 1.21.0

Not tested in game yet. Thomas asked for the "AI avoids prone" mod's behavior.

- AI now avoid going prone on every surface, friendly and enemy, Antistasi's included. This is the same one config value the original mod sets (`CfgSurfaces >> Default >> AIAvoidStance = 2`), so it costs nothing at runtime. It is static config, so it has no setting; unload AUQOL to undo it. You can unload the "AI avoids prone" mod.
- `auqol_combat_noProne` is unchanged and still decides whether AUQOL's own suppression reaction may order a unit prone.

## 1.20.5

Not tested in game yet. From Thomas's report of squad AA soldiers not firing at an attacking A-10.

- Squad AA soldiers now take out their launchers against jets. The launcher check ran every 5 seconds and wanted a clear view of more than half the aircraft at that instant, so a jet's attack run was often over before it caught it. While an enemy aircraft is known it now runs every second, and any line of sight to an aircraft is enough.
- A gunner who takes out his launcher is now told to fire as well as aim (not on Hold fire).
- The T key focus no longer pulls a gunner off a vehicle his launcher is on, so an AA soldier stays on the jet when you mark an enemy soldier.
- Enemy parachutes are never launcher targets.
- T no longer needs you exactly on an enemy: with none under the crosshair it takes the visible enemy nearest to where you look, within 15 degrees and 1500 m.
- Pressing T now shows a short notification, only for you, when an enemy was marked for your squad.

## 1.20.4

Not tested in game yet. From Thomas's first timing log (singleplayer, 1.20.3).

- Night spotting was the most expensive AUQOL pass: 1.5 to 3.2 ms on average, up to 7 ms, all in one frame every 5 s. It now does a fifth of the enemy AI every second, so each soldier is still checked every 5 s but no frame carries the whole pass.
- Fixed RPT errors: recruiting an AI (`fn_squadSelfTreat`, "Type Group, expected Object") and pressing the Reveal target key (`fn_squadLaunchers`, "Type Bool, expected Array"). Both functions fell back to the right default, so nothing in game was affected; the log is clean now.
- The startup diagnostics line no longer says AUQOL's hiding stays off when Hide Among The Grass isn't loaded.

## 1.20.3

Docs only, nothing in game changes.

- The README is now a short overview with links. The settings table lives in docs/configuration.md, the compatibility table in docs/compatibility.md, and "How it works" and "Known limitations" moved to FEATURES.md.

## 1.20.2

Not tested in game yet. Optimization only, nothing plays or looks different.

Every feature was reviewed for work it repeats. Most were already event-driven with cached config lookups since 1.10.0. These were left:
- Loot action: whether an object's class gets the action is looked up once per class, not for every object spawned on each client.
- Self-treat and group medics: whether ACE medical is loaded is read once at start, and each item's type (first aid kit, medikit) once per item class, instead of on every hit and pass.

## 1.20.1

Not tested in game yet. Optimization only, nothing plays or looks different.

- Night spotting (server and headless client): the 5 s pass lists every soldier and vehicle once and splits them per side. Each enemy soldier then filters only his own enemies, where before he searched everything within 300 m and checked each of his own friends in script. Whether a side is hostile is also worked out once per pass, not per soldier.
- Hide among the grass: your own concealment state is no longer sent over the network to every other player, since only your machine reads it. Squad AI still send theirs, because they can move to another machine.
- The recurring timers start a fraction of a second apart, so the ones with matching periods (5, 15, 30, 60 s) no longer all run in the same frame.
- The per-shot handler only calls the grenade dodge for throws.

## 1.20.0

Not tested in game yet.

- New: hard to locate at range (`auqol_conceal_locate`, on). Enemies farther away than the distance where a shot gives you away don't learn where you or your squad are from the shot; they have to see you. That distance comes from the gear's own config values: 500 m for an unsuppressed rifle (`auqol_conceal_locateRange`), scaled by the round's loudness and the muzzle device (a suppressor brings it to about 100 to 160 m), muzzle flash in the dark (open muzzle farther, suppressor less; enemies with night vision see it as by day), uniform camouflage (ghillie ×0.6), prone ×0.8, and 25 % more for each further shot from the same spot. Works with AUQOL's hide among the grass and with the Hide Among The Grass mod.
- Hide among the grass: a camouflage uniform now also raises the shots you can fire from one spot before you are revealed (divided by the uniform's camouflage value).
- Smart combat: a soldier a far shooter's round passes close to no longer learns where the shooter is or fires back at him.

## 1.19.0

Not tested in game yet.

- New: hide among the grass (`auqol_conceal_enabled`, on). Lying still or sneaking crouched off roads, with no enemy close, makes you and your squad invisible to enemy AI until you are hit, someone fires close by, or you fire too much. Same rules and timings as the Hide Among The Grass mod's GitHub version (detection distance 10 m, 15 s cooldown, 4 shots, crouching on, grass not required), with HATG's hidden / revealed icon at its place and a Toggle hiding keybind. Switches itself off when the Hide Among The Grass mod is loaded.
- New: partial camouflage (`auqol_conceal_partial`, on). When you can't hide, prone, vegetation and a ghillie suit still make you harder to see.
- Night spotting: noise and lights now have their own switches. Noise (`auqol_night_noise`) is off by default, lights (`auqol_night_lights`) on.

## 1.18.0

Not tested in game yet.

- New: night spotting (`auqol_night_enabled`, on). At night, enemy AI with no night vision or thermal (goggles, helmet visor, weapon sight, or the vehicle's sights) spot you and your squad much later and at shorter range. Darkness comes from the moon height and phase and the cloud cover; on a moonless, overcast night their spot distance and spot time drop to `auqol_night_strength` (25%). Noise still gives you away: they notice you as by day within 20 m prone, 35 m crouched, 50 m walking (`auqol_night_closeRange`), 100 m running, 150 m sprinting and 200 m for a running engine, and 300 m when you are lit by your weapon light, headlights, a street lamp or a flare; gunfire is always heard. Works with any modded gear and vehicles (read from config) and alongside Hide Among The Grass.
- Smart combat cover search skips objects with no positions inside (such as HATG's hiding objects) when it looks for buildings.

## 1.17.0

Not tested in game yet.

- Wounded AI (your squad and AI groups in a fight) no longer treat themselves in the open: when a known enemy can see them they run to the nearest cover within 25 m first, then treat there. Your squad rejoins formation afterwards. Stuck recovery leaves them alone meanwhile. A "Treat yourself" ordered from the command menu is the engine's own and still runs at once.
- Smart combat AI fire back harder when shot at: a suppressed soldier answers at once at where he thinks the shooter is, and for 15 s every covering soldier that can't see the enemy lays suppressive fire each pass (before, about one in three). Part of `auqol_combat_suppressiveFire`.

## 1.16.0

None of it tested in game yet.

- Smart combat AI take cover much more often. Cover spots are now right at the back of the tree, rock or wall (found with a ray), not a few metres off where the enemy could still see them. A soldier with no cover near where the team is heading takes cover near himself, the covering team takes cover at contact instead of standing in the open, and defenders keep their covered spot when the teams swap. Return fire and suppression are unchanged.
- New: clear scratches (`auqol_service_scratches`, on). A vehicle with only light damage (below `auqol_service_scratchLevel`, 0.1) is set back to undamaged, so Repair only shows when something needs fixing.

## 1.15.1

Fixes from checking every feature against every other feature. None of it tested in game yet.

- The T key always shares the enemy with nearby friendly AI groups, even right after an automatic contact report (before, it could be skipped for up to 10 s).
- T key on a soldier: a squad gunner holding his launcher takes his rifle instead of firing a rocket at him.
- A unit treating itself is no longer pulled away by the T key focus, the launcher switch, or smart combat ordering it back into formation mid-treatment.
- Smart combat: a soldier behind outdoor cover no longer stands up for a few seconds when its "get low under fire" timer runs out; it stays crouched and the fire team pass takes the stance over.

## 1.15.0

Launchers stop wasting rounds, plus fixes from an internal review of how the features work together. None of it tested in game yet.

- Launchers: a vehicle that is out of the fight gets no more rounds. That means no living crew, an aircraft that can no longer fly (going down), or a ground vehicle that can neither move nor fire. An immobilized vehicle whose gun still works stays a target. Vehicles another gunner already has under his launcher come last, so two rounds go to two vehicles. 1 s after each launcher round hits, the gunner turns to the next vehicle or puts the launcher away. Works for your squad and for AI groups in a smart combat fight.
- Launchers: an empty launcher counts when the gunner carries another round, so the second AA or AT round is used after he has put the launcher away.
- The T key focus ends when its vehicle is out of the fight.
- Fix: smart combat stopped working for any group with a soldier an Antistasi medic had ever helped (script error on Antistasi's "helped" value, which is a unit, not true/false).
- Fix: magazine sharing could lose the magazine when the receiver had no room left.
- Fix: spreading targets in smart combat could pull an AT gunner off the tank he was aiming at.
- Fix: a soldier treating himself, or being treated by a group medic, could be sent to cover or into a grenade dodge, which cut the treatment short.
- Fix: with ACE Advanced Throwing, AI ran from a player's grenade while it was still being cooked in the hand. The dodge now waits until the grenade is thrown.

## 1.14.0

AI features linked tighter with smart combat. None of it tested in game yet.

- AI groups in a fight now treat themselves with their own first aid kits, by the same rules as your squad (`auqol_squad_selfTreat`). The red-icon clearing stays for your squad only. A medic never heals a mate that is treating itself, and the other way round.
- AI groups use the launcher switch against any known enemy vehicle, so AA gunners now engage aircraft (before, only tanks and APCs triggered it).
- The T key now shares the enemy with nearby friendly AI groups, as the 1.13.0 notes already said.
- Fix: group medics could hit a script error on a mate an Antistasi medic was coming to help.

## 1.13.0

The rest of the four mods' features in AUQOL's own code, and AUQOL's features made aware of each other. None of it tested in game yet.

- New smart combat parts, all on: assault when close and stronger (`auqol_combat_assault`), defend in place (`auqol_combat_defend`), fight armor as a team (`auqol_combat_antiArmor`), spread targets (`auqol_combat_spreadTargets`), contact reports between groups (`auqol_combat_shareContacts`), get away from grenades (`auqol_combat_dodge`), share magazines (`auqol_combat_resupply`), medics treat the wounded (`auqol_combat_medics`).
- Smart combat movers that get stuck on the way to a spot pick a new one after 9 s, and rest with their leader after three failures.
- Ladders: holding the Fast ladder climbing key on the way down now slides you down (`auqol_anim_ladderSlideSpeed`, 4x).
- Pistol swap: the moment the pistol comes up now plays 1.5 times faster again (3x by default), which it didn't before.
- Features working together: stuck recovery never moves units smart combat is moving; AI groups facing armor use the squad launcher switch; your squad's sightings reach nearby friendly AI groups; ejected enemy crew fight from cover at once.

## 1.12.0

Smart combat AI in full, none of it tested in game yet.

- New: squads fight from cover (`auqol_combat_tactics`, on). An AI group in contact fights as two fire teams: one moves to the next covered spot (walls, rocks, trees, sandbags, building positions) while the other covers it, then they swap. Antistasi keeps steering the group: waypoints, behaviour, combat mode, formation, speed and the leader are never touched, and units Antistasi has busy are never moved.
- New: AI use and clear buildings (`auqol_combat_buildings`), flank (`auqol_combat_flank`), lay suppressive fire (`auqol_combat_suppressiveFire`), throw hand grenades at hidden enemies (`auqol_combat_grenades`) and smoke when caught without cover (`auqol_combat_smoke`). All on.
- New: `auqol_combat_noProne` (on): AUQOL never makes AI go prone, for use with no-prone AI mods.
- New: `auqol_combat_range` (500 m), how close a known enemy must be for the tactics to run.
- `auqol_combat_yieldToAIMods` now turns all smart combat AI off while LAMBS Danger or Vcom AI is loaded.

## 1.11.0

New features, none tested in game yet.

- New: faster AI animations (`auqol_anim_ai`, on; `auqol_anim_aiSpeed`, 1.0 to 2.0, default 1.25). Every AI soldier of every faction plays its animations faster, like the Fast Reaction AI (FRAI) mod. Players are never sped up; no FSM or behaviour is changed.
- New: faster pistol swap (`auqol_anim_pistolSwap`, on; speed 2x by default).
- New: faster ladders (`auqol_anim_ladder`, on; 1.5x by default) and a *Fast ladder climbing (hold)* keybind, Left Shift by default, for 2.5x.
- New: smart combat AI. AI that come under close fire make their group aware of the shooter (`auqol_combat_revealShooter`, on), and standing AI crouch or go prone until 10 s after the fire stops (`auqol_combat_takeCover`, on; not in player-led groups). Both stand down when LAMBS Danger or Vcom AI is loaded (`auqol_combat_yieldToAIMods`, on).

## 1.10.0

Performance. None of this has been tested in game yet.

- New: freeze parked empty vehicles (`auqol_freeze_parked`, on) and settled wrecks (`auqol_freeze_wrecks`, on). They stop being simulated while no player is within 500 m and wake when one comes closer, using Arma's dynamic simulation. The server marks them every 30 s. Vehicles with crew, moving, attached, towed, hidden or already frozen by another mod (ACE cargo, Antistasi logistics) are never marked.
- Faster AI reactions are now event-driven: a unit is handled when it spawns, 5 s later, when it changes owner and when it joins a player's group. The full pass over every unit runs once a minute instead of every 5 s.
- Loot and service share one object-spawn handler, and weapon holders (dropped weapons and body gear) skip it.
- Live vehicle markers do their per-second work only while the map or GPS panel is open, every 10 s otherwise, and at once when the map opens.
- The 5 s launcher fallback is skipped while your group knows of no enemy.
- `auqol_debug` now also logs each timer's runs, average and worst time every 5 minutes (`Timing:` lines in the RPT).

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
