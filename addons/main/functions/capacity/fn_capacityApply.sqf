/*
    Author: AUQOL
    Server side of the carrying-capacity feature ("auqol_capacity_apply" event). Sets each worn
    container's capacity to its config capacity (getContainerMaxLoad of the worn class) times the
    multiplier, and puts released containers back to their config capacity. Only containers AUQOL
    changed are restored. The multiplier comes from the server's own setting, never from the client,
    and is clamped to 1..1000.

    The engine's total soldier load limit (CfgInventoryGlobalVariable >> maxSoldierLoad) is static
    config and cannot be changed per unit by script; see the optional auqol_maxload addon.

    Arguments:
    0: Player unit <OBJECT>
    1: Released containers <ARRAY of OBJECT> (default: [])

    Return Value: none
*/

params [["_unit", objNull, [objNull]], ["_released", [], [[]]]];

if (!isServer) exitWith {};

private _restore = {
    params ["_container"];
    private _base = _container getVariable "auqol_capacity_base";
    if (isNil "_base") exitWith {};
    _container setMaxLoad _base;
    _container setVariable ["auqol_capacity_base", nil, true];
};

{
    if (_x isEqualType objNull && {!isNull _x}) then { [_x] call _restore };
} forEach _released;

if (isNull _unit || {!isPlayer _unit}) exitWith {};

private _multiplier = if (auqol_capacity_enabled) then { round ((auqol_capacity_multiplier max 1) min 1000) } else { 1 };

{
    _x params ["_container", "_class"];
    if (isNull _container) then { continue };

    if (_multiplier == 1) then {
        [_container] call _restore;
        continue;
    };

    private _base = getContainerMaxLoad _class;
    if (_base <= 0) then { continue };
    private _target = _base * _multiplier;
    if (maxLoad _container != _target) then {
        _container setVariable ["auqol_capacity_base", _base, true];
        _container setMaxLoad _target;
        [format ["Capacity of %1 (%2) set to %3 (x%4) for %5", _class, _container, _target, _multiplier, name _unit], true] call AUQOL_fnc_log;
    };
} forEach [
    [uniformContainer _unit, uniform _unit],
    [vestContainer _unit, vest _unit],
    [backpackContainer _unit, backpack _unit]
];
