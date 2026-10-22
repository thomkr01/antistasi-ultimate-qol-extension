// Settings and shared state. Runs on every machine before mission objects are initialised.

auqol_ready = false;
auqol_service_cache = createHashMap;
auqol_aceRearmSources = [];
auqol_map_tracked = createHashMap; // Antistasi vehicle marker -> [its vehicle, position AUQOL or Antistasi last gave it]
auqol_launcherFlags = createHashMap; // magazine -> aiAmmoUsageFlags of its ammo
auqol_calloutNext = 0; // time of the next radio call-out
auqol_ambushGroup = grpNull; // the group AUQOL put on Hold fire for the ambush
auqol_launcherNext = 0; // time of the next 5 s launcher fallback pass
auqol_map_ignored = createHashMap; // markers already found not to be Antistasi vehicle markers
auqol_map_pending = createHashMap; // new markers waiting for their text -> time first seen
auqol_map_nextScan = 0;
auqol_stuck_units = []; // friendly AI local to this machine, for the wider stuck scopes
auqol_stuck_nextScan = 0;
auqol_stuck_listScope = -1;
auqol_garage_full = createHashMap; // vehicle class -> full garage fuel value (0: not a fuel source)
auqol_map_nextIdle = 0; // next marker pass while the map and GPS panel are closed
auqol_freeze_marked = []; // vehicles AUQOL marked for dynamic simulation
auqol_freeze_ownsSystem = false; // AUQOL switched the engine's dynamic simulation on
auqol_perf_stats = createHashMap; // timer name -> [total ms, runs, worst ms], debug logging only
auqol_perf_nextReport = 0;
auqol_conceal_hatg = isClass (configFile >> "CfgPatches" >> "hatg_core"); // Hide Among The Grass loaded: AUQOL concealment stays off
auqol_conceal_hidden = []; // units this machine has hidden
auqol_conceal_off = false; // the local player switched concealment off for their squad with the toggle key
auqol_conceal_surfaceCache = createHashMap; // surface class -> has ground clutter
auqol_conceal_ghillieCache = createHashMap; // uniform class -> is a ghillie suit
auqol_conceal_camoCache = createHashMap; // uniform class -> camouflage multiplier (AUQOL_fnc_concealCamo)
auqol_night_slice = 0; // which fifth of the units the 1 s night spotting pass checks
auqol_night_visionCache = createHashMap; // "CfgWeapons>class" or "CfgVehicles>class" -> has night vision or thermal
// LAMBS Danger and Vcom AI react to suppression themselves (auqol_combat_yieldToAIMods).
auqol_combat_throwables = createHashMap; // magazine -> [Throw muzzle, "frag" / "smoke" / ""]
auqol_aceMedical = isClass (configFile >> "CfgPatches" >> "ace_medical_engine"); // ACE medical loaded: self-treat and group medics stay off
auqol_itemTypeCache = createHashMap; // item class -> CfgWeapons ItemInfo type (401 first aid kit, 619 medikit)
auqol_loot_vehicleCache = createHashMap; // object class -> gets the loot action as a vehicle
auqol_combat_ammoSim = createHashMap; // ammo class -> lowercase simulation, for the grenade dodge
auqol_combat_aiModLoaded = isClass (configFile >> "CfgPatches" >> "lambs_danger") || {isClass (configFile >> "CfgPatches" >> "VCOM_AI")};

private _category = "Antistasi Ultimate QoL by TchicX";

// --- Crew ejection (evaluated where each vehicle is local, so the server value is forced on everyone)
[
    "auqol_eject_enabled", "CHECKBOX",
    ["Eject enemy crew from immobilized vehicles", "When an enemy AI land vehicle can no longer move (engine, wheels or tracks destroyed), its living enemy AI occupants are moved out. Players, friendly AI, captives and surrendered units are never ejected."],
    [_category, "Enemy crew ejection"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_eject_outOfFuel", "CHECKBOX",
    ["Also treat an empty fuel tank as immobilized", "canMove does not consider fuel for land vehicles. When enabled, an enemy land vehicle with exactly zero fuel also counts as immobilized."],
    [_category, "Enemy crew ejection"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_eject_aircraft", "CHECKBOX",
    ["Eject enemy crew from downed aircraft", "When an enemy AI helicopter or plane has crashed or landed on the ground and cannot fly any more (or is over 80% damaged), its living enemy AI occupants are moved out, so a shot down aircraft stops firing from the ground."],
    [_category, "Enemy crew ejection"],
    true, 1
] call CBA_fnc_addSetting;

// --- Service stock (applied where each service object is local, and on the server for ACE and the Antistasi garage)
// Setting scripts also fire for the initial value, before AUQOL_fnc_settingsInitialized has run; auqol_ready skips that call.
private _serviceChanged = { if (auqol_ready) then { call AUQOL_fnc_serviceApplyAll } };

[
    "auqol_service_fuel", "CHECKBOX",
    ["Infinite fuel-service stock", "Fuel trucks and other recognized fuel sources never run out of the fuel they hand out (vanilla fuel cargo, or ACE refuel infinite-source mode). Their own engine fuel is not touched."],
    [_category, "Service vehicles"],
    true, 1, _serviceChanged
] call CBA_fnc_addSetting;

[
    "auqol_service_ammo", "CHECKBOX",
    ["Infinite ammunition-service stock", "Ammo trucks and other recognized rearm sources never run out (vanilla ammo cargo, or ACE rearm when it runs in 'limited' supply mode). ACE 'unlimited' mode is already infinite and is left alone."],
    [_category, "Service vehicles"],
    true, 1, _serviceChanged
] call CBA_fnc_addSetting;

[
    "auqol_service_repair", "CHECKBOX",
    ["Infinite repair-service stock", "Repair trucks and other recognized repair sources never run out of vanilla repair cargo. ACE repair has no depleting stock, so nothing changes when ACE repair is enabled."],
    [_category, "Service vehicles"],
    true, 1, _serviceChanged
] call CBA_fnc_addSetting;

[
    "auqol_service_garageFuel", "CHECKBOX",
    ["Infinite Antistasi garage fuel sources", "Antistasi's garage refuels vehicles you pull out from the fuel stored in garaged fuel trucks, and that stored fuel runs out. When enabled, garaged fuel sources are kept full. Requires the fuel-service setting."],
    [_category, "Service vehicles"],
    true, 1
] call CBA_fnc_addSetting;

// --- Vehicle damage (checked where each vehicle is local)
[
    "auqol_service_scratches", "CHECKBOX",
    ["Clear scratches", "A vehicle with only light damage (a bullet or two, nothing broken) is set back to undamaged 2 s after the hit, so Repair only shows up when something needs fixing. Works with vanilla and ACE repair."],
    [_category, "Vehicle damage"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_service_scratchLevel", "SLIDER",
    ["Scratch level", "Damage below this, on the whole vehicle and on every part (0 = intact, 1 = destroyed), counts as a scratch and is cleared. Anything at or above it stays and can be repaired as usual."],
    [_category, "Vehicle damage"],
    [0.01, 0.3, 0.1, 2], 1
] call CBA_fnc_addSetting;

// --- Local player (server-forced, applied on each player's own machine)
private _playerChanged = { if (auqol_ready) then { call AUQOL_fnc_playerApply } };

[
    "auqol_player_noSway", "CHECKBOX",
    ["No weapon sway", "Removes weapon sway for your own character (setCustomAimCoef 0, or an ACE sway factor of 0 when ACE sway is active)."],
    [_category, "Player"],
    true, 1, _playerChanged
] call CBA_fnc_addSetting;

[
    "auqol_player_unlimitedStamina", "CHECKBOX",
    ["Unlimited stamina", "Disables the vanilla stamina system for your own character, or zeroes ACE Advanced Fatigue exertion when that is active. AI stamina is not changed."],
    [_category, "Player"],
    true, 1, _playerChanged
] call CBA_fnc_addSetting;

[
    "auqol_player_weightless", "CHECKBOX",
    ["Running unaffected by carried weight", "Sets your character's loadCoef trait to 0 so equipment weight no longer drains or reserves stamina, and removes carried mass from ACE Advanced Fatigue. Other movement mechanics are unchanged."],
    [_category, "Player"],
    true, 1, _playerChanged
] call CBA_fnc_addSetting;

[
    "auqol_player_recoil", "SLIDER",
    ["Recoil", "How much weapon recoil your own character has, 0 to 100%. 100% is vanilla and leaves recoil alone; 0% is no recoil (setUnitRecoilCoefficient). AI outside your squad is not changed."],
    [_category, "Player"],
    [0, 1, 1, 0, true], 1, _playerChanged
] call CBA_fnc_addSetting;

[
    "auqol_player_squad", "CHECKBOX",
    ["Apply to AI in your squad", "The no sway, unlimited stamina, weightless running and recoil settings above also apply to the AI in your own group (the ones local to your machine). Under ACE the AI get the vanilla versions, since ACE sway and fatigue only run for players."],
    [_category, "Player"],
    true, 1, _playerChanged
] call CBA_fnc_addSetting;

// --- Squad reactions (applied on each player's machine to the AI in their group)
private _squadChanged = { if (auqol_ready) then { [] call AUQOL_fnc_squadReactApply } };

[
    "auqol_squad_reaction", "CHECKBOX",
    ["Faster squad reactions", "The AI in groups led by a player spot enemies sooner, pass sightings to each other faster and turn onto targets quicker: their spot time, spot distance, aiming speed, commanding and courage (they hold the line instead of breaking and fleeing) skills are raised to at least the value below. Accuracy is not changed."],
    [_category, "Combat AI: squad reactions"],
    true, 1, _squadChanged
] call CBA_fnc_addSetting;

[
    "auqol_squad_reactionSkill", "SLIDER",
    ["Minimum reaction skill", "The floor for those five skills, 0.3 to 1. Skills already higher are left alone. Antistasi recruits start around 0.2 to 0.4."],
    [_category, "Combat AI: squad reactions"],
    [0.3, 1, 0.8, 2], 1, _squadChanged
] call CBA_fnc_addSetting;

[
    "auqol_squad_reactionAll", "CHECKBOX",
    ["Also for all friendly AI", "The faster reactions above also apply to every friendly AI, not just your squad: garrisons, static and turret gunners at outposts and HQ, and high-command squads. Applied where each AI runs (server, headless client or player) when it spawns, and checked again every minute."],
    [_category, "Combat AI: squad reactions"],
    true, 1, _squadChanged
] call CBA_fnc_addSetting;

[
    "auqol_squad_revealKey", "CHECKBOX",
    ["Reveal target key alerts your squad", "Pressing Reveal target (T by default) while looking at an enemy gives every unit in your group full knowledge of it. If you lead the group it becomes your AI's focus for 30 s: they target it at once, and each new press moves the focus to the new enemy while the old one stays known. They fire under their current combat mode, so Hold fire still holds."],
    [_category, "Combat AI: squad reactions"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_squad_lookSpot", "CHECKBOX",
    ["Look to spot for your squad", "Enemies you can see near where you look (within the angle below of your crosshair, up to 1500 m) are revealed to your squad without pressing anything. Every such enemy counts, and the squad's own combat AI picks which to fight first. No focus is set, unlike the Reveal target key, which still works."],
    [_category, "Combat AI: squad reactions"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_squad_lookAngle", "SLIDER",
    ["Look to spot angle (degrees)", "How close to the centre of your view an enemy must be to be spotted, 1 to 15 degrees. About 5 is a hand's width around the crosshair on a normal screen."],
    [_category, "Combat AI: squad reactions"],
    [1, 15, 5, 0], 1
] call CBA_fnc_addSetting;

[
    "auqol_squad_selfTreat", "CHECKBOX",
    ["Wounded squad AI treat themselves", "AI in your group that are hurt (limping, can't run) use their first aid kit on themselves at once, a few seconds after being hit. Light leftover damage that only keeps the red hurt icon up (for example after Antistasi's revive) is cleared without using a kit. Off under ACE medical, which has its own AI medical."],
    [_category, "Combat AI: squad reactions"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_squad_selfTreatMedikit", "CHECKBOX",
    ["Require medikit to clear the hurt icon", "On: light leftover damage (the red hurt icon, for example after a revive by a non-medic) is only cleared on AI that carry a medikit. Off: it is cleared on every AI. Treating real wounds with a first aid kit is not affected."],
    [_category, "Combat AI: squad reactions"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_squad_launchers", "CHECKBOX",
    ["Squad switches to launchers at once", "An AI in your group with a loaded AT or AA launcher takes it out as soon as it knows about an enemy vehicle it can see and hit: ground vehicles within 500 m for AT, aircraft within 2000 m for AA. Knowing comes from its own spotting, the squad, or your Reveal target key."],
    [_category, "Combat AI: squad reactions"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_squad_callouts", "CHECKBOX",
    ["Radio call-outs", "When the Reveal target key or look to spot shows your squad an enemy, one of your AI calls it out in group chat: type, clock position and distance."],
    [_category, "Combat AI: squad tactics"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_squad_ambush", "CHECKBOX",
    ["Ambush discipline", "While you lead your group in Stealth behaviour, your squad is put on Hold fire so nobody gives the position away. The first shot you fire, leaving Stealth or setting a combat mode yourself ends it, and the squad opens up together."],
    [_category, "Combat AI: squad tactics"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_squad_overwatch", "CHECKBOX",
    ["Overwatch when you stop", "With an enemy known within 300 m and you standing still for 3 s, your free AI take the nearest cover within 15 m and cover you. They return to formation when you move again or the enemy is gone. AI you ordered yourself are left alone."],
    [_category, "Combat AI: squad tactics"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_squad_breach", "CHECKBOX",
    ["Breach and clear (Reveal target key)", "Pressing Reveal target on an enemy soldier inside a building within 150 m sends the two free AI nearest to the building in together, to the positions nearest him, for 30 s."],
    [_category, "Combat AI: squad tactics"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_squad_nvDiscipline", "CHECKBOX",
    ["Light discipline at night", "At night, friendly AI with night vision or thermal keep their weapon lights off and use IR lasers, so only enemies with night vision can see them. AI without night vision are left alone."],
    [_category, "Combat AI: squad tactics"],
    true, 1
] call CBA_fnc_addSetting;

// --- AI animation speed (setAnimSpeedCoef only acts where it runs, so every machine applies it to every AI)
private _animChanged = { if (auqol_ready) then { [] call AUQOL_fnc_animAiApply } };

[
    "auqol_anim_ai", "CHECKBOX",
    ["Faster AI animations", "Every AI soldier of every faction plays its animations faster (the speed below): moving, turning, changing stance and getting through actions, so its next decision comes sooner. No AI behaviour or FSM is changed. Players are never sped up. Reloading and other upper-body animations are not affected by the engine."],
    [_category, "AI animation speed"],
    true, 1, _animChanged
] call CBA_fnc_addSetting;

[
    "auqol_anim_aiSpeed", "SLIDER",
    ["AI animation speed", "1.0 is vanilla, 2.0 is twice as fast. Takes up to 15 s to reach every AI after a change."],
    [_category, "AI animation speed"],
    [1, 2, 1.25, 2], 1, _animChanged
] call CBA_fnc_addSetting;

// --- Player animations (local player only; the speed is sent to every machine while it lasts)
[
    "auqol_anim_pistolSwap", "CHECKBOX",
    ["Faster pistol swap", "Switching to or from your handgun plays faster, at the speed below, and the moment the pistol comes up 1.5 times faster again. Other animations are not changed."],
    [_category, "Player animations"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_anim_pistolSwapSpeed", "SLIDER",
    ["Pistol swap speed", "1.0 is vanilla, 3.0 is three times as fast."],
    [_category, "Player animations"],
    [1, 3, 2, 2], 1
] call CBA_fnc_addSetting;

[
    "auqol_anim_ladderSlide", "CHECKBOX",
    ["Ladder slide down", "While on a ladder, the Slide down ladder key (Ctrl+S by default, in Controls > Configure Addons) lets you slide to the foot of the ladder."],
    [_category, "Player animations"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_player_wakePrimary", "CHECKBOX",
    ["Primary weapon after getting up", "After you get up from unconscious (Antistasi revive or Withstand, ACE), your primary weapon (else your handgun) comes up instead of the engine's slow launcher animation."],
    [_category, "Player animations"],
    true, 1
] call CBA_fnc_addSetting;

// --- Smart combat AI (runs where each AI group is local, from its EnemyDetected and Suppressed events)
[
    "auqol_combat_tactics", "CHECKBOX",
    ["Squads fight from cover", "AI groups in contact fight as two fire teams: one moves to the next covered spot (behind walls, rocks, trees, or inside buildings) while the other covers it, then they swap. Antistasi keeps steering the group; only members move between cover, and they rejoin formation when the fight ends. Not for groups led by a player."],
    [_category, "Combat AI: smart combat"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_combat_buildings", "CHECKBOX",
    ["Use and clear buildings", "Building positions count as cover, so AI fight from inside houses, and an enemy inside a building within 80 m is cleared: up to two movers take the positions nearest to it."],
    [_category, "Combat AI: smart combat"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_combat_flank", "CHECKBOX",
    ["Flank", "In groups of four or more, the second fire team advances on a line swung out to one side of the enemy instead of straight at it."],
    [_category, "Combat AI: smart combat"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_combat_suppressiveFire", "CHECKBOX",
    ["Suppressive fire", "Covering AI that can't see the enemy fire at where it was last seen, to keep its head down while their team moves."],
    [_category, "Combat AI: smart combat"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_combat_fireChance", "SLIDER",
    ["Covering fire chance (%)", "How often, every 3 s, each covering AI is ordered to fire: at an enemy it sees, or (with Suppressive fire) at where it was last seen. 100 % is every pass; every pass anyway while the group is under fire. 0 to 100."],
    [_category, "Combat AI: smart combat"],
    [0, 100, 80, 0], 1
] call CBA_fnc_addSetting;

[
    "auqol_combat_grenades", "CHECKBOX",
    ["Hand grenades at hidden enemies", "An AI 12 to 35 m from an enemy it can't see (behind cover or inside a building) throws a hand grenade at it, if it has one and no friend is near that spot. At most once every 40 s per AI."],
    [_category, "Combat AI: smart combat"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_combat_smoke", "CHECKBOX",
    ["Smoke when there is no cover", "An AI that has to move with no cover near and the enemy within 200 m throws a smoke grenade toward it first. At most once a minute per group."],
    [_category, "Combat AI: smart combat"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_combat_assault", "CHECKBOX",
    ["Assault when close and stronger", "With the enemy within 50 m and at least twice its number, the moving team closes in on its position instead of stopping at cover."],
    [_category, "Combat AI: smart combat"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_combat_defend", "CHECKBOX",
    ["Defend in place", "A group that isn't going anywhere (Antistasi defend orders, a hold, guard or sentry waypoint, no waypoint left, or a stopped leader) takes cover within 30 m of its leader instead of advancing, preferring building positions."],
    [_category, "Combat AI: smart combat"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_combat_antiArmor", "CHECKBOX",
    ["Fight armor as a team", "With an enemy tank or APC known within 400 m, AI with AT launchers take them out and target it at once, and the others take cover further away from it."],
    [_category, "Combat AI: smart combat"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_combat_spreadTargets", "CHECKBOX",
    ["Spread targets", "With several enemies known, the covering team splits them up: one enemy each, in turn, instead of everyone on the same one."],
    [_category, "Combat AI: smart combat"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_combat_shareContacts", "CHECKBOX",
    ["Contact reports between groups", "When a group (or your squad) spots an enemy, AI groups of the same side within 300 m learn about it too and join the fight. Only knowledge is shared; where they go stays with Antistasi or the mission."],
    [_category, "Combat AI: smart combat"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_combat_dodge", "CHECKBOX",
    ["Get away from grenades", "AI within 10 m of a thrown hand grenade run 12 m away from it, then rejoin their group."],
    [_category, "Combat AI: smart combat"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_combat_resupply", "CHECKBOX",
    ["Share magazines", "In a fight, an AI down to its last magazine gets one from a group mate within 15 m who has four or more that fit its weapon."],
    [_category, "Combat AI: smart combat"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_combat_medics", "CHECKBOX",
    ["Medics treat the wounded", "While no enemy is within 60 m, a group's medic treats the most hurt mate within 30 m who is wounded but not down. Downed units stay with Antistasi's revive. Off under ACE medical."],
    [_category, "Combat AI: smart combat"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_combat_range", "SLIDER",
    ["Contact range (m)", "Tactics run while the group knows of an enemy within this distance, 100 to 1000 m, and stop 30 s after the last one."],
    [_category, "Combat AI: smart combat"],
    [100, 1000, 500, 0], 1
] call CBA_fnc_addSetting;

[
    "auqol_combat_noProne", "CHECKBOX",
    ["Never make AI go prone", "AUQOL's own suppression reaction stops at crouching. AI already avoid prone through the mod's config. Stance orders from you, Antistasi or other mods are never overridden either way."],
    [_category, "Combat AI: smart combat"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_combat_revealShooter", "CHECKBOX",
    ["AI under fire learn where it comes from", "When rounds pass close to an AI, its group gets to know the shooter, so it answers the fire instead of scanning for it. Applies to every AI, both sides."],
    [_category, "Combat AI: smart combat"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_combat_takeCover", "CHECKBOX",
    ["Suppressed AI get low", "A standing AI on foot crouches when rounds pass close, or goes prone under heavy fire (unless 'Never make AI go prone' is on), and goes back to its own stance choice 10 s after the last close round. Only AI whose stance is left to the AI are touched; AI in a group led by a player are skipped."],
    [_category, "Combat AI: smart combat"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_combat_yieldToAIMods", "CHECKBOX",
    ["Leave combat AI to LAMBS or Vcom", "When LAMBS Danger or Vcom AI is loaded, every smart combat AI setting above stays off, since those mods already run their own combat AI."],
    [_category, "Combat AI: smart combat"],
    true, 1
] call CBA_fnc_addSetting;

// --- Performance (server: the engine's dynamic simulation is decided there)
[
    "auqol_freeze_parked", "CHECKBOX",
    ["Freeze parked empty vehicles", "Empty vehicles that stand still stop being simulated while no player is within 500 m, and wake as soon as one comes closer (Arma's dynamic simulation). Saves CPU at a busy HQ. Vehicles that are attached, towed, hidden or already frozen by another mod are left alone."],
    [_category, "Performance"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_freeze_wrecks", "CHECKBOX",
    ["Freeze settled wrecks", "Destroyed vehicles that have come to rest stop being simulated while no player is within 500 m, and wake as soon as one comes closer. Antistasi's garbage clean still removes them as before."],
    [_category, "Performance"],
    true, 1
] call CBA_fnc_addSetting;

// --- Map (client only, server-forced like the rest)
[
    "auqol_map_liveVehicles", "CHECKBOX",
    ["Live vehicle markers", "Markers Antistasi puts on convoy objectives, mission vehicles, supply boxes and spotted enemy vehicles follow their vehicle every second instead of jumping once a minute."],
    [_category, "Map"],
    true, 1
] call CBA_fnc_addSetting;

// --- Antistasi rebel loadout editor (client UI, server-forced like the rest)
[
    "auqol_loadout_copyFromUser", "CHECKBOX",
    ["'Copy from user' button in the rebel loadout editor", "Adds a 'Copy from user' button to the bottom bar of Antistasi's Set Rebel Loadout arsenal. It loads your own loadout into the role being edited, keeping only unlocked items. Press Save afterwards to keep it."],
    [_category, "Rebel loadouts"],
    true, 1
] call CBA_fnc_addSetting;

// --- AI stuck detection and recovery (runs on whichever machine owns each AI)
[
    "auqol_stuck_enabled", "CHECKBOX",
    ["Detect and recover stuck friendly AI", "Watches friendly AI that have somewhere to go but make no progress, then tries to free them: refresh the move order, rejoin formation, a short safe hop, and (if enabled) a teleport to the squad leader."],
    [_category, "AI stuck recovery"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_stuck_scope", "LIST",
    ["Which AI to watch", "Your squad: AI in each player's own group. Near players: friendly AI within the radius below of any player. All: every friendly AI (checked where each AI is local, every 5 s)."],
    [_category, "AI stuck recovery"],
    [[0, 1, 2], ["Your squad", "Friendly AI near players", "All friendly AI"], 0], 1
] call CBA_fnc_addSetting;

[
    "auqol_stuck_scopeRadius", "SLIDER",
    ["Radius for 'near players' (m)", "Only used by the 'Friendly AI near players' scope, 50 to 3000 m."],
    [_category, "AI stuck recovery"],
    [50, 3000, 500, 0], 1
] call CBA_fnc_addSetting;

[
    "auqol_stuck_timeout", "SLIDER",
    ["Stuck after (s)", "How long a unit with somewhere to go may make no progress before it counts as stuck, 10 to 300 s. Also the time each recovery step gets to work."],
    [_category, "AI stuck recovery"],
    [10, 300, 30, 0], 1
] call CBA_fnc_addSetting;

[
    "auqol_stuck_minProgress", "SLIDER",
    ["Minimum progress (m)", "Getting this much closer to its destination, or moving this far, within the time above counts as progress, 0.5 to 20 m. Moving stops counting once the unit has not got any closer for three times the time above (circling, back and forth)."],
    [_category, "AI stuck recovery"],
    [0.5, 20, 3, 1], 1
] call CBA_fnc_addSetting;

[
    "auqol_stuck_refreshOrders", "CHECKBOX",
    ["Step 1: refresh the move order", "Re-issues the unit's current order to the same destination: the same move position, the same waypoint, or follow the leader."],
    [_category, "AI stuck recovery"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_stuck_regroup", "CHECKBOX",
    ["Step 2: rejoin formation", "For units following their leader in formation: clears stuck targets and orders, then tells them to follow the leader again. Units with an explicit move order or a hold order are skipped."],
    [_category, "AI stuck recovery"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_stuck_reposition", "CHECKBOX",
    ["Step 3: short safe hop", "Moves the unit (or the vehicle it drives) a few metres toward where it is going, onto a checked spot: dry, not steep, not under a roof, clear of objects and with no enemies within 100 m."],
    [_category, "AI stuck recovery"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_stuck_teleport", "CHECKBOX",
    ["Step 4: emergency teleport to the squad leader", "Last resort for infantry: moves the unit to a checked spot next to its squad leader, if the leader is within the maximum distance below. Never players, vehicles, or units parachuting, swimming or climbing."],
    [_category, "AI stuck recovery"],
    false, 1
] call CBA_fnc_addSetting;

[
    "auqol_stuck_maxDistance", "SLIDER",
    ["Maximum hop / teleport distance (m)", "The safe hop goes at most 10 m (25 m for vehicles) and never further than this. The teleport is only used when the leader is within this distance, 5 to 500 m."],
    [_category, "AI stuck recovery"],
    [5, 500, 100, 0], 1
] call CBA_fnc_addSetting;

[
    "auqol_stuck_cooldown", "SLIDER",
    ["Cooldown after a failed recovery (s)", "When every enabled step has been tried and the unit is still stuck, wait this long before starting again, 10 to 600 s."],
    [_category, "AI stuck recovery"],
    [10, 600, 60, 0], 1
] call CBA_fnc_addSetting;

[
    "auqol_stuck_maxAttempts", "SLIDER",
    ["Maximum recovery rounds", "After this many failed rounds the unit is left alone until it moves again by itself, 1 to 10."],
    [_category, "AI stuck recovery"],
    [1, 10, 3, 0], 1
] call CBA_fnc_addSetting;

[
    "auqol_stuck_notifyDetect", "CHECKBOX",
    ["Message when a unit gets stuck", "System chat line naming the unit, why it seems stuck and which step is being tried. Shown to the player leading its group."],
    [_category, "AI stuck recovery"],
    false, 1
] call CBA_fnc_addSetting;

[
    "auqol_stuck_notifyResult", "CHECKBOX",
    ["Message when recovery works or fails", "System chat line when a stuck unit moves again, and when a recovery round fails. Shown to the player leading its group."],
    [_category, "AI stuck recovery"],
    true, 1
] call CBA_fnc_addSetting;

// --- Loot gathering (Antistasi Ultimate). The server picks the radius, so both are server-forced.
[
    "auqol_loot_enabled", "CHECKBOX",
    ["Gather loot from vehicles", "Adds the loot crate's 'Gather Scattered Loot' action to every vehicle, and makes the vehicle and the loot crate use the radius below. Off: vehicles lose the action and the crate goes back to Antistasi's own radius."],
    [_category, "Loot gathering"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_loot_radius", "SLIDER",
    ["Loot gather radius (m)", "How far around the vehicle or loot crate loot is gathered from, 10 to 2000 m."],
    [_category, "Loot gathering"],
    [10, 2000, 2000, 0], 1
] call CBA_fnc_addSetting;

[
    "auqol_loot_enemyRadius", "SLIDER",
    ["Enemy check radius (m)", "Gathering is refused while an enemy in combat mode is this close to the vehicle or crate, 10 to 2000 m."],
    [_category, "Loot gathering"],
    [10, 2000, 100, 0], 1
] call CBA_fnc_addSetting;

[
    "auqol_loot_caches", "CHECKBOX",
    ["Also loot item caches within 30 m", "Enemy item caches (the supply crates at outposts, bases and airports) within 30 m of the vehicle or loot crate are emptied into it too."],
    [_category, "Loot gathering"],
    true, 1
] call CBA_fnc_addSetting;

// --- Night spotting (applied on every machine to the enemy AI local to it)
private _nightChanged = { if (auqol_ready) then { [] call AUQOL_fnc_nightApply } };

[
    "auqol_night_enabled", "CHECKBOX",
    ["Enemies without night vision spot worse in the dark", "At night, enemy AI with no night vision or thermal (goggles, helmet visor, weapon sight or a vehicle sight) find you and your squad much later and at shorter range. How much depends on how dark it is: moon height and phase and cloud cover. Gunfire, contact reports and Antistasi's own AI work as before."],
    [_category, "Night spotting"],
    true, 1, _nightChanged
] call CBA_fnc_addSetting;

[
    "auqol_night_strength", "SLIDER",
    ["Enemy spotting in full darkness (%)", "Their spot distance and spot time skills on a moonless, overcast night, as a share of normal, 5 to 100. A clear full moon night is a bit over halfway back to normal. 100 turns the effect off."],
    [_category, "Night spotting"],
    [5, 100, 25, 0], 1, _nightChanged
] call CBA_fnc_addSetting;

[
    "auqol_night_noise", "CHECKBOX",
    ["Noise gives you away", "On: inside the distances below an enemy spots you as well as by day (prone, crouched, walking, running, sprinting, engines). Off: noise doesn't help them; gunfire is still heard."],
    [_category, "Night spotting"],
    false, 1, _nightChanged
] call CBA_fnc_addSetting;

[
    "auqol_night_lights", "CHECKBOX",
    ["Lights give you away", "On: with your weapon light or headlights on, under a working street lamp or near a flare, you are seen from 6 times the walking distance below."],
    [_category, "Night spotting"],
    true, 1, _nightChanged
] call CBA_fnc_addSetting;

[
    "auqol_night_closeRange", "SLIDER",
    ["Noise and light distance (m)", "For a soldier walking upright, 10 to 200 m. Inside it an enemy spots you as well as by day. Other movement scales it: prone x0.4, crouched x0.7, running x2, sprinting x3, a vehicle with its engine on x4 (with Noise gives you away), and x6 when you are lit (with Lights give you away). Gunfire is always heard."],
    [_category, "Night spotting"],
    [10, 200, 50, 0], 1, _nightChanged
] call CBA_fnc_addSetting;

// --- Concealment (each player's machine, for the player and their squad AI). Off while HATG is loaded.
private _concealChanged = { if (auqol_ready) then { [] call AUQOL_fnc_concealTick } };

[
    "auqol_conceal_enabled", "CHECKBOX",
    ["Hide among the grass", "Lying still (or sneaking crouched) off roads, with no enemy close, makes you and your squad invisible to enemy AI until you are hit, someone fires close to you or you fire too much. Like the Hide Among The Grass mod; switches itself off when that mod is loaded."],
    [_category, "Concealment"],
    true, 1, _concealChanged
] call CBA_fnc_addSetting;

[
    "auqol_conceal_squad", "CHECKBOX",
    ["Also your squad's AI", "The AI in your group hide the same way."],
    [_category, "Concealment"],
    true, 1, _concealChanged
] call CBA_fnc_addSetting;

[
    "auqol_conceal_crouch", "CHECKBOX",
    ["Hide while crouched", "Crouching also hides you, as long as you move no faster than the speed below. Standing only hides you under a roof."],
    [_category, "Concealment"],
    true, 1, _concealChanged
] call CBA_fnc_addSetting;

[
    "auqol_conceal_crouchSpeed", "SLIDER",
    ["Crouched hiding speed (km/h)", "The fastest you can move crouched and stay hidden, 0 to 20. 5 is sneaking, 12 walking."],
    [_category, "Concealment"],
    [0, 20, 5, 0], 1, _concealChanged
] call CBA_fnc_addSetting;

[
    "auqol_conceal_surfaces", "CHECKBOX",
    ["Only in grass or bushes", "On: hiding needs ground with grass or field clutter, a bush within 3 m, or a roof. Off: any ground off a road."],
    [_category, "Concealment"],
    false, 1, _concealChanged
] call CBA_fnc_addSetting;

[
    "auqol_conceal_distance", "SLIDER",
    ["Detection distance (m)", "No hiding with a living enemy this close when prone, twice it crouched, four times standing, 0 to 100. Halved for each of night, rain, fog, a roof and a ghillie suit (at least 5 m). Anyone firing within it reveals you."],
    [_category, "Concealment"],
    [0, 100, 10, 0], 1, _concealChanged
] call CBA_fnc_addSetting;

[
    "auqol_conceal_cooldown", "SLIDER",
    ["Revealed for (s)", "How long you stay visible after being hit, shot near or firing too much, 0 to 600."],
    [_category, "Concealment"],
    [0, 600, 15, 0], 1
] call CBA_fnc_addSetting;

[
    "auqol_conceal_shots", "SLIDER",
    ["Shots before you are revealed", "From one spot (within 10 m), -1 to 60: a random 4 to 8 at 4, more with a ghillie suit, many more with a suppressor, half without one. Firing a launcher always reveals you. -1: shooting never reveals you."],
    [_category, "Concealment"],
    [-1, 60, 4, 0], 1
] call CBA_fnc_addSetting;

[
    "auqol_conceal_partial", "CHECKBOX",
    ["Partial camouflage when not hidden", "When you can't hide (enemy close, moving, after shooting's cooldown ends), you are still harder to see: prone x0.5, crouched x0.75, x0.7 in grass or next to a bush (not while running), x0.6 in a ghillie suit."],
    [_category, "Concealment"],
    true, 1, _concealChanged
] call CBA_fnc_addSetting;

[
    "auqol_conceal_hud", "CHECKBOX",
    ["Show hidden indicator", "A stealth icon at the bottom of the screen: grey HIDDEN, white SEEN, red OFF after the toggle key."],
    [_category, "Concealment"],
    true, 0, _concealChanged
] call CBA_fnc_addSetting;

[
    "auqol_conceal_locate", "CHECKBOX",
    ["Hard to locate at range", "Enemies farther away than the distance below don't learn where you or your squad are from your shots alone, only by seeing you. Also works with the Hide Among The Grass mod."],
    [_category, "Concealment"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_conceal_locateRange", "SLIDER",
    ["Shot gives you away within (m)", "For an unsuppressed rifle, 100 to 1500. Scaled by the round's and muzzle device's loudness from config (a suppressor brings 500 m down to 100 to 160 m), muzzle flash in the dark (open muzzle x1.2 at night, suppressor less; night vision sees it as by day), uniform camouflage (ghillie x0.6), prone x0.8, +25 % for each further shot from the same spot (up to x3), and a random x0.8 to 1.2."],
    [_category, "Concealment"],
    [100, 1500, 500, 0], 1
] call CBA_fnc_addSetting;

// --- Antistasi "Withstand" self-revive cooldown (read on each client, so the setting script applies it everywhere)
private _withstandChanged = { if (auqol_ready) then { call AUQOL_fnc_withstandApply } };

[
    "auqol_withstand_enabled", "CHECKBOX",
    ["Shorter Withstand cooldown", "Replaces the 5-minute cooldown of Antistasi's Withstand self-revive with the time below. Needs the mission's Withstand self-revive parameter."],
    [_category, "Withstand"],
    true, 1, _withstandChanged
] call CBA_fnc_addSetting;

[
    "auqol_withstand_timeout", "SLIDER",
    ["Withstand cooldown (s)", "Seconds before Withstand can be used again, 1 to 300. Antistasi's default is 300."],
    [_category, "Withstand"],
    [1, 300, 1, 0], 1, _withstandChanged
] call CBA_fnc_addSetting;

// --- Diagnostics
[
    "auqol_debug", "CHECKBOX",
    ["Verbose diagnostic logging", "Writes one RPT line per ejection, refill and loot run, and every 5 minutes the average and worst time of each AUQOL timer. Leave off during normal play."],
    [_category, "Diagnostics"],
    false, 0
] call CBA_fnc_addSetting;
