/*
    Author: AUQOL
    Applies the current service settings to one service object: vanilla cargo where the object is
    local, ACE refuel and rearm on the server (both ACE APIs are server-only).

    Arguments:
    0: Service object <OBJECT>

    Return Value: none
*/

params ["_object"];

if (!auqol_ready || {isNull _object} || {!alive _object}) exitWith {};

([typeOf _object] call AUQOL_fnc_serviceConfig) params ["_isSource", "_vanillaFuel", "_vanillaAmmo", "_vanillaRepair", "_aceFuel", "_aceAmmo"];
if (!_isSource) exitWith {};

if (local _object) then {
    if (_vanillaFuel) then { [_object, "fuel"] call AUQOL_fnc_serviceRefillLocal };
    if (_vanillaAmmo) then { [_object, "ammo"] call AUQOL_fnc_serviceRefillLocal };
    if (_vanillaRepair) then { [_object, "repair"] call AUQOL_fnc_serviceRefillLocal };
};

if (isServer && {!(_object getVariable ["auqol_service_exclude", false])}) then {
    if (_aceFuel > 0) then { [_object, auqol_service_fuel] call AUQOL_fnc_aceRefuelApply };
    if (_aceAmmo > 0) then { [_object, auqol_service_ammo] call AUQOL_fnc_aceRearmApply };
};
