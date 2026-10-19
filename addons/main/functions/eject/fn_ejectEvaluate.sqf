/*
    Author: AUQOL
    Checks a vehicle after a damage, fuel or boarding event and, if it is immobilized with eligible
    enemy crew, schedules the ejection once the hull has stopped rolling. A pending flag stops repeated
    events from stacking, and a vehicle that keeps moving is retried at most three times. Also the
    "auqol_eject_evaluate" event handler, used to hand a pending check to a vehicle's new owner.

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

// The flag is local to this machine. If the vehicle changes owner during the wait, the wait ends early and
// the check is handed to the new owner, which has no flag of its own and would otherwise only act on the
// next damage, fuel or boarding event. AUQOL_fnc_ejectCrew rechecks the setting and the crew.
[
    { params ["_vehicle"]; !alive _vehicle || {!local _vehicle} || {abs speed _vehicle < 3} },
    {
        params ["_vehicle", "_retry"];
        _vehicle setVariable ["auqol_eject_pending", nil];
        if (alive _vehicle && {!local _vehicle}) exitWith { ["auqol_eject_evaluate", [_vehicle, _retry], _vehicle] call CBA_fnc_targetEvent };
        [_vehicle] call AUQOL_fnc_ejectCrew;
    },
    [_vehicle, _retry],
    8,
    {
        params ["_vehicle", "_retry"];
        _vehicle setVariable ["auqol_eject_pending", nil];
        if (_retry >= 3 || {!alive _vehicle}) exitWith {};
        if (local _vehicle) then { [_vehicle, _retry + 1] call AUQOL_fnc_ejectEvaluate } else {
            ["auqol_eject_evaluate", [_vehicle, _retry + 1], _vehicle] call CBA_fnc_targetEvent;
        };
    }
] call CBA_fnc_waitUntilAndExecute;
