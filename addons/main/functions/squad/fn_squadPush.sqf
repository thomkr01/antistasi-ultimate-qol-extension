/*
    Author: AUQOL
    Push with you, every second, for the squad you lead (not on SAFE or STEALTH, not in a vehicle). With an enemy known
    within 300 m and you moving toward it (speed over 2 m/s and closing in), your free AI
    (AUQOL_fnc_combatIsEligible) fight as two fire teams that leapfrog with you: one team moves to cover
    just ahead of you (within 15 m of a point up to 20 m toward the enemy, AUQOL_fnc_combatFindCover) while
    the other suppresses where the enemy was last seen (doSuppressiveFire, with the combat fire chance and
    only under YELLOW or RED). The teams swap when the movers have arrived or after 8 s. When you stop for
    6 s, turn away, the enemy is gone or the setting is off, they go back into formation
    (AUQOL_fnc_combatRelease). Units with overwatch or breach orders (auqol_owUntil), orders of yours,
    treating or stopped units are never touched. The units carry the smart combat spot variables, so
    stuck recovery leaves them alone, and a unit that cannot reach its spot in 10 s is handed back.

    Arguments: none
    Return Value: none
*/
private _player = player;
if (!hasInterface || {isNull _player}) exitWith {};
private _group = group _player;
private _ai = units _group select { local _x && {!isPlayer _x} && {alive _x} };
private _owned = _ai select { _x getVariable ["auqol_pushOwned", false] };

private _enemy = _player findNearestEnemy _player;
private _ePos = if (isNull _enemy) then { [0, 0, 0] } else { _player getHideFrom _enemy };
private _fight = auqol_squad_push && {behaviour _player in ["AWARE", "COMBAT"]} && {leader _group isEqualTo _player}
    && {_ePos isNotEqualTo [0, 0, 0]} && {_player distance _ePos < 300} && {isNull objectParent _player};

// Pushing: moving and getting closer to the enemy; it holds for 6 s after the last time so a short stop does not drop the teams.
private _last = _group getVariable ["auqol_pushSample", [0, 1e6]];
if (_fight && {speed _player > 2}) then {
    private _dist = _player distance2D _ePos;
    if (time - (_last select 0) >= 2) then {
        if (_dist < (_last select 1) - 3) then { _group setVariable ["auqol_pushUntil", time + 6] };
        _group setVariable ["auqol_pushSample", [time, _dist]];
    };
} else {
    if (time - (_last select 0) >= 2) then { _group setVariable ["auqol_pushSample", [time, 1e6]] };
};
private _pushing = _fight && {time < _group getVariable ["auqol_pushUntil", 0]};

{
    private _dest = _x getVariable "auqol_tacDest";
    private _blocked = !isNil "_dest" && {time - (_x getVariable ["auqol_pushAt", time]) > 10} && {_x distance2D _dest > 2.5};
    // Overwatch or breach took the unit over: only the push marks go, its spot and team are theirs now.
    if (!isNil {_x getVariable "auqol_owUntil"}) then {
        _x setVariable ["auqol_pushOwned", nil];
        _x setVariable ["auqol_pushTeam", nil];
        continue;
    };
    if (!_pushing || _blocked) then {
        _x setVariable ["auqol_pushOwned", nil];
        _x setVariable ["auqol_pushAt", nil];
        if (_blocked) then { _x setVariable ["auqol_tacRestUntil", time + 30] };
        [_x] call AUQOL_fnc_combatRelease;
    };
} forEach _owned;
if (!_pushing) exitWith {};

private _free = _ai select { isNil {_x getVariable "auqol_owUntil"} && {[_x] call AUQOL_fnc_combatIsEligible} };
{
    if (isNil {_x getVariable "auqol_pushTeam"}) then { _x setVariable ["auqol_pushTeam", _forEachIndex % 2] };
} forEach _free;
if (_free isEqualTo []) exitWith {};

(_group getVariable ["auqol_pushPhase", [0, -100]]) params ["_moving", "_since"];
private _movers = _free select { _x getVariable "auqol_pushTeam" == _moving };
private _arrived = _movers findIf { private _d = _x getVariable "auqol_tacDest"; !isNil "_d" && {_x distance2D _d > 2.5} } == -1;
private _swap = time - _since > 8 || {_arrived && {time - _since > 3}};
if (_swap) then {
    _moving = 1 - _moving;
    _group setVariable ["auqol_pushPhase", [_moving, time]];
    _movers = _free select { _x getVariable "auqol_pushTeam" == _moving };
};

private _taken = _ai apply { _x getVariable ["auqol_tacDest", getPosATL _x] };
private _anchor = (getPosATL _player) getPos [((_player distance2D _ePos) / 3) min 20, _player getDir _ePos];
{
    private _unit = _x;
    if (_unit in _movers) then {
        if (!_swap && {!isNil {_unit getVariable "auqol_tacDest"}}) then { continue };
        private _pos = [_unit, _ePos, _anchor, 15, _taken] call AUQOL_fnc_combatFindCover;
        if (_pos isEqualTo []) then { continue };
        _pos params ["_spot", "_indoor"];
        _taken pushBack _spot;
        _unit setVariable ["auqol_pushOwned", true];
        _unit setVariable ["auqol_pushAt", time];
        _unit setVariable ["auqol_tacTeam", _unit getVariable "auqol_pushTeam"];
        _unit setVariable ["auqol_tacDest", _spot];
        _unit setVariable ["auqol_tacIndoor", _indoor];
        _unit doMove _spot;
    } else {
        // Covering: out of its cover spot's order, it fires where the enemy was last seen.
        if (_swap) then {
            if (!isNil {_unit getVariable "auqol_tacDest"}) then { _unit setVariable ["auqol_tacMoved", true] };
            _unit setVariable ["auqol_tacDest", nil];
            _unit setVariable ["auqol_pushOwned", true];
            _unit setVariable ["auqol_tacTeam", _unit getVariable "auqol_pushTeam"];
        };
        if (_swap && {combatMode _unit in ["YELLOW", "RED"]} && {random 1 < auqol_combat_fireChance / 100} && {currentWeapon _unit isEqualTo primaryWeapon _unit}) then {
            _unit doSuppressiveFire (AGLToASL _ePos vectorAdd [0, 0, 1]);
        };
    };
} forEach _free;
