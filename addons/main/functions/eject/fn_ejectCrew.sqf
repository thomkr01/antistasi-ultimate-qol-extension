/*
    Author: AUQOL
    Ejects every eligible occupant of an immobilized vehicle. Runs where the vehicle is local; each unit
    is handled on the machine that owns it, since unassignVehicle and leaveVehicle need local arguments.

    Arguments:
    0: Vehicle <OBJECT>

    Return Value: none
*/

params ["_vehicle"];

if (!alive _vehicle || {!local _vehicle} || {!([_vehicle] call AUQOL_fnc_ejectIsImmobilized)}) exitWith {};

private _units = (crew _vehicle) select { [_x] call AUQOL_fnc_ejectIsEligible };
{
    ["auqol_eject_unit", [_x, _vehicle], _x] call CBA_fnc_targetEvent;
} forEach _units;

[format ["Ejecting %1 unit(s) from immobilized %2 (%3)", count _units, typeOf _vehicle, _vehicle], true] call AUQOL_fnc_log;
