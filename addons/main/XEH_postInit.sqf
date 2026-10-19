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
// Player animation boosts (ladder, pistol swap): setAnimSpeedCoef only acts on the machine that runs it.
["auqol_anim_coef", { (_this select 0) setAnimSpeedCoef (_this select 1) }] call CBA_fnc_addEventHandler;
["auqol_stuck_message", { systemChat ("[AUQOL] " + (_this select 0)) }] call CBA_fnc_addEventHandler;

// Added on every machine: the handlers act only where the vehicle is local, which follows locality changes.
["LandVehicle", "InitPost", { (_this select 0) call AUQOL_fnc_ejectInitVehicle }, true, ["StaticWeapon"], true] call CBA_fnc_addClassEventHandler;
// One handler for every other object. Weapon holders (dropped gear, the gear of every body) are the most
// common spawns and are never service objects or loot targets, so they are skipped.
["All", "InitPost", {
    params ["_object"];
    _object call AUQOL_fnc_serviceInitObject;
    [_object] call AUQOL_fnc_lootInitObject;
}, true, ["Man", "WeaponHolder", "WeaponHolderSimulated"], true] call CBA_fnc_addClassEventHandler;

// Faster AI reactions: a unit is checked where it is local when it spawns, 5 s later (after Antistasi has
// set its skills) and whenever it becomes local to a new machine (server <-> headless client).
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
        if (_isLocal) then { [[_unit]] call AUQOL_fnc_squadReactApply };
    }];
    if (!local _unit) exitWith {};
    [[_unit]] call AUQOL_fnc_squadReactApply;
    [{ [[_this]] call AUQOL_fnc_squadReactApply }, _unit, 5] call CBA_fnc_waitAndExecute;
}, true, [], true] call CBA_fnc_addClassEventHandler;

// Antistasi's rebel loadout editor is a BIS arsenal; its open event is the only hook into that screen.
if (hasInterface) then {
    [missionNamespace, "arsenalOpened", { _this call AUQOL_fnc_loadoutCopyInit }] call BIS_fnc_addScriptedEventHandler;
};

// Vanilla resupply (2.12+): fires repeatedly while a vehicle is being rearmed, repaired or refuelled.
addMissionEventHandler ["Service", { _this call AUQOL_fnc_serviceOnService }];

["CBA_settingsInitialized", { call AUQOL_fnc_settingsInitialized }] call CBA_fnc_addEventHandler;
