/*
    Author: AUQOL
    Says whether an object gets the loot-gathering action: Antistasi's rebel loot crate, or any vehicle
    (land, air or sea) that is not a static weapon.

    Arguments:
    0: Object <OBJECT>

    Return Value: 0 = no, 1 = vehicle, 2 = loot crate <NUMBER>
*/

params ["_object"];

private _crateClass = (missionNamespace getVariable ["A3A_faction_reb", createHashMap]) getOrDefault ["lootCrate", "A3AP_Box_Syndicate_Ammo_F"];
if (typeOf _object == _crateClass) exitWith {2};
// The class check runs for every object spawned on a client, so it is looked up once per class.
[0, 1] select (auqol_loot_vehicleCache getOrDefaultCall [typeOf _object, {
    (_object isKindOf "LandVehicle" || {_object isKindOf "Air"} || {_object isKindOf "Ship"}) && {!(_object isKindOf "StaticWeapon")}
}, true])
