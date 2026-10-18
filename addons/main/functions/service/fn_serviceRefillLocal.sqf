/*
    Author: AUQOL
    Refills one vanilla service cargo to full on a local service object ("auqol_service_refill" event
    handler and direct calls). setFuelCargo, setAmmoCargo and setRepairCargo only change the cargo the
    object hands out; the object's own engine fuel and ammunition are untouched.

    Arguments:
    0: Service object <OBJECT>
    1: Service kind, "fuel", "ammo" or "repair" <STRING>

    Return Value: none
*/

params ["_source", "_kind"];

if (isNull _source || {!local _source} || {!alive _source} || {_source getVariable ["auqol_service_exclude", false]}) exitWith {};
if !([_kind] call AUQOL_fnc_serviceVanillaActive) exitWith {};

switch (_kind) do {
    case "fuel": { if (getFuelCargo _source < 1) then { _source setFuelCargo 1 } };
    case "ammo": { if (getAmmoCargo _source < 1) then { _source setAmmoCargo 1 } };
    case "repair": { if (getRepairCargo _source < 1) then { _source setRepairCargo 1 } };
};

[format ["Refilled %1 cargo of %2 (%3)", _kind, typeOf _source, _source], true] call AUQOL_fnc_log;
