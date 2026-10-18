/*
    Author: AUQOL
    Adds the immobilization triggers to a land vehicle (CBA InitPost, every machine). Dammaged and Fuel
    are global events; each handler exits early unless the vehicle is local, so exactly one machine
    acts even after locality changes. GetIn re-checks when units board an already immobilized vehicle.

    Arguments:
    0: Vehicle <OBJECT>

    Return Value: none
*/

params ["_vehicle"];

if (!isNil {_vehicle getVariable "auqol_eject_ehs"}) exitWith {};

_vehicle setVariable ["auqol_eject_ehs", [
    _vehicle addEventHandler ["Dammaged", { [_this select 0] call AUQOL_fnc_ejectEvaluate }],
    _vehicle addEventHandler ["Fuel", { if !(_this select 1) then { [_this select 0] call AUQOL_fnc_ejectEvaluate } }],
    _vehicle addEventHandler ["GetIn", { [_this select 0] call AUQOL_fnc_ejectEvaluate }]
]];
