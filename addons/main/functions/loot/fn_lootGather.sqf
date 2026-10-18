/*
    Author: AUQOL
    Server handler for the loot action. Runs Antistasi's own SCRT_fnc_loot_gatherLoot, the function the
    loot crate uses, so enemy check, cooldown, unlocked-item rules and money split are identical.
    The radius is the server's auqol_loot_radius, or Antistasi's lootCrateDistance parameter for the
    crate when the feature is off.

    Arguments:
    0: Vehicle or loot crate <OBJECT>

    Return Value: none
*/

params [["_object", objNull, [objNull]]];

if (!isServer || {!alive _object} || {isNil "SCRT_fnc_loot_gatherLoot"}) exitWith {};

// Sent by clients: only accept objects that carry the action.
private _kind = [_object] call AUQOL_fnc_lootIsTarget;
if (_kind == 0 || {_kind == 1 && {!auqol_loot_enabled}}) exitWith {};

private _radius = if (auqol_loot_enabled) then {
    10 max round auqol_loot_radius min 2000
} else {
    missionNamespace getVariable ["lootCrateDistance", 50]
};

[format ["Gathering loot into %1 (radius %2)", typeOf _object, _radius], true] call AUQOL_fnc_log;
[_object, _radius] spawn SCRT_fnc_loot_gatherLoot;
