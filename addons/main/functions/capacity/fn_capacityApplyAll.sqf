/*
    Author: AUQOL
    Re-applies the capacity settings to every connected player except headless clients (server, on
    settings ready and on a capacity setting change).

    Arguments: none
    Return Value: none
*/

if (!isServer) exitWith {};

{ [_x] call AUQOL_fnc_capacityApply } forEach (allPlayers - entities "HeadlessClient_F");
