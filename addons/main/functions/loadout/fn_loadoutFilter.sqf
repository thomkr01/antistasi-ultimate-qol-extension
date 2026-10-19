/*
    Author: AUQOL
    Removes every item that is not unlocked from a getUnitLoadout array, for "Copy from user"
    (AUQOL_fnc_loadoutCopyFromUser). Weapons are checked as their base class, then each attachment and
    loaded magazine on its own, both in the weapon slots and for weapons stored in the uniform, vest or
    backpack. Kept items keep their counts and ammo, and the layout of the array stays the same.
    No game state is read or changed, so tests/ingame/loadout_test.sqf can call it with made-up data.

    Arguments:
    0: Loadout, as getUnitLoadout returns it <ARRAY> (not changed)
    1: Unlocked classes, lower case <HASHMAP>

    Return Value: [filtered loadout <ARRAY>, classes left out <ARRAY>]
*/

params ["_loadout", "_unlocked"];

private _skipped = [];
private _ok = {
    params ["_class"];
    if (_class == "" || {toLower _class in _unlocked}) exitWith { true };
    _skipped pushBackUnique _class;
    false
};

private _copy = +_loadout;

// Weapon array: [class, muzzle, pointer, optic, [mag, ammo], [mag, ammo], bipod]. Checked the same way in
// a weapon slot and inside a container, part by part, so a locked attachment or magazine never rides
// along on an unlocked weapon. Returns false when the weapon itself is locked; ammo counts are kept.
private _filterWeapon = {
    params ["_weapon"];
    // Arsenal lists base weapons; a preset class with built-in attachments counts as its base.
    private _base = [_weapon select 0] call BIS_fnc_baseWeapon;
    if !([_base] call _ok) exitWith { false };
    _weapon set [0, _base];
    { if !([_weapon select _x] call _ok) then { _weapon set [_x, ""] } } forEach [1, 2, 3, 6];
    {
        private _mag = _weapon select _x;
        if (_mag isNotEqualTo [] && {!([_mag select 0] call _ok)}) then { _weapon set [_x, []] };
    } forEach [4, 5];
    true
};

// Weapons and binoculars
{
    private _weapon = _copy select _x;
    if (_weapon isEqualTo []) then { continue };
    if !([_weapon] call _filterWeapon) then { _copy set [_x, nil] };
} forEach [0, 1, 2, 8];

// Uniform, vest, backpack: [class, [[item, count], [mag, count, ammo], [[weapon...], count]]]
{
    private _container = _copy select _x;
    if (_container isEqualTo []) then { continue };
    if !([_container select 0] call _ok) then { _copy set [_x, nil]; continue };
    _container set [1, (_container select 1) select {
        private _class = _x select 0;
        if (_class isEqualType []) then { [_class] call _filterWeapon } else { [_class] call _ok }
    }];
} forEach [3, 4, 5];

// Headgear and facewear
{ if !([_copy select _x] call _ok) then { _copy set [_x, nil] } } forEach [6, 7];

// Map, GPS, radio, compass, watch, NVG
private _assigned = _copy select 9;
{ if !([_x] call _ok) then { _assigned set [_forEachIndex, nil] } } forEach +_assigned;

[_copy, _skipped]
