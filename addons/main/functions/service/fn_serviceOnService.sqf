/*
    Author: AUQOL
    Vanilla "Service" mission event handler. Fires at intervals while a vehicle is being serviced, so the
    service object's cargo is put back to full as it is used instead of polling it. The object may be
    remote; the refill is then sent to its owner, at most once every 2 seconds per object.

    Arguments:
    0: Service object <OBJECT>
    1: Serviced vehicle <OBJECT>
    2: Service type, 0 minor repair, 1 repair, 2 refuel, 3 rearm <NUMBER>

    Return Value: false, so the default on-screen service message is still shown <BOOL>
*/

params ["_source", "", "_type"];

private _kind = ["repair", "repair", "fuel", "ammo"] param [_type, ""];
if (!auqol_ready || {isNull _source} || {!([typeOf _source] call AUQOL_fnc_serviceConfig select 0)}) exitWith {false};
if !([_kind] call AUQOL_fnc_serviceVanillaActive) exitWith {false};

if (local _source) then {
    [_source, _kind] call AUQOL_fnc_serviceRefillLocal;
} else {
    private _cargo = switch (_kind) do {
        case "fuel": { getFuelCargo _source };
        case "ammo": { getAmmoCargo _source };
        default { getRepairCargo _source };
    };
    if (_cargo < 1 && {diag_tickTime > (_source getVariable ["auqol_service_nextRequest", 0])}) then {
        _source setVariable ["auqol_service_nextRequest", diag_tickTime + 2];
        ["auqol_service_refill", [_source, _kind], _source] call CBA_fnc_targetEvent;
    };
};

false
