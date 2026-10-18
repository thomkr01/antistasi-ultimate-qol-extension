// Debug console, "Local exec" (single player, or your own client). Creates a real stuck case:
// a new AI in your group, boxed in by four concrete walls and ordered to a point 80 m ahead.
// With default settings expect, about every 30 s: refresh order, rejoin formation is skipped
// (the unit has a move order), then a short hop out of the box and "is moving again".
// Turn on "Message when a unit gets stuck" to see every step in system chat.
// Set _skipWait to true to skip the first 30 s wait (AUQOL_fnc_stuckSimulate marks it as stuck).
// Clean up afterwards: { deleteVehicle _x } forEach (missionNamespace getVariable ["auqol_test_stuck", []]);
private _skipWait = false;
private _ai = (group player) createUnit [typeOf player, player getRelPos [15, 0], [], 0, "NONE"];
private _objects = [_ai];
{
    private _wall = createVehicle ["Land_CncWall4_F", _ai getRelPos [2, _x], [], 0, "CAN_COLLIDE"];
    _wall setDir ((getDir _ai) + _x);
    _objects pushBack _wall;
} forEach [0, 90, 180, 270];
_ai doMove (player getRelPos [80, 0]);
missionNamespace setVariable ["auqol_test_stuck", _objects];
if (_skipWait) then { [{ [_this] call AUQOL_fnc_stuckSimulate }, _ai, 6] call CBA_fnc_waitAndExecute };
systemChat format ["[AUQOL test] %1 is boxed in and ordered to move. Stuck checks every 5 s, timeout %2 s.", name _ai, auqol_stuck_timeout];
