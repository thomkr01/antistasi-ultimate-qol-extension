/*
    Author: AUQOL
    Slide down the ladder you are on: leaves the ladder and moves the player to its foot at about 5 m/s
    (Ladder Tweak Remastered has a slide-down; this is our own code, with the vanilla animations).
    The ladder is found (objects within 40 m, line within 2 m, 1.32.1) from the nearby objects' config `ladders` lines (start and end selection, both
    in model space); the one the player is on the line of is used, the lower end is the target.
    The player's unit is local, so setPosASL each frame is replicated by the engine; no object is attached.
    Called from the Slide down ladder keybind (local player only).

    Return Value: none
*/

private _unit = player;
if (!auqol_ready || {!auqol_anim_ladderSlide} || {!alive _unit} || {!local _unit}) exitWith {};
if !("ladder" in toLowerANSI animationState _unit) exitWith { [format ["Ladder slide: not on a ladder (animation %1)", animationState _unit], true] call AUQOL_fnc_log };

private _best = [];
private _bestDist = 2; // m from the ladder line (the player hangs about 0.5 m off it, and a model's ladder points need not be exact)
private _pos = getPosASL _unit;
{
    private _building = _x;
    {
        _x params ["_start", "_end"];
        private _a = _building selectionPosition _start;
        private _b = _building selectionPosition _end;
        private _local = _building worldToModel ASLToAGL _pos;
        private _line = _b vectorDiff _a;
        private _t = (((_local vectorDiff _a) vectorDotProduct _line) / ((_line vectorDotProduct _line) max 0.0001)) min 1 max 0;
        private _dist = _local distance (_a vectorAdd (_line vectorMultiply _t));
        if (_dist < _bestDist) then {
            _bestDist = _dist;
            _best = [_building, [_b, _a] select ((_a select 2) < (_b select 2))];
        };
    } forEach getArray (configOf _building >> "ladders");
} forEach (nearestObjects [_unit, [], 40, true] select { getArray (configOf _x >> "ladders") isNotEqualTo [] });
if (_best isEqualTo []) exitWith { [format ["Ladder slide: no ladder within 2 m found among %1 objects near %2", count (nearestObjects [_unit, [], 40, true]), getPosATL _unit], true] call AUQOL_fnc_log };

_best params ["_building", "_foot"];
private _target = AGLToASL (_building modelToWorld _foot);
[format ["Ladder slide: %1 from %2 to %3", typeOf _building, getPosASL _unit, _target], true] call AUQOL_fnc_log;
_unit action ["ladderOff", _building];

[{
    params ["_unit", "_target"];
    private _from = getPosASL _unit;
    private _duration = (_from distance _target) / 5;
    [{
        params ["_args", "_handle"];
        _args params ["_unit", "_from", "_target", "_start", "_duration"];
        private _t = (time - _start) / (_duration max 0.1);
        if (_t >= 1 || {!alive _unit} || {!isNull objectParent _unit} || {lifeState _unit == "INCAPACITATED"} || {!local _unit}) exitWith {
            [_handle] call CBA_fnc_removePerFrameHandler;
        };
        _unit setPosASL (_from vectorAdd ((_target vectorDiff _from) vectorMultiply _t));
        _unit setVelocity [0, 0, 0];
    }, 0, [_unit, _from, _target, time, _duration]] call CBA_fnc_addPerFrameHandler;
}, [_unit, _target], 0.3] call CBA_fnc_waitAndExecute; // lets the unit step off the ladder first
