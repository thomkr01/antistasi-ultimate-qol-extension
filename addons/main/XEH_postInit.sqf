// Event wiring. Handlers check settings when they fire, so registering them before settings are ready is safe.

// Network events. Each runs on the machine that owns the object passed as target. The loot request is
// the one remoteExecCall (AUQOL_fnc_lootAddAction), because the server has to know who sent it.
["auqol_eject_unit", { _this call AUQOL_fnc_ejectUnit }] call CBA_fnc_addEventHandler;
["auqol_eject_evaluate", { _this call AUQOL_fnc_ejectEvaluate }] call CBA_fnc_addEventHandler;
["auqol_service_refill", { _this call AUQOL_fnc_serviceRefillLocal }] call CBA_fnc_addEventHandler;
["auqol_loot_message", {
    systemChat localize (_this select 0);
    playSound "A3AP_UiFailure";
}] call CBA_fnc_addEventHandler;
// Player animation boosts (pistol swap): setAnimSpeedCoef only acts on the machine that runs it.
["auqol_anim_coef", { (_this select 0) setAnimSpeedCoef (_this select 1) }] call CBA_fnc_addEventHandler;
// Smart combat contact reports: reveal only acts where the group is local, so it goes to its leader's machine.
["auqol_combat_reveal", { params ["_group", "_target", ["_level", 1.5]]; _group reveal [_target, _level] }] call CBA_fnc_addEventHandler;
// Hard to locate: each machine checks the hostile groups local to it.
["auqol_locate_shot", { _this call AUQOL_fnc_concealLocateCheck }] call CBA_fnc_addEventHandler;
["auqol_stuck_message", { systemChat ("[AUQOL] " + (_this select 0)) }] call CBA_fnc_addEventHandler;

// Added on every machine: the handlers act only where the vehicle is local, which follows locality changes.
["LandVehicle", "InitPost", { (_this select 0) call AUQOL_fnc_ejectInitVehicle }, true, ["StaticWeapon"], true] call CBA_fnc_addClassEventHandler;
// Downed aircraft: same handlers; AUQOL_fnc_ejectIsImmobilized only accepts an aircraft that is on the ground and crippled.
["Air", "InitPost", { (_this select 0) call AUQOL_fnc_ejectInitVehicle }, true, [], true] call CBA_fnc_addClassEventHandler;
// Scratch clearing: every vehicle and static weapon, acting where it is local (AUQOL_fnc_serviceScratches).
["AllVehicles", "InitPost", { (_this select 0) addEventHandler ["Dammaged", { _this call AUQOL_fnc_serviceScratches }] }, true, ["Man"], true] call CBA_fnc_addClassEventHandler;
// One handler for every other object. Weapon holders (dropped gear, the gear of every body) are the most
// common spawns and are never service objects or loot targets, so they are skipped.
["All", "InitPost", {
    params ["_object"];
    _object call AUQOL_fnc_serviceInitObject;
    [_object] call AUQOL_fnc_lootInitObject;
}, true, ["Man", "WeaponHolder", "WeaponHolderSimulated"], true] call CBA_fnc_addClassEventHandler;

// Faster AI reactions and night spotting: a unit is checked where it is local when it spawns, 5 s later (after Antistasi has
// set its skills and night gear) and whenever it becomes local to a new machine (server <-> headless client).
// Faster AI animations act only on the machine that sets them, so this runs everywhere for every unit.
// The Suppressed handler acts only where the unit is local, which follows locality changes.
["CAManBase", "InitPost", {
    params ["_unit"];
    [[_unit]] call AUQOL_fnc_animAiApply;
    _unit addEventHandler ["Suppressed", { _this call AUQOL_fnc_combatSuppressed }];
    [_unit] call AUQOL_fnc_combatGroupHook;
    _unit addEventHandler ["Local", {
        params ["_unit", "_isLocal"];
        [_unit] call AUQOL_fnc_combatGroupHook;
        if (_isLocal) then { [[_unit]] call AUQOL_fnc_squadReactApply; [[_unit]] call AUQOL_fnc_nightApply };
    }];
    if (!local _unit) exitWith {};
    [[_unit]] call AUQOL_fnc_squadReactApply;
    [{ [[_this]] call AUQOL_fnc_squadReactApply; [[_this]] call AUQOL_fnc_nightApply }, _unit, 5] call CBA_fnc_waitAndExecute;
}, true, [], true] call CBA_fnc_addClassEventHandler;

// Grenade dodge: any unit's throw, checked for frags in the handler. Concealment counts the shots of the units it hides,
// and hard to locate works out how far away a shot of a player or their squad gives them away.
// Launcher rounds: once a local AI's round has hit, its launcher check runs again, so a vehicle that is
// out of the fight gets no second round and the next vehicle gets it (AUQOL_fnc_squadLaunchers). Only
// where AUQOL already runs that check: your squad with the launcher switch on, and AI groups in a smart combat fight.
["CAManBase", "Fired", {
    params ["_unit", "_weapon", "", "", "_ammo", "", "_projectile"];
    if (_weapon == "Throw") then { _this call AUQOL_fnc_combatDodge };
    if (local _unit) then { [_unit, _weapon] call AUQOL_fnc_concealOnFired; [_unit, _weapon, _ammo] call AUQOL_fnc_concealLocateShot };
    if (!auqol_ready || {!local _unit} || {isPlayer _unit} || _weapon == "" || {_weapon != secondaryWeapon _unit}) exitWith {};
    if !([auqol_combat_antiArmor && {!isNil {group _unit getVariable "auqol_tacPFH"}}, auqol_squad_launchers] select (isPlayer leader _unit)) exitWith {};
    private _recheck = { [{ [[_this]] call AUQOL_fnc_squadLaunchers }, _this select 0, 1] call CBA_fnc_waitAndExecute };
    [{ isNull (_this select 1) }, _recheck, [_unit, _projectile], 20, _recheck] call CBA_fnc_waitUntilAndExecute;
}, true, [], true] call CBA_fnc_addClassEventHandler;

// Antistasi's rebel loadout editor is a BIS arsenal; its open event is the only hook into that screen.
if (hasInterface) then {
    [missionNamespace, "arsenalOpened", { _this call AUQOL_fnc_loadoutCopyInit }] call BIS_fnc_addScriptedEventHandler;
};

// Vanilla resupply (2.12+): fires repeatedly while a vehicle is being rearmed, repaired or refuelled.
addMissionEventHandler ["Service", { _this call AUQOL_fnc_serviceOnService }];

["CBA_settingsInitialized", { call AUQOL_fnc_settingsInitialized }] call CBA_fnc_addEventHandler;
