/*
    Author: AUQOL
    Gives a unit's group the EnemyDetected hook that starts smart combat tactics for it
    (AUQOL_fnc_combatStart). Called for every unit on every machine when it spawns and when it changes
    owner; the hook acts only where the group is local. One hook per group and machine.

    Arguments:
    0: Unit <OBJECT>

    Return Value: none
*/

params ["_unit"];
private _group = group _unit;
if (isNull _group || {!isNil {_group getVariable "auqol_tacHook"}}) exitWith {};
_group setVariable ["auqol_tacHook", _group addEventHandler ["EnemyDetected", {
    params ["_group"];
    if (local _group) then { [_group] call AUQOL_fnc_combatStart };
}]];
