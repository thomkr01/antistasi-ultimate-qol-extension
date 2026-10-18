/*
    Author: AUQOL
    CBA InitPost handler (every machine with an interface). Gives vehicles the same "Gather Scattered
    Loot" hold action as Antistasi's loot crate, and swaps the crate's own action for the AUQOL one so
    both use the same radius. Does nothing without Antistasi Ultimate.

    Arguments:
    0: Object <OBJECT>

    Return Value: none
*/

params ["_object"];

if (!hasInterface || {isNil "SCRT_fnc_loot_gatherLoot"}) exitWith {};

private _kind = [_object] call AUQOL_fnc_lootIsTarget;
if (_kind == 0) exitWith {};

if (_kind == 1) exitWith {
    [_object, "auqol_loot_enabled && {vehicle player == player} && {_this distance _target < 5}"] call AUQOL_fnc_lootAddAction;
};

// Loot crate: Antistasi adds its action by JIP remoteExec, which can land after this handler. Wait for it,
// remove it, and add ours under the same variable so Antistasi's Killed handler still removes it.
[
    { !isNil { _this getVariable "lootActionID" } || {isNull _this} },
    {
        if (isNull _this) exitWith {};
        [_this, _this getVariable "lootActionID"] call BIS_fnc_holdActionRemove;
        _this setVariable ["lootActionID", [_this, "vehicle player == player && {_this distance _target < 5}"] call AUQOL_fnc_lootAddAction];
    },
    _object, 120,
    { if (!isNull _this) then { _this setVariable ["lootActionID", [_this, "vehicle player == player && {_this distance _target < 5}"] call AUQOL_fnc_lootAddAction] } }
] call CBA_fnc_waitUntilAndExecute;
