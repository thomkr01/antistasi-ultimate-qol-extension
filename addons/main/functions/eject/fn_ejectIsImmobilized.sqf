/*
    Author: AUQOL
    Returns whether a land vehicle is genuinely unable to move. canMove reflects engine, wheel and track
    damage (it ignores fuel for land vehicles), so a parked or waiting vehicle never qualifies. An empty
    tank counts too when auqol_eject_outOfFuel is enabled. An aircraft counts once it is down: on the ground
    and either unable to fly (canMove false) or more than 80% damaged, so a healthy landed aircraft keeps
    its crew. An aircraft still falling does not count yet (see AUQOL_fnc_ejectEvaluate).

    Arguments:
    0: Vehicle <OBJECT>

    Return Value: <BOOL>
*/

params ["_vehicle"];

if (_vehicle isKindOf "Air") exitWith {
    auqol_eject_aircraft
    && {isTouchingGround _vehicle || {(getPosATL _vehicle select 2) < 2}}
    && {!canMove _vehicle || {damage _vehicle > 0.8}}
};

!canMove _vehicle || {auqol_eject_outOfFuel && {fuel _vehicle == 0}}
