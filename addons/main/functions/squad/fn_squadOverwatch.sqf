/*
    Author: AUQOL
    Overwatch for the squad you lead, every second. With a known enemy within 300 m and you standing
    still for 3 s, each AI that is free (AUQOL_fnc_combatIsEligible: no order of yours, not treating,
    not stopped) takes the nearest cover within 15 m (AUQOL_fnc_combatFindCover, at most two units per
    pass) and covers from it. When you move again, the enemy is gone or the setting is off, they go back
    into formation (AUQOL_fnc_combatRelease). Breach orders (AUQOL_fnc_squadBreach) are held for 30 s
    regardless. The units carry the smart combat spot variables, so stuck recovery leaves them alone.
    Arguments: none
    Return Value: none
*/
private _player = player;
if (!hasInterface || {isNull _player}) exitWith {};
private _group = group _player;
private _ai = units _group select { local _x && {!isPlayer _x} && {alive _x} };
private _enemy = _player findNearestEnemy _player;
private _fight = auqol_squad_overwatch && {leader _group isEqualTo _player} && {!isNull _enemy} && {_player distance _enemy < 300};
if (speed _player >= 1) then { _group setVariable ["auqol_owStill", time] };
private _halted = time - (_group getVariable ["auqol_owStill", time]) > 3;
_group setVariable ["auqol_owStill", _group getVariable ["auqol_owStill", time]];
{
    private _until = _x getVariable "auqol_owUntil";
    if (!isNil "_until" && {time >= _until || {!(_x getVariable ["auqol_owBreach", false]) && {!_fight || {!_halted}}}}) then {
        _x setVariable ["auqol_owUntil", nil];
        _x setVariable ["auqol_owBreach", nil];
        [_x] call AUQOL_fnc_combatRelease;
    };
} forEach _ai;
if (!_fight || {!_halted} || {!isNull objectParent _player}) exitWith {};
private _ePos = _player getHideFrom _enemy;
if (_ePos isEqualTo [0, 0, 0]) exitWith {};
if (time >= _group getVariable ["auqol_owLogAt", 0]) then {
    _group setVariable ["auqol_owLogAt", time + 15];
    [format ["Overwatch: %1 of %2 squad AI can be moved", count (_ai select { [_x] call AUQOL_fnc_combatIsEligible }), count _ai], true] call AUQOL_fnc_log;
};
private _taken = _ai apply { _x getVariable ["auqol_tacDest", getPosATL _x] };
private _done = 0;
{
    if (_done >= 2) exitWith {};
    private _unit = _x;
    if (!isNil {_unit getVariable "auqol_tacDest"} || {time < _unit getVariable ["auqol_tacNextSeek", 0]} || {!([_unit] call AUQOL_fnc_combatIsEligible)}) then { continue };
    _unit setVariable ["auqol_tacNextSeek", time + 8];
    _done = _done + 1;
    private _pos = [_unit, _ePos, getPosATL _unit, 15, _taken] call AUQOL_fnc_combatFindCover;
    if (_pos isEqualTo []) then { continue };
    _pos params ["_spot", "_indoor"];
    _taken pushBack _spot;
    _unit setVariable ["auqol_tacTeam", 0];
    _unit setVariable ["auqol_tacDest", _spot];
    _unit setVariable ["auqol_tacIndoor", _indoor];
    _unit setVariable ["auqol_owUntil", time + 120];
    _unit doMove _spot;
} forEach _ai;
