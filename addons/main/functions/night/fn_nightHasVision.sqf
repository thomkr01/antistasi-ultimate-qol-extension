/*
    Author: AUQOL
    Says whether a unit can see in the dark: night vision or thermal in its head-mounted slot, in its
    helmet (built-in visors), in its binoculars or weapon optics, or in any optic of the vehicle it is in
    (gunner and commander sights, pilot cameras, static weapon sights). Read from config, so any faction,
    gear or vehicle mod works without a list. Each class is looked up once and cached.

    Arguments:
    0: Unit <OBJECT>

    Return Value: <BOOL>
*/

params ["_unit"];

// True when the config or a class below it (up to _depth levels) lists an NVG or thermal vision mode.
private _scan = {
    params ["_cfg", "_depth"];
    (getArray (_cfg >> "visionMode")) findIf { (toLowerANSI _x) in ["nvg", "ti"] } != -1
    || {_depth > 0 && {(configProperties [_cfg, "isClass _x", true]) findIf { [_x, _depth - 1] call _scan } != -1}}
};
private _check = {
    params ["_class", "_root", "_depth"];
    if (_class == "") exitWith { false };
    private _key = _root + ">" + _class;
    private _known = auqol_night_visionCache get _key;
    if (isNil "_known") then {
        _known = [configFile >> _root >> _class, _depth] call _scan;
        auqol_night_visionCache set [_key, _known];
    };
    _known
};

private _vehicle = objectParent _unit;
if (!isNull _vehicle && {[typeOf _vehicle, "CfgVehicles", 5] call _check}) exitWith { true };

// Item arrays are empty when the unit has no such weapon, so the optic slot is read with a default.
private _items = [hmd _unit, binocular _unit, secondaryWeapon _unit, primaryWeaponItems _unit param [2, ""],
    secondaryWeaponItems _unit param [2, ""], handgunItems _unit param [2, ""]];
_items append getArray (configFile >> "CfgWeapons" >> headgear _unit >> "subItems");
_items findIf { [_x, "CfgWeapons", 3] call _check } != -1
