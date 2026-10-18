/*
    Author: AUQOL
    Server. Empties enemy item caches (the faction "ammobox" crates Antistasi spawns at outposts, bases
    and airports) within 30 m of the looting vehicle or crate into a weapon holder next to it. Antistasi's
    gather function then picks the holder up like any dropped gear, so its unlocked-item and money rules
    apply to the cache contents too. The emptied box is deleted; Antistasi's zone despawn only touches
    its caches while they are alive, so a deleted one is simply skipped.

    Arguments:
    0: Vehicle or loot crate <OBJECT>

    Return Value: Number of caches emptied <NUMBER>
*/

params ["_object"];

private _classes = [];
{
    private _class = (missionNamespace getVariable [_x, createHashMap]) getOrDefault ["ammobox", ""];
    if (_class != "") then { _classes pushBackUnique _class };
} forEach ["A3A_faction_occ", "A3A_faction_inv", "A3A_faction_riv"];
if (_classes isEqualTo []) exitWith {0};

private _rebelBox = missionNamespace getVariable ["boxX", objNull];
private _caches = (nearestObjects [_object, _classes, 30]) select {
    alive _x && _x != _object && _x != _rebelBox
    && {isNil { _x getVariable "A3A_canGarage" }}      // rebel-owned utility items
    && {(magazineCargo _x + itemCargo _x + weaponCargo _x + backpackCargo _x) isNotEqualTo []}
};
if (_caches isEqualTo []) exitWith {0};

private _holder = createVehicle ["GroundWeaponHolder", getPosATL _object, [], 0, "CAN_COLLIDE"];
{
    private _cache = _x;
    { _holder addMagazineAmmoCargo [_x select 0, 1, _x select 1] } forEach magazinesAmmoCargo _cache;
    { _holder addWeaponWithAttachmentsCargoGlobal [_x, 1] } forEach weaponsItemsCargo _cache;
    { _holder addItemCargoGlobal [_x, 1] } forEach itemCargo _cache;
    { _holder addBackpackCargoGlobal [_x, 1] } forEach backpackCargo _cache;
    deleteVehicle _cache;
} forEach _caches;

[format ["Emptied %1 cache(s) near %2 for looting", count _caches, typeOf _object], true] call AUQOL_fnc_log;
count _caches
