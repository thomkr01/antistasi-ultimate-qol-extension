/*
    Author: AUQOL
    Gives a unit's group the EnemyDetected hook that starts smart combat tactics for it
    (AUQOL_fnc_combatStart). Called for every unit on every machine when it spawns and when it changes
    owner; the hook acts only where the group is local, and also passes the sighting to nearby groups
    of its side (AUQOL_fnc_combatShareContact). One hook per group and machine.

    Arguments:
    0: Unit <OBJECT>

    Return Value: none
*/

params ["_unit"];
private _group = group _unit;
if (isNull _group || {!isNil {_group getVariable "auqol_tacHook"}}) exitWith {};
_group setVariable ["auqol_tacHook", _group addEventHandler ["EnemyDetected", {
    params ["_group", "_target"];
    if (!local _group || {isPlayer leader _group}) exitWith {};
    [_group] call AUQOL_fnc_combatStart;
    [_group, _target] call AUQOL_fnc_combatShareContact;
}]];
