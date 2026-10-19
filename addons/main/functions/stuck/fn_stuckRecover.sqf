/*
    Author: AUQOL
    Runs one recovery step on a stuck local AI unit. Called only by AUQOL_fnc_stuckEvaluate, on the
    machine that owns the unit, so the local-argument AI commands are valid here.

    1: Refresh the order the unit already has, to the same place: a move order is re-issued with
       doMove, an AI group leader's current waypoint is set again, a formation follower is told to
       follow its leader, a driver is sent to its destination again. Formation, behaviour and
       waypoints are not changed.
    2: Formation followers only: clear a stuck watch target, then doStop + doFollow, which drops a
       stuck command queue and puts the unit back into formation in its own group.
    3: Short safe hop toward the destination (or the leader, for followers): at most 10 m on foot or
       25 m when driving, capped by auqol_stuck_maxDistance, onto a spot checked by
       AUQOL_fnc_stuckFindPosition, then step 1 again.
    4: Infantry only: move next to the squad leader onto a checked spot, then follow it. The evaluate
       step only offers this when the leader is within auqol_stuck_maxDistance.
    Steps 3 and 4 check the unit again with AUQOL_fnc_stuckIsEligible (including the stricter checks for
    moving: not in COMBAT behaviour) immediately before moving it, and do nothing when it fails.
    Health, gear, group, rank and role are untouched: the unit is only moved and re-ordered.

    Arguments:
    0: Unit <OBJECT>
    1: Step 1-4 <NUMBER>
    2: Destination from expectedDestination <ARRAY>

    Return Value: Step could be carried out <BOOL>
*/

params ["_unit", "_step", "_dest"];

if (!local _unit) exitWith { false };

private _veh = vehicle _unit;
private _onFoot = _veh isEqualTo _unit;
private _group = group _unit;
private _leader = leader _group;

private _fnc_refresh = {
    if (!_onFoot || {currentCommand _unit == "MOVE"}) exitWith { _unit doMove _dest };
    if (_leader isEqualTo _unit) exitWith {
        private _wp = currentWaypoint _group;
        if (_wp < count waypoints _group) then { _group setCurrentWaypoint [_group, _wp] } else { _unit doMove _dest };
    };
    _unit doFollow _leader;
};

switch (_step) do {
    case 1: { call _fnc_refresh; true };
    case 2: {
        _unit doWatch objNull;
        doStop _unit;
        _unit doFollow _leader;
        true
    };
    case 3: {
        private _target = if (_onFoot && _leader isNotEqualTo _unit && {currentCommand _unit == ""}) then { getPosATL _leader } else { _dest };
        private _range = (auqol_stuck_maxDistance min ([25, 10] select _onFoot));
        private _dir = (getPosATL _veh) vectorFromTo _target;
        _dir set [2, 0];
        _dir = vectorNormalized _dir;
        private _spot = [];
        {
            _spot = [_veh, (getPosATL _veh) vectorAdd (_dir vectorMultiply (_range * _x)), _range / 3] call AUQOL_fnc_stuckFindPosition;
            if (_spot isNotEqualTo []) exitWith {};
        } forEach [1, 0.6, 0.3];
        if (_spot isEqualTo [] || {!([_unit, true] call AUQOL_fnc_stuckIsEligible)}) exitWith { false };
        if (_onFoot) then { _unit setPosATL _spot } else { _veh setVehiclePosition [_spot, [], 0, "NONE"] };
        call _fnc_refresh;
        true
    };
    case 4: {
        if (!_onFoot || _leader isEqualTo _unit || {!alive _leader}) exitWith { false };
        private _spot = [_unit, getPosATL vehicle _leader, 15] call AUQOL_fnc_stuckFindPosition;
        if (_spot isEqualTo [] || {!([_unit, true] call AUQOL_fnc_stuckIsEligible)}) exitWith { false };
        _unit setPosATL _spot;
        _unit doFollow _leader;
        true
    };
    default { false };
};
