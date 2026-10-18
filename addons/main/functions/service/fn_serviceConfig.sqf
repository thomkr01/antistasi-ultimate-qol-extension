/*
    Author: AUQOL
    Returns (and caches per class) which services a class provides according to its config. Only
    classes that declare a service in config are ever touched, so ordinary vehicles keep normal stock.
    ACE values follow ACE's own fallback: ace_refuel_fuelCargo defaults to transportFuel and
    ace_rearm_defaultSupply to transportAmmo. ACE jerry cans are portable consumables and excluded.

    Arguments:
    0: Class name <STRING>

    Return Value: [isSource, vanillaFuel, vanillaAmmo, vanillaRepair, aceFuelCargo, aceRearmSupply]
        <[BOOL, BOOL, BOOL, BOOL, NUMBER, NUMBER]>
*/

params [["_class", "", [""]]];

private _entry = auqol_service_cache get _class;
if (!isNil "_entry") exitWith {_entry};

private _cfg = configFile >> "CfgVehicles" >> _class;
private _transportFuel = getNumber (_cfg >> "transportFuel");
private _transportAmmo = getNumber (_cfg >> "transportAmmo");
private _aceFuel = [_cfg >> "ace_refuel_fuelCargo", "NUMBER", _transportFuel] call CBA_fnc_getConfigEntry;
private _aceAmmo = [_cfg >> "ace_rearm_defaultSupply", "NUMBER", _transportAmmo] call CBA_fnc_getConfigEntry;

_entry = if (!isClass _cfg || {_class isKindOf "Land_CanisterFuel_F"}) then {
    [false, false, false, false, 0, 0]
} else {
    private _vanilla = [_transportFuel > 0, _transportAmmo > 0, getNumber (_cfg >> "transportRepair") > 0];
    [(_vanilla findIf {_x} != -1) || _aceFuel > 0 || _aceAmmo > 0] + _vanilla + [_aceFuel, _aceAmmo]
};

auqol_service_cache set [_class, _entry];
_entry
