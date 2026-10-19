/*
    Author: AUQOL
    Keeps fuel sources stored in the Antistasi Ultimate garage full (server, every 10 seconds).

    HR_GRG_fnc_refuelVehicleFromSources drains the stored fuel data of garaged fuel sources when a
    vehicle is pulled out, and drops a source from HR_GRG_Sources#1 once it is empty. This writes the
    stored value back to full in the same format the garage uses (vanilla: fraction of transportFuel
    at index 1; ACE: litres at index 2), re-registers emptied sources and broadcasts the change with
    the garage's own update functions. Ammo and repair sources are on/off in the garage and never
    deplete, so they are not touched. Does nothing when the garage is not present.

    Only the garage's source category is read (fuel, ammo and repair source vehicles, not the whole
    garage), each class's full value is cached, and nothing is written for a source that is already full.

    Arguments: none
    Return Value: none
*/

if (!isServer || {!auqol_service_fuel} || {!auqol_service_garageFuel}) exitWith {};
if (isNil "HR_GRG_Vehicles" || {isNil "HR_GRG_Sources"} || {isNil "HR_GRG_fnc_broadcastStateUpdate"} || {isNil "HR_GRG_fnc_declairSources"}) exitWith {};

// Index 6 is the garage's source category (HR_GRG_SOURCEINDEX).
private _sourceCategory = HR_GRG_Vehicles param [6, createHashMap];
if (!(_sourceCategory isEqualType createHashMap) || {count HR_GRG_Sources < 3}) exitWith {};

private _hasAce = missionNamespace getVariable ["A3A_hasAce", false];
private _fuelSources = HR_GRG_Sources select 1;
private _otherSources = (HR_GRG_Sources select 0) + (HR_GRG_Sources select 2);
private _registered = false;

{
    // Garage entry: [displayName, class, lockUID, checkedOut, stateData, lockName, customisation, lockTime]
    private _uid = _x;
    private _class = _y param [1, ""];
    private _fuelData = (_y param [4, []]) param [0, []];
    if (!(_fuelData isEqualType []) || {count _fuelData < 3} || {_uid in _otherSources}) then { continue };

    // Full value per class, looked up in config once and cached; a class that holds no fuel is skipped.
    private _full = auqol_garage_full getOrDefaultCall [_class, {
        private _cfg = configFile >> "CfgVehicles" >> _class;
        [parseNumber (getNumber (_cfg >> "transportFuel") > 0),
            [_cfg >> "ace_refuel_fuelCargo", "NUMBER", getNumber (_cfg >> "transportFuel")] call CBA_fnc_getConfigEntry] select _hasAce
    }, true];
    if (_full <= 0) then { continue };
    private _index = [1, 2] select _hasAce;

    if ((_fuelData select _index) < _full) then {
        _fuelData set [_index, _full];
        if !(_uid in _fuelSources) then {
            _fuelSources pushBack _uid;
            _registered = true;
        };
        [_uid, _fuelData, 0] call HR_GRG_fnc_broadcastStateUpdate;
        [format ["Garage fuel source %1 (%2) restored to full", _uid, _class], true] call AUQOL_fnc_log;
    };
} forEach _sourceCategory;

if (_registered) then { [1] call HR_GRG_fnc_declairSources };
