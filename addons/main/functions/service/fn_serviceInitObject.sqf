/*
    Author: AUQOL
    CBA InitPost handler for every non-man object. Ignores anything that does not provide a service in
    config. Service objects are applied one second later so that state restored right after creation
    (for example the Antistasi garage restoring stored cargo) is already in place.

    Arguments:
    0: Object <OBJECT>

    Return Value: none
*/

params ["_object"];

if !([typeOf _object] call AUQOL_fnc_serviceConfig select 0) exitWith {};

[{ [_this] call AUQOL_fnc_serviceApplyObject }, _object, 1] call CBA_fnc_waitAndExecute;
