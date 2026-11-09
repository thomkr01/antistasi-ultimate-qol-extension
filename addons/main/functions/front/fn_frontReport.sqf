/*
    Author: AUQOL
    "Where is it?" from the command menu: the first of the given AI that can see the enemy calls out where he is
    (AUQOL_fnc_squadCallout, at once), or the first of them says it has no visual. Only AI of your own group.

    Arguments:
    0: Enemy <OBJECT>
    1: AI to ask <ARRAY> (the units you had selected; empty: your whole group)

    Return Value: none
*/
params ["_target", ["_units", []]];
if (!hasInterface || {!auqol_ready} || {!auqol_front_menu} || {isNull _target}) exitWith {};
_units = _units select { !isPlayer _x && {alive _x} && {group _x isEqualTo group player} && {lifeState _x in ["HEALTHY", "INJURED"]} };
if (_units isEqualTo []) then { _units = units group player select { !isPlayer _x && {alive _x} && {lifeState _x in ["HEALTHY", "INJURED"]} } };
if (_units isEqualTo []) exitWith {};
private _seer = _units findIf { ([_x, "VIEW", _target] checkVisibility [eyePos _x, aimPos _target]) > 0 };
if (_seer == -1) exitWith { (_units select 0) groupChat "Negative, no visual on that one." };
[_target, _units select _seer, true] call AUQOL_fnc_squadCallout;
