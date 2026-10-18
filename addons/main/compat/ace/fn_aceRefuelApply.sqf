/*
    Author: AUQOL
    Switches an ACE refuel source between ACE's built-in infinite mode and its normal finite capacity
    (server only, as ace_refuel_fnc_makeSource requires). Infinite mode is ACE's REFUEL_INFINITE_FUEL
    (-10) capacity, which ace_refuel_fnc_refuel already skips when draining the source. Before
    switching, the tank is set full so Antistasi's garage and refund code, which read
    ace_refuel_currentFuelCargo, see a full source. The source's own engine fuel is not changed.

    Arguments:
    0: Fuel source <OBJECT>
    1: Infinite <BOOL>

    Return Value: none
*/

#define REFUEL_INFINITE_FUEL -10

params ["_source", "_infinite"];

if (!isServer || {!(missionNamespace getVariable ["ace_refuel_enabled", false])}) exitWith {};
if (isNil "ace_refuel_fnc_makeSource" || {isNil "ace_refuel_fnc_setFuel"}) exitWith {
    if (isNil "auqol_aceRefuelWarned") then {
        auqol_aceRefuelWarned = true;
        ["WARNING: ACE refuel is enabled but ace_refuel_fnc_makeSource/setFuel were not found; ACE fuel sources are left unchanged."] call AUQOL_fnc_log;
    };
};
if (_source getVariable ["ace_refuel_jerryCan", false]) exitWith {};

private _cfg = configOf _source;
private _cargo = [_cfg >> "ace_refuel_fuelCargo", "NUMBER", getNumber (_cfg >> "transportFuel")] call CBA_fnc_getConfigEntry;
if (_cargo <= 0) exitWith {}; // -10 is already infinite in config, 0 and -1 are not sources

private _isOurs = _source getVariable ["auqol_aceInfiniteFuel", false];
private _capacity = _source getVariable ["ace_refuel_capacity", _cargo];

if (_infinite) then {
    // Infinite already, or disabled on purpose by the mission (REFUEL_DISABLED_FUEL, -1).
    if (_capacity == REFUEL_INFINITE_FUEL || _capacity < 0) exitWith {};
    [_source, _capacity max _cargo] call ace_refuel_fnc_setFuel;
    [_source, REFUEL_INFINITE_FUEL] call ace_refuel_fnc_makeSource;
    _source setVariable ["auqol_aceInfiniteFuel", true, true];
    [format ["ACE fuel source %1 (%2) set to infinite", typeOf _source, _source], true] call AUQOL_fnc_log;
} else {
    if (!_isOurs) exitWith {};
    [_source, _cargo] call ace_refuel_fnc_makeSource; // restores the config capacity, full
    _source setVariable ["auqol_aceInfiniteFuel", nil, true];
    [format ["ACE fuel source %1 (%2) restored to %3 l", typeOf _source, _source, _cargo], true] call AUQOL_fnc_log;
};
