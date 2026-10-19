/*
    Author: AUQOL
    One smart combat pass for a local AI group in contact (every 3 s, AUQOL_fnc_combatStart).

    The group fights as two fire teams (members split by order, the leader stays with neither). One team
    moves while the other covers, and they swap when the moving team has reached cover or after 20 s.
    Moving team: each unit picks a covered spot (AUQOL_fnc_combatFindCover) near a point that depends
    on what the group is doing:
    - advancing (default): a third of the way from the leader toward the enemy, at most 25 m, so the
      squad moves up behind walls, rocks, trees and inside buildings. With auqol_combat_flank the
      second team's point swings 50 degrees out to one side.
    - assaulting (auqol_combat_assault): with the enemy within 50 m and at least twice its number,
      the movers close in on its position, from cover if there is any, otherwise straight in.
    - defending (auqol_combat_defend): when the group isn't going anywhere (Antistasi's defend orders,
      a HOLD, GUARD or SENTRY waypoint, no waypoint left, or a stopped leader) the movers take cover
      within 30 m of the leader instead of advancing, preferring building positions.
    - against armor (auqol_combat_antiArmor): with an enemy tank or APC known within 400 m, AT gunners
      take out their launchers and target it, and everyone else takes cover 15 m further away from
      it. The launcher switch (AUQOL_fnc_squadLaunchers) runs on every pass with any enemy vehicle
      known, so AA gunners also take out their launchers against aircraft.
    With auqol_combat_buildings an enemy inside a building within 80 m is cleared: up to two movers
    take the building positions nearest to it. A mover that finds no cover while the enemy is within
    200 m may throw smoke first (auqol_combat_smoke). A mover that makes no progress to its spot for
    9 s gets a new one, and after three such spots it is handed back to its leader for 30 s (and to
    AUQOL's stuck recovery once the fight is over).
    Covering team: units in cover crouch outdoors (only if their stance is left to the AI), and with
    auqol_combat_spreadTargets they are spread over the known enemies. Those without a line of sight
    lay suppressive fire on where the enemy was last seen (auqol_combat_suppressiveFire), and one 12
    to 35 m from an enemy it can't see, with no friend near that spot, throws a hand grenade
    (auqol_combat_grenades). Ammo sharing and medics run from AUQOL_fnc_combatSupport.

    Leaving Antistasi Ultimate's AI alone: the group's waypoints, behaviour, combat mode, formation
    and speed are never touched, so Antistasi (PATCOM) keeps steering the group and its leader. Only
    members are moved, and never one that Antistasi or another script has busy
    (AUQOL_fnc_combatIsEligible), and nothing new is ordered while Antistasi's kill reaction runs.
    Members go back into formation (doFollow) when contact ends, the group stops being eligible or the
    feature is turned off.

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
// A unit only busy treating itself keeps its team and spot: a release would order it back into formation mid-treatment.
{ [_x] call AUQOL_fnc_combatRelease } forEach ((units _group - [_leader]) select {
    !(_x in _members) && {!isNil {_x getVariable "auqol_tacTeam"}} && {time >= _x getVariable ["auqol_treatUntil", 0]}
});
if (_members isEqualTo []) exitWith {};

{
    if (isNil {_x getVariable "auqol_tacTeam"}) then { _x setVariable ["auqol_tacTeam", _forEachIndex % 2] };
} forEach _members;

private _dirToEnemy = _leader getDir _ePos;
private _distEnemy = _leader distance2D _ePos;
private _enemies = (_leader targets [true, auqol_combat_range]) select { alive _x };

// What the group is doing decides where the movers go.
private _armor = objNull;
if (auqol_combat_antiArmor) then {
    _armor = (_enemies select { (_x isKindOf "Tank" || {_x isKindOf "Wheeled_APC_F"}) && {_leader distance _x < 400} && {!([_x] call AUQOL_fnc_squadIsOutOfFight)} }) param [0, objNull];
};
private _assault = auqol_combat_assault && {isNull _armor} && _distEnemy < 50
    && {count _members + 1 >= 2 * count (_enemies select { _x isKindOf "CAManBase" && {_x distance2D _ePos < 50} })};
private _defend = auqol_combat_defend && {
    ((_group getVariable ["PATCOM_Patrol_Params", []]) param [0, ""]) isEqualTo "Patrol_Defend"
    || {waypointType [_group, currentWaypoint _group] in ["HOLD", "GUARD", "SENTRY"]}
    || {currentWaypoint _group >= count waypoints _group}
    || {stopped _leader}
};

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

// Movers that made no progress to their spot for 9 s pick a new one; the stuck spot is avoided.
private _bad = _group getVariable ["auqol_tacBad", []];
private _toPick = [];
{
    private _unit = _x;
    private _dest = _unit getVariable "auqol_tacDest";
    if (_newPhase || {isNil "_dest"}) then { _toPick pushBack _unit; continue };
    private _dist = _unit distance2D _dest;
    if (_dist < 2.5) then { continue };
    (_unit getVariable ["auqol_tacProgress", [_dist, time]]) params ["_best", "_bestAt"];
    if (_dist < _best - 0.5) then { _unit setVariable ["auqol_tacProgress", [_dist, time]]; continue };
    if (time - _bestAt > 9) then {
        _bad pushBack _dest;
        private _fails = (_unit getVariable ["auqol_tacFails", 0]) + 1;
        _unit setVariable ["auqol_tacFails", _fails];
        if (_fails >= 3) then {
            [_unit] call AUQOL_fnc_combatRelease;
            _unit setVariable ["auqol_tacRestUntil", time + 30];
            _unit setVariable ["auqol_tacFails", nil];
        } else {
            _toPick pushBack _unit;
        };
    };
} forEach _movers;
_group setVariable ["auqol_tacBad", _bad select [count _bad - 10 max 0, 10]];

private _taken = (_members apply { _x getVariable ["auqol_tacDest", getPosATL _x] }) + _bad;

// --- Movers pick their next spot
if (_toPick isNotEqualTo []) then {
    // Enemy inside a building: the movers nearest to it clear it, room by room from the closest position.
    private _house = objNull;
    if (auqol_combat_buildings && _distEnemy < 80 && !_defend) then {
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
        private _hasAT = secondaryWeapon _unit != "";
        if (!isNull _house && _clearers < 2 && {isNull _armor}) then {
            private _spots = ((_house buildingPos -1) select {
                private _spot = _x;
                _taken findIf { _x distance _spot < 1.5 } == -1
            }) apply { [_x distance _ePos, _x] };
            _spots sort true;
            if (_spots isNotEqualTo []) then { _pos = [_spots select 0 select 1, true]; _clearers = _clearers + 1 };
        };
        if (_pos isEqualTo []) then {
            private _anchor = [];
            private _radius = 25;
            call {
                if (!isNull _armor && !_hasAT) exitWith { _anchor = (getPosATL _unit) getPos [15, _armor getDir _unit] };
                if (_defend) exitWith { _anchor = getPosATL _leader; _radius = 30 };
                if (_assault) exitWith { _anchor = _ePos; _radius = 12 };
                private _dir = _dirToEnemy;
                if (auqol_combat_flank && _moving == 1 && {count _members >= 3} && _distEnemy > 40) then { _dir = _dir + 50 * _side };
                _anchor = (getPosATL _leader) getPos [(_distEnemy / 3) min 25, _dir];
            };
            _pos = [_unit, _ePos, _anchor, _radius, _taken] call AUQOL_fnc_combatFindCover;
            if (_pos isEqualTo [] && _assault) then { _pos = [_ePos getPos [4, _ePos getDir _unit], false] };
        };
        if (_pos isEqualTo []) then {
            if (auqol_combat_smoke && _distEnemy < 200 && !_defend) then { [_unit, _ePos, "smoke"] call AUQOL_fnc_combatThrow };
        } else {
            _pos params ["_spot", "_indoor"];
            _taken pushBack _spot;
            _unit setVariable ["auqol_tacDest", _spot];
            _unit setVariable ["auqol_tacIndoor", _indoor];
            _unit setVariable ["auqol_tacProgress", [_unit distance2D _spot, time]];
            if (_unit getVariable ["auqol_tacStance", false]) then {
                if (unitPos _unit == "Middle") then { _unit setUnitPos "AUTO" };
                _unit setVariable ["auqol_tacStance", nil];
            };
            _unit doMove _spot;
        };
    } forEach _toPick;
};

// Any known vehicle, not only armor, so AA launchers come out against aircraft too; the function filters by launcher and range.
if (auqol_combat_antiArmor && {_enemies findIf { !(_x isKindOf "Man") } > -1}) then { [_members] call AUQOL_fnc_squadLaunchers };

// --- Covering team
private _men = _enemies select { _x isKindOf "CAManBase" };
{
    private _unit = _x;
    private _dest = _unit getVariable "auqol_tacDest";
    private _inCover = !isNil "_dest" && {_unit distance2D _dest < 2.5};
    // Behind outdoor cover they crouch; at a building position they stay up to see out of windows.
    if (_inCover && {unitPos _unit == "Auto"} && {!(_unit getVariable ["auqol_tacIndoor", false])}) then {
        _unit setUnitPos "MIDDLE";
        _unit setVariable ["auqol_tacStance", true];
    };
    // One enemy each, in turn, instead of the whole team on the same one.
    // Not a gunner with his launcher out: his vehicle target comes first (AUQOL_fnc_squadLaunchers).
    if (auqol_combat_spreadTargets && _newPhase && {count _men > 1} && {currentWeapon _unit != secondaryWeapon _unit || {secondaryWeapon _unit == ""}}) then {
        private _target = _men select (_forEachIndex % count _men);
        if (getAttackTarget _unit isNotEqualTo _target) then { _unit doTarget _target };
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

[_group, _members, _distEnemy] call AUQOL_fnc_combatSupport;
