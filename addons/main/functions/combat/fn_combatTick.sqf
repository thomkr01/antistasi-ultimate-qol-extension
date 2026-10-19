/*
    Author: AUQOL
    One smart combat pass for a local AI group in contact (every 3 s, AUQOL_fnc_combatStart).

    The group fights as two fire teams (members split by order, the leader stays with neither). One team
    moves while the other covers, and they swap when the moving team has reached cover or after 20 s:
    - Moving team: each unit picks a covered spot (AUQOL_fnc_combatFindCover) near a point between its
      leader and the enemy, so the squad advances behind walls, rocks, trees and inside buildings
      instead of in the open. With auqol_combat_flank, the second team's point swings out to one side
      of the enemy. With auqol_combat_buildings, an enemy inside a building within 80 m is cleared:
      up to two movers take the building positions nearest to it. A mover that finds no cover
      while the enemy is within 200 m may throw smoke first (auqol_combat_smoke).
    - Covering team: units in cover crouch (only if their stance is left to the AI), units without a
      line of sight to the enemy lay suppressive fire on where it was last seen
      (auqol_combat_suppressiveFire), and a unit 12 to 35 m from an enemy it can't see, with no friend
      near that spot, throws a hand grenade (auqol_combat_grenades).

    Leaving Antistasi Ultimate's AI alone: the group's waypoints, behaviour, combat mode, formation
    and speed are never touched, so Antistasi (PATCOM) keeps steering the group and its leader. Only
    members are moved, and never one that Antistasi or another script has busy: garrisons
    (pathing or movement off, or stopped), statics and vehicles, incapacitated, surrendered, captive,
    fleeing, healing or rearming units, units with a move order AUQOL didn't give, or an Antistasi
    kill reaction in progress. Members go back into formation (doFollow) when contact ends, the group
    stops being eligible or the feature is turned off.

    Arguments:
    0: Group <GROUP>
    1: Timer handle <NUMBER>

    Return Value: none
*/

params ["_group", "_handle"];

private _stop = {
    { [_x] call AUQOL_fnc_combatRelease } forEach units _group;
    [_handle] call CBA_fnc_removePerFrameHandler;
    if (!isNull _group) then {
        _group setVariable ["auqol_tacPFH", nil];
        _group setVariable ["auqol_tacPhase", nil];
    };
};

private _leader = leader _group;
if (isNull _group || {!local _group} || {!auqol_combat_tactics} || {!alive _leader} || {isPlayer _leader}
    || {auqol_combat_yieldToAIMods && auqol_combat_aiModLoaded}) exitWith _stop;

private _enemy = _leader findNearestEnemy _leader;
if (isNull _enemy || {_leader distance _enemy > auqol_combat_range}) exitWith {
    private _idle = (_group getVariable ["auqol_tacIdle", 0]) + 1;
    _group setVariable ["auqol_tacIdle", _idle];
    if (_idle >= 10) then _stop;
};
_group setVariable ["auqol_tacIdle", 0];

// Where the group believes the enemy is, not where it really is.
private _ePos = _leader getHideFrom _enemy;
if (_ePos isEqualTo [0, 0, 0]) exitWith {};

// Antistasi's kill reaction (support call, suppressing fire, smoke charge) runs its own orders for a few seconds.
if (_group getVariable ["A3A_reactingToKill", false]) exitWith {};

private _members = (units _group - [_leader]) select { [_x] call AUQOL_fnc_combatIsEligible };
{ [_x] call AUQOL_fnc_combatRelease } forEach ((units _group - [_leader]) select { !(_x in _members) && {!isNil {_x getVariable "auqol_tacTeam"}} });
if (_members isEqualTo []) exitWith {};

{
    if (isNil {_x getVariable "auqol_tacTeam"}) then { _x setVariable ["auqol_tacTeam", _forEachIndex % 2] };
} forEach _members;

// Swap teams when every mover has arrived (at least 6 s after the swap) or after 20 s.
(_group getVariable ["auqol_tacPhase", [0, -100]]) params ["_moving", "_since"];
private _movers = _members select { _x getVariable "auqol_tacTeam" == _moving };
private _arrived = _movers findIf {
    private _dest = _x getVariable "auqol_tacDest";
    !isNil "_dest" && {_x distance2D _dest > 2.5}
} == -1;
private _newPhase = time - _since > 20 || {_arrived && {time - _since > 6}};
if (_newPhase) then {
    _moving = 1 - _moving;
    _since = time;
    _group setVariable ["auqol_tacPhase", [_moving, _since]];
    _movers = _members select { _x getVariable "auqol_tacTeam" == _moving };
};
private _coverers = _members - _movers;

private _dirToEnemy = _leader getDir _ePos;
private _distEnemy = _leader distance2D _ePos;
private _taken = _members apply { _x getVariable ["auqol_tacDest", getPosATL _x] };

// --- Movers pick their next spot once per swap
if (_newPhase) then {
    // Enemy inside a building: the movers nearest to it clear it, room by room from the closest position.
    private _house = objNull;
    if (auqol_combat_buildings && _distEnemy < 80) then {
        private _near = nearestObjects [_ePos, ["House", "Building"], 25];
        private _idx = _near findIf { count (_x buildingPos -1) > 1 && {_ePos inArea [getPosATL _x, (boundingBoxReal _x select 2) * 0.7, (boundingBoxReal _x select 2) * 0.7, 0, false]} };
        if (_idx != -1) then { _house = _near select _idx };
    };

    private _side = _group getVariable ["auqol_tacFlankSide", selectRandom [-1, 1]];
    _group setVariable ["auqol_tacFlankSide", _side];
    private _clearers = 0;

    {
        private _unit = _x;
        private _pos = [];
        if (!isNull _house && _clearers < 2) then {
            private _spots = ((_house buildingPos -1) select {
                private _spot = _x;
                _taken findIf { _x distance _spot < 1.5 } == -1
            }) apply { [_x distance _ePos, _x] };
            _spots sort true;
            if (_spots isNotEqualTo []) then { _pos = [_spots select 0 select 1, true]; _clearers = _clearers + 1 };
        };
        if (_pos isEqualTo []) then {
            // Advance a third of the way to the enemy (at most 25 m), staying within reach of the leader.
            private _dir = _dirToEnemy;
            if (auqol_combat_flank && _moving == 1 && {count _members >= 3} && _distEnemy > 40) then { _dir = _dir + 50 * _side };
            private _anchor = (getPosATL _leader) getPos [(_distEnemy / 3) min 25, _dir];
            _pos = [_unit, _ePos, _anchor, 25, _taken] call AUQOL_fnc_combatFindCover;
        };
        if (_pos isEqualTo []) then {
            // No cover near: Antistasi's own smoke charge may already be running, so only one smoke per group a minute.
            if (auqol_combat_smoke && _distEnemy < 200) then { [_unit, _ePos, "smoke"] call AUQOL_fnc_combatThrow };
        } else {
            _pos params ["_spot", "_indoor"];
            _taken pushBack _spot;
            _unit setVariable ["auqol_tacDest", _spot];
            _unit setVariable ["auqol_tacIndoor", _indoor];
            if (_unit getVariable ["auqol_tacStance", false]) then {
                if (unitPos _unit == "Middle") then { _unit setUnitPos "AUTO" };
                _unit setVariable ["auqol_tacStance", nil];
            };
            _unit doMove _spot;
        };
    } forEach _movers;
};

// --- Covering team
{
    private _unit = _x;
    private _dest = _unit getVariable "auqol_tacDest";
    private _inCover = !isNil "_dest" && {_unit distance2D _dest < 2.5};
    // Behind outdoor cover they crouch; at a building position they stay up to see out of windows.
    if (_inCover && {unitPos _unit == "Auto"} && {!(_unit getVariable ["auqol_tacIndoor", false])}) then {
        _unit setUnitPos "MIDDLE";
        _unit setVariable ["auqol_tacStance", true];
    };
    private _sees = [_unit, "VIEW", _enemy] checkVisibility [eyePos _unit, AGLToASL _ePos vectorAdd [0, 0, 1.2]] > 0.3;
    if (!_sees) then {
        private _d = _unit distance2D _ePos;
        if (auqol_combat_grenades && _d > 12 && _d < 35 && {(_ePos nearEntities ["CAManBase", 8]) findIf { side group _x == side _group } == -1}) then {
            [_unit, _ePos, "frag"] call AUQOL_fnc_combatThrow;
        } else {
            if (auqol_combat_suppressiveFire && {random 1 < 0.35} && _d < 400) then { _unit doSuppressiveFire (AGLToASL _ePos vectorAdd [0, 0, 1]) };
        };
    };
} forEach _coverers;
