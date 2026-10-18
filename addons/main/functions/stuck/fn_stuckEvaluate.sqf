/*
    Author: AUQOL
    Stuck check and recovery step for one local AI unit, called every 5 s by AUQOL_fnc_stuckMonitor.

    A unit is only watched while it has somewhere to go and nothing else to do:
    - alive, AI, local, not incapacitated (Antistasi "incapacitated"), surrendered, healing someone
      (Antistasi "helping") or rearming from bodies (Antistasi "rearming");
    - movement and pathfinding AI enabled, not stopped (Stop / Hold, garrison doStop), and no command
      other than a move (currentCommand "" or "MOVE": attack, heal, get in, rearm and so on are left alone);
    - a destination from expectedDestination other than "DoNotPlan" (not moving) or "LEADER DIRECT"
      (get in, supply). Within 8 m of it (25 m when driving) the unit has arrived and is dropped;
    - on foot: on the ground, not swimming, not on a ladder. In a vehicle: the AI driver of a land
      vehicle that can move, with no player on board. Passengers and static weapons are skipped;
    - not fighting: no attack target, not suppressed, no known enemy within 300 m;
    - for AI-led groups (patrols, garrisons, HC squads): not on a HOLD, GUARD, SENTRY, LOITER or
      DISMISS waypoint and not on a CYCLE patrol route.
    Anything else clears the unit's tracking.

    Progress: moving auqol_stuck_minProgress metres from where the current window started, or getting
    that much closer to the destination. No progress for auqol_stuck_timeout seconds means stuck.
    Each recovery step then gets another timeout window to work before the next enabled step is tried.
    After the last step: one failed round, a cooldown, and after auqol_stuck_maxAttempts rounds the unit
    is left alone until it moves again by itself.

    Arguments:
    0: Unit <OBJECT>

    Return Value: none
*/

params ["_unit"];

private _veh = vehicle _unit;
private _onFoot = _veh isEqualTo _unit;
private _group = group _unit;
private _leader = leader _group;
(expectedDestination _unit) params [["_dest", []], ["_mode", "DoNotPlan"]];

private _eligible = alive _unit && {local _unit} && {!isPlayer _unit}
    && {!(_unit getVariable ["incapacitated", false])} && {!(_unit getVariable ["surrendered", false])}
    && {!(_unit getVariable ["helping", false])} && {!(_unit getVariable ["rearming", false])}
    && {lifeState _unit in ["HEALTHY", "INJURED"]}
    && {_unit checkAIFeature "MOVE"} && {_unit checkAIFeature "PATH"}
    && {!stopped _unit} && {currentCommand _unit in ["", "MOVE"]}
    && {!(_mode in ["DoNotPlan", "LEADER DIRECT"])} && {_dest isNotEqualTo []}
    && {if (_onFoot) then {
            isTouchingGround _unit && {!surfaceIsWater getPosASL _unit} && {!("ladder" in toLower animationState _unit)}
        } else {
            driver _veh isEqualTo _unit && {_veh isKindOf "LandVehicle"} && {!(_veh isKindOf "StaticWeapon")}
            && {canMove _veh} && {fuel _veh > 0} && {(crew _veh) findIf { isPlayer _x } == -1}
        }}
    && {isNull getAttackTarget _unit} && {getSuppression _unit == 0} && {_unit distance (_unit findNearestEnemy _unit) > 300}
    && {isPlayer _leader || {
            private _waypoints = waypoints _group;
            _waypoints findIf { waypointType _x == "CYCLE" } == -1
            && {!(waypointType [_group, currentWaypoint _group] in ["HOLD", "GUARD", "SENTRY", "LOITER", "DISMISS"])}
        }};

if (!_eligible) exitWith { _unit setVariable ["auqol_stuck", nil] };

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
    _state = createHashMapFromArray [["pos", _pos], ["dist", _dist], ["since", _now], ["stage", 0],
        ["rounds", 0], ["nextTry", 0], ["gaveUp", false], ["group", _group]];
    _unit setVariable ["auqol_stuck", _state];
};
_state set ["seen", _now];

private _minProgress = auqol_stuck_minProgress;
if (_pos distance (_state get "pos") >= _minProgress || {(_state get "dist") - _dist >= _minProgress}) exitWith {
    private _stage = _state get "stage";
    if (_stage > 0 || {_state get "rounds" > 0}) then {
        private _how = ["by itself", "after refreshing its order", "after rejoining formation", "after a short hop", "after the teleport"] select _stage;
        [_unit, "is moving again " + _how, "result"] call AUQOL_fnc_stuckNotify;
    };
    _state set ["pos", _pos];
    _state set ["dist", _dist];
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
_state set ["dist", _dist];
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
_state set ["dist", _veh distance2D _dest];
if (!_done) then { _state set ["since", _now - auqol_stuck_timeout] }; // nothing happened: next step on the next check
[_unit, format ["recovery step %1: %2%3", _next, ["refresh move order", "rejoin formation", "short safe hop", "teleport to squad leader"] select (_next - 1), ["", " (no safe spot found)"] select !_done], "detect"] call AUQOL_fnc_stuckNotify;
