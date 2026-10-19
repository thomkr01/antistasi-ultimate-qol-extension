/*
    Author: AUQOL
    Stuck check and recovery step for one local AI unit, called every 5 s by AUQOL_fnc_stuckMonitor.

    Eligibility (what is watched and what is skipped) is AUQOL_fnc_stuckIsEligible; an ineligible unit
    has its tracking cleared. Within 8 m of the destination (25 m when driving) the unit has arrived and
    is dropped.

    Progress: getting auqol_stuck_minProgress metres closer to the destination than the unit has been
    so far, or moving that far from where the current window started. Moving only counts while the
    unit has reached a new closest point within the last three timeouts, so a unit circling an obstacle
    or shuttling back and forth is not reset forever, while a detour of up to three timeouts is fine.
    A destination that moves (a leader to follow, a new order) restarts the closest-point record, so
    formation followers keep the plain movement rule. No progress for auqol_stuck_timeout seconds
    means stuck.
    Each recovery step then gets another timeout window to work before the next enabled step is tried.
    After the last step: one failed round, a cooldown, and after auqol_stuck_maxAttempts rounds the unit
    is left alone until it moves again by itself.

    Arguments:
    0: Unit <OBJECT>

    Return Value: none
*/

params ["_unit"];

if (!local _unit || {!([_unit] call AUQOL_fnc_stuckIsEligible)}) exitWith { _unit setVariable ["auqol_stuck", nil] };

private _veh = vehicle _unit;
private _onFoot = _veh isEqualTo _unit;
private _group = group _unit;
private _leader = leader _group;
(expectedDestination _unit) params [["_dest", []], ["_mode", "DoNotPlan"]];

private _now = time;
private _pos = getPosASL _veh;
private _dist = _veh distance2D _dest;
private _state = _unit getVariable "auqol_stuck";

// Close enough to where it is going: nothing to do. Reported as a success when a step got it there.
if (_dist <= ([25, 8] select _onFoot)) exitWith {
    if (!isNil "_state" && {_state get "stage" > 0}) then {
        private _how = ["", "after refreshing its order", "after rejoining formation", "after a short hop", "after the teleport"] select (_state get "stage");
        [_unit, "reached its position " + _how, "result"] call AUQOL_fnc_stuckNotify;
    };
    _unit setVariable ["auqol_stuck", nil];
};

// New, or not seen for a while (left the scope, was busy), or moved to another group: start fresh.
if (isNil "_state" || {_now - (_state get "seen") > 15} || {(_state get "group") isNotEqualTo _group}) then {
    _state = createHashMapFromArray [["pos", _pos], ["dest", _dest], ["best", _dist], ["bestAt", _now], ["since", _now], ["stage", 0],
        ["rounds", 0], ["nextTry", 0], ["gaveUp", false], ["group", _group]];
    _unit setVariable ["auqol_stuck", _state];
};
_state set ["seen", _now];

private _minProgress = auqol_stuck_minProgress;
if (_dest distance2D (_state get "dest") > _minProgress) then {
    _state set ["dest", _dest];
    _state set ["best", _dist];
    _state set ["bestAt", _now];
};
private _closer = _dist <= (_state get "best") - _minProgress;
if (_closer) then {
    _state set ["best", _dist];
    _state set ["bestAt", _now];
};
private _moved = _pos distance (_state get "pos") >= _minProgress && {_now - (_state get "bestAt") < 3 * auqol_stuck_timeout};
if (_closer || _moved) exitWith {
    private _stage = _state get "stage";
    if (_stage > 0 || {_state get "rounds" > 0}) then {
        private _how = ["by itself", "after refreshing its order", "after rejoining formation", "after a short hop", "after the teleport"] select _stage;
        [_unit, "is moving again " + _how, "result"] call AUQOL_fnc_stuckNotify;
    };
    _state set ["pos", _pos];
    _state set ["since", _now];
    _state set ["stage", 0];
    _state set ["rounds", 0];
    _state set ["gaveUp", false];
};

if (_state get "gaveUp" || {_now < _state get "nextTry"} || {_now - (_state get "since") < auqol_stuck_timeout}) exitWith {};

// Stuck. Pick the next enabled step that applies to this unit.
private _stage = _state get "stage";
private _isFollower = _onFoot && _leader isNotEqualTo _unit && {currentCommand _unit == ""};
private _candidates = [auqol_stuck_refreshOrders, auqol_stuck_regroup && _isFollower, auqol_stuck_reposition,
    auqol_stuck_teleport && _onFoot && {alive _leader} && {_leader isNotEqualTo _unit && _unit distance _leader <= auqol_stuck_maxDistance}];
private _next = -1;
for "_i" from _stage to 3 do {
    if (_candidates select _i) exitWith { _next = _i + 1 };
};

_state set ["pos", _pos];
_state set ["since", _now];

if (_next == -1) exitWith {
    private _rounds = (_state get "rounds") + 1;
    _state set ["rounds", _rounds];
    _state set ["stage", 0];
    if (_rounds >= auqol_stuck_maxAttempts) then {
        _state set ["gaveUp", true];
        [_unit, format ["is still stuck after %1 recovery rounds; leaving it alone until it moves", _rounds], "result"] call AUQOL_fnc_stuckNotify;
    } else {
        _state set ["nextTry", _now + auqol_stuck_cooldown];
        [_unit, format ["is still stuck; trying again in %1 s", round auqol_stuck_cooldown], "result"] call AUQOL_fnc_stuckNotify;
    };
};

if (_stage == 0) then {
    // Why: something solid right in front (knee height, 2 m toward the destination), else pathfinding.
    private _from = _pos vectorAdd [0, 0, 0.5];
    private _dir = _from vectorFromTo ((AGLToASL _dest) vectorAdd [0, 0, 0.5]);
    _dir set [2, 0];
    private _hit = lineIntersectsSurfaces [_from, _from vectorAdd (vectorNormalized _dir vectorMultiply ([6, 2] select _onFoot)), _unit, _veh, true, 1, "GEOM", "NONE"];
    private _reason = if (_hit isNotEqualTo []) then {
        private _obstacle = (_hit select 0) select 2;
        if (isNull _obstacle) then { "blocked by terrain" } else {
            private _label = getText (configOf _obstacle >> "displayName");
            format ["blocked by %1", [_label, "an obstacle"] select (_label == "")]
        }
    } else {
        ["cannot find a way to its destination", "cannot keep up with its squad"] select (_mode in ["FORMATION PLANNED", "DoNotPlanFormation"])
    };
    [_unit, format ["seems stuck (%1)", _reason], "detect"] call AUQOL_fnc_stuckNotify;
};

_state set ["stage", _next];
private _done = [_unit, _next, _dest] call AUQOL_fnc_stuckRecover;
// Measure the next window from where the step left the unit, so a hop or teleport alone is not progress.
_state set ["pos", getPosASL _veh];
_state set ["best", _veh distance2D _dest];
if (!_done) then { _state set ["since", _now - auqol_stuck_timeout] }; // nothing happened: next step on the next check
[_unit, format ["recovery step %1: %2%3", _next, ["refresh move order", "rejoin formation", "short safe hop", "teleport to squad leader"] select (_next - 1), ["", " (not carried out: no safe spot, or the unit got busy)"] select !_done], "detect"] call AUQOL_fnc_stuckNotify;
