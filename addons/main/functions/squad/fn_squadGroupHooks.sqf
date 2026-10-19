/*
    Author: AUQOL
    Adds AUQOL's group event handlers to the local player's group, once per group. Called when the
    player's group changes (CBA "group" player event, which also fires once at start).
    - EnemyDetected: a new enemy was spotted by the group, so the launcher check runs at once instead of
      waiting for the 5 s fallback pass. Infantry targets are ignored, since launchers only switch for vehicles.
    - UnitJoined: a recruit joined, so the squad perks are applied to it at once.
    Group events fire where the group is local (the machine of its leader); when another machine leads
    the group the fallback timers still cover it.

    Arguments: none
    Return Value: none
*/

if (!hasInterface) exitWith {};
private _group = group player;
if (isNull _group || {_group getVariable ["auqol_hooked", false]}) exitWith {};
_group setVariable ["auqol_hooked", true];

_group addEventHandler ["EnemyDetected", {
    params ["", "_target"];
    if (!(_target isKindOf "Man") && {group player isEqualTo (_this select 0)}) then { call AUQOL_fnc_squadLaunchers };
}];
_group addEventHandler ["UnitJoined", {
    if (group player isEqualTo (_this select 0)) then { call AUQOL_fnc_playerApply };
}];
