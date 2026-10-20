/*
    Author: AUQOL
    Hard to locate, on every machine (event auqol_locate_shot from AUQOL_fnc_concealLocateShot): for the
    hostile AI groups local here, 1.5 s after the shot (once the engine has reacted to it), a group
    farther away than the distance where the shot gives the shooter away forgets him again
    (forgetTarget), unless:
    - one of its soldiers actually saw him in the last 3 s (the engine's own lastSeen), or
    - any group of its side here is within that distance or saw him: they found him and tell the
      others over the radio.
    Enemies with night vision use the daylight distance. What the engine sees afterwards (with night
    spotting and concealment) still finds him as usual. Player-led groups are never touched. Also
    remembers the distance on the shooter, so smart combat doesn't hand his position to a group the
    shot passed close to (AUQOL_fnc_combatSuppressed).

    Arguments:
    0: Shooter <OBJECT>
    1: Distance in the dark without night vision <NUMBER>
    2: Distance with night vision or by day <NUMBER>

    Return Value: none
*/

params ["_shooter", "_range", "_rangeVision"];

if (!alive _shooter) exitWith {};
_shooter setVariable ["auqol_locate", [time, _range, _rangeVision]];

private _side = side group _shooter;
private _groups = allGroups select {
    local _x && {(side _x getFriend _side) < 0.6} && {!isPlayer leader _x} && {alive leader _x} && {leader _x distance _shooter < 2000}
};
if (_groups isEqualTo []) exitWith {};

[{
    params ["_shooter", "_range", "_rangeVision", "_groups"];
    if (!alive _shooter) exitWith {};
    private _found = [];
    private _lost = [];
    {
        private _units = units _x select { alive _x };
        if (_units isNotEqualTo []) then {
            private _limit = [_range, _rangeVision] select (_units findIf { [_x] call AUQOL_fnc_nightHasVision } != -1);
            private _near = selectMin (_units apply { _x distance _shooter });
            private _seen = _units findIf { private _t = (_x targetKnowledge _shooter) select 2; _t > 0 && {time - _t < 3} } != -1;
            if (_near <= _limit || _seen) then { _found pushBackUnique side _x } else { _lost pushBack _x };
        };
    } forEach _groups;
    {
        if (!(side _x in _found) && {_x knowsAbout _shooter > 0}) then {
            _x forgetTarget _shooter;
            [format ["Hard to locate: %1 lost %2 (%3 m away)", groupId _x, name _shooter, round (leader _x distance _shooter)], true] call AUQOL_fnc_log;
        };
    } forEach _lost;
}, [_shooter, _range, _rangeVision, _groups], 1.5] call CBA_fnc_waitAndExecute;
