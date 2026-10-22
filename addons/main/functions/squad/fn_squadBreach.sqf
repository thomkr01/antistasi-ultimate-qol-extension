/*
    Author: AUQOL
    Breach and clear on the Reveal target key (AUQOL_fnc_squadRevealTarget): when you mark an enemy soldier
    standing inside a building within 150 m, the two free AI of your group nearest to that building (free as
    in AUQOL_fnc_combatIsEligible) move in together to the building positions nearest to him, and the
    squad's focus is already on him. After 30 s they go back into formation (AUQOL_fnc_squadOverwatch
    releases them). Only your own squad is ordered, and only by your key press.
    Arguments:
    0: Enemy <OBJECT>
    Return Value: none
*/
params ["_target"];
if (!auqol_squad_breach || {!(_target isKindOf "CAManBase")} || {leader group player isNotEqualTo player} || {player distance _target > 150}) exitWith {};
private _pos = getPosATL _target;
private _near = nearestObjects [_pos, ["House", "Building"], 25];
private _idx = _near findIf { count (_x buildingPos -1) > 1 && {_pos inArea [getPosATL _x, (boundingBoxReal _x select 2) * 0.7, (boundingBoxReal _x select 2) * 0.7, 0, false]} };
if (_idx == -1) exitWith {};
private _house = _near select _idx;
private _spots = ((_house buildingPos -1) apply { [_x distance _target, _x] });
_spots sort true;
private _crew = (units group player select { local _x && {[_x] call AUQOL_fnc_combatIsEligible} && {_x distance _house < 80} }) apply { [_x distance _house, _x] };
_crew sort true;
private _taken = [];
{
    _x params ["", "_unit"];
    private _spot = (_spots select { private _s = _x select 1; _taken findIf { _x distance _s < 1.5 } == -1 }) param [0, []];
    if (_spot isEqualTo []) then { continue };
    _taken pushBack (_spot select 1);
    _unit setVariable ["auqol_tacTeam", 0];
    _unit setVariable ["auqol_tacDest", _spot select 1];
    _unit setVariable ["auqol_tacIndoor", true];
    _unit setVariable ["auqol_owUntil", time + 30];
    _unit setVariable ["auqol_owBreach", true];
    _unit setVariable ["auqol_owAt", time];
    _unit doMove (_spot select 1);
} forEach (_crew select [0, 2]);
// Going in is an order to engage: it ends ambush discipline, so the squad does not walk in on Hold fire.
if (_taken isNotEqualTo []) then { [true] call AUQOL_fnc_squadAmbush };
if (_taken isNotEqualTo []) then { [format ["Breach: %1 moving into %2", count _taken, typeOf _house], true] call AUQOL_fnc_log };
