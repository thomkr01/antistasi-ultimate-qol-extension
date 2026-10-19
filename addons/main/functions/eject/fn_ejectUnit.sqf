/*
    Author: AUQOL
    "auqol_eject_unit" event handler, run where the unit is local. Moves the unit out without damage
    and tells its group to stop using the vehicle so it does not climb back in.

    Arguments:
    0: Unit <OBJECT>
    1: Vehicle <OBJECT>

    Return Value: none
*/

params ["_unit", "_vehicle"];

if (!local _unit || {!alive _unit} || {objectParent _unit != _vehicle}) exitWith {};

unassignVehicle _unit;
moveOut _unit;

private _group = group _unit;
if (local _group) then {
    _group leaveVehicle _vehicle;
    // On foot now: smart combat tactics take the crew into cover right away.
    [_group] call AUQOL_fnc_combatStart;
};
