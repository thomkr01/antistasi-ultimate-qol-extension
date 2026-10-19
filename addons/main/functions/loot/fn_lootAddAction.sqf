/*
    Author: AUQOL
    Adds the "Gather Scattered Loot" hold action, a copy of Antistasi's SCRT_fnc_loot_addActionLoot
    (same text, icon, 2 s hold, 5 m range), except that the server picks the radius and checks the
    request (AUQOL_fnc_lootGather).

    Arguments:
    0: Object <OBJECT>
    1: Show condition <STRING>

    Return Value: Action ID <NUMBER>
*/

params ["_object", "_condition"];

if (!hasInterface) exitWith {-1};

private _id = _object getVariable ["auqol_lootActionID", -1];
if (_id >= 0) then { [_object, _id] call BIS_fnc_holdActionRemove };

_id = [_object,
    localize "STR_antistasi_actions_loot_around_text",
    "\a3\missions_f_oldman\data\img\holdactions\holdaction_box_ca.paa",
    "\a3\missions_f_oldman\data\img\holdactions\holdaction_box_ca.paa",
    _condition,
    "vehicle player == player && {_caller distance _target < 5}",
    {}, {},
    // remoteExec, not a CBA event: only remoteExecutedOwner tells the server which machine sent the request.
    { [_this select 0, _this select 1] remoteExecCall ["AUQOL_fnc_lootGather", 2] },
    {}, [], 2, 5, false, false
] call BIS_fnc_holdActionAdd;

_object setVariable ["auqol_lootActionID", _id];
_id
