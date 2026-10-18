/*
    Author: AUQOL
    Checks a vehicle after a damage, fuel or boarding event and, if it is immobilized with eligible
    enemy crew, schedules the ejection once the hull has stopped rolling. A pending flag stops repeated
    events from stacking, and a vehicle that keeps moving is retried at most three times.

    Arguments:
    0: Vehicle <OBJECT>
    1: Retry count <NUMBER> (default: 0)

    Return Value: none
*/

params ["_vehicle", ["_retry", 0]];

if (!local _vehicle || {!auqol_ready} || {!auqol_eject_enabled}) exitWith {};
if (!alive _vehicle || {unitIsUAV _vehicle} || {_vehicle getVariable ["auqol_noEject", false]}) exitWith {};
if (_vehicle getVariable ["auqol_eject_pending", false]) exitWith {};
if !([_vehicle] call AUQOL_fnc_ejectIsImmobilized) exitWith {};
if ((crew _vehicle) findIf { [_x] call AUQOL_fnc_ejectIsEligible } == -1) exitWith {};

_vehicle setVariable ["auqol_eject_pending", true];

[
    { params ["_vehicle"]; !alive _vehicle || {abs speed _vehicle < 3} },
    {
        params ["_vehicle"];
        _vehicle setVariable ["auqol_eject_pending", nil];
        [_vehicle] call AUQOL_fnc_ejectCrew;
    },
    [_vehicle, _retry],
    8,
    {
        params ["_vehicle", "_retry"];
        _vehicle setVariable ["auqol_eject_pending", nil];
        if (_retry < 3) then { [_vehicle, _retry + 1] call AUQOL_fnc_ejectEvaluate };
    }
] call CBA_fnc_waitUntilAndExecute;
