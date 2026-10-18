/*
    Author: AUQOL
    One pass over existing objects when settings become ready or a service setting changes. Non-service
    classes are rejected by a cached lookup, so the pass is cheap; it is never run on a timer.

    Arguments: none
    Return Value: none
*/

{ [_x] call AUQOL_fnc_serviceApplyObject } forEach vehicles;
