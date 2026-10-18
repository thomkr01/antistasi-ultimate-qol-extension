/*
    Author: AUQOL
    Writes one prefixed line to the RPT. Debug lines are dropped unless the auqol_debug setting is on,
    so per-event messages never flood the log in normal play.

    Arguments:
    0: Message <STRING>
    1: Debug only <BOOL> (default: false)

    Return Value: none

    Example: ["Ejected 3 units", true] call AUQOL_fnc_log;
*/

params [["_message", "", [""]], ["_debugOnly", false, [false]]];

if (_debugOnly && {!(missionNamespace getVariable ["auqol_debug", false])}) exitWith {};

diag_log text format ["[AUQOL] %1", _message];
