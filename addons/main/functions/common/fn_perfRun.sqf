/*
    Author: AUQOL
    Runs one pass of a recurring AUQOL timer. With debug logging on it also measures how long the pass
    took and, every 5 minutes, writes the average and worst time of each timer to the RPT, so the
    mod's own cost can be read in a real game. With debug logging off it only runs the code.

    Arguments:
    0: Timer name <STRING>
    1: Code to run <CODE>

    Return Value: none
*/

params ["_name", "_code"];

if !(missionNamespace getVariable ["auqol_debug", false]) exitWith { [] call _code };

private _start = diag_tickTime;
[] call _code;
private _ms = (diag_tickTime - _start) * 1000;

(auqol_perf_stats getOrDefault [_name, [0, 0, 0], true]) params ["_total", "_count", "_worst"];
auqol_perf_stats set [_name, [_total + _ms, _count + 1, _worst max _ms]];

if (time >= auqol_perf_nextReport) then {
    auqol_perf_nextReport = time + 300;
    {
        _y params ["_total", "_count", "_worst"];
        [format ["Timing: %1 ran %2 times, average %3 ms, worst %4 ms", _x, _count, (_total / _count) toFixed 3, _worst toFixed 3]] call AUQOL_fnc_log;
    } forEach auqol_perf_stats;
    auqol_perf_stats = createHashMap;
};
