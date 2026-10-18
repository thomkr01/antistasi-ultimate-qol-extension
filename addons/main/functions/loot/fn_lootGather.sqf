/*
    Author: AUQOL
    Server handler for the loot action. Runs Antistasi's own SCRT_fnc_loot_gatherLoot, the function the
    loot crate uses, so enemy check, cooldown, unlocked-item rules and money split are identical.
    With the feature on, the gather radius is auqol_loot_radius and the enemies-nearby check uses its own
    auqol_loot_enemyRadius around the object; passing the position makes Antistasi skip its own check,
    which uses the gather radius. With it off, the crate is Antistasi's call with lootCrateDistance.

    Arguments:
    0: Vehicle or loot crate <OBJECT>

    Return Value: none
*/

params [["_object", objNull, [objNull]]];

if (!isServer || {!alive _object} || {isNil "SCRT_fnc_loot_gatherLoot"}) exitWith {};

// Sent by clients: only accept objects that carry the action.
private _kind = [_object] call AUQOL_fnc_lootIsTarget;
if (_kind == 0 || {_kind == 1 && {!auqol_loot_enabled}}) exitWith {};

if (!auqol_loot_enabled) exitWith {
    [_object, missionNamespace getVariable ["lootCrateDistance", 50]] spawn SCRT_fnc_loot_gatherLoot;
};

private _radius = 10 max round auqol_loot_radius min 2000;
private _enemyRadius = 10 max round auqol_loot_enemyRadius min 2000;

if ([getPosATL _object, _enemyRadius] call A3A_fnc_enemyNearCheck) exitWith {
    {
        ["auqol_loot_message", ["STR_antistasi_actions_looter_enemies_nearby"], _x] call CBA_fnc_targetEvent;
    } forEach ([_radius, _object] call SCRT_fnc_common_getNearPlayers);
};

// Same 10 s cooldown Antistasi applies, checked here so caches are not emptied for a refused run.
if (serverTime - (_object getVariable ["lastLooted", -10]) >= 10 && auqol_loot_caches) then {
    [_object] call AUQOL_fnc_lootCaches;
};

[format ["Gathering loot into %1 (radius %2, enemy check %3)", typeOf _object, _radius, _enemyRadius], true] call AUQOL_fnc_log;
[_object, _radius, getPosATL _object] spawn SCRT_fnc_loot_gatherLoot;
