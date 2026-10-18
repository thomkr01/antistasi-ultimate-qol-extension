/*
    Author: AUQOL
    Returns whether a land vehicle is genuinely unable to move. canMove reflects engine, wheel and track
    damage (it ignores fuel for land vehicles), so a parked or waiting vehicle never qualifies. An empty
    tank counts too when auqol_eject_outOfFuel is enabled.

    Arguments:
    0: Vehicle <OBJECT>

    Return Value: <BOOL>
*/

params ["_vehicle"];

!canMove _vehicle || {auqol_eject_outOfFuel && {fuel _vehicle == 0}}
