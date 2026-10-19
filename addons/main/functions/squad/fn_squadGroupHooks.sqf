/*
    Author: AUQOL
    Adds AUQOL's group event handlers to the local player's group, once per group. Called when the
    player's group changes (CBA "group" player event, which also fires once at start).
    - EnemyDetected: a new enemy was spotted by the group. With faster squad reactions on, every unit
      gets the best knowledge anyone on its side has of it at once, instead of waiting for the spoken
      contact report to reach it through the radio queue. For vehicles the launcher check also runs at
      once instead of waiting for the 5 s fallback pass.
    - UnitJoined: a recruit joined, so the squad perks, the self-treat hook and the faster reactions are
      applied to it at once.
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
    params ["_group", "_target"];
    if (group player isNotEqualTo _group) exitWith {};
    if (auqol_squad_reaction) then { { _x reveal _target } forEach (units _group select { local _x && {!isPlayer _x} }) };
    if !(_target isKindOf "Man") then { call AUQOL_fnc_squadLaunchers };
}];
_group addEventHandler ["UnitJoined", {
    params ["_group", "_unit"];
    if (group player isEqualTo _group) then { call AUQOL_fnc_playerApply; call AUQOL_fnc_squadSelfTreat };
    [[_unit]] call AUQOL_fnc_squadReactApply;
}];
