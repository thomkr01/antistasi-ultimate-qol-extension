/*
    Author: AUQOL
    "Copy from user" in Antistasi's rebel loadout editor (client). Takes the loadout the player wore
    when the editor opened (Antistasi keeps it in localNamespace "commanderLoadout"), drops every item
    the arsenal does not have unlimited (-1, shown as the infinity sign), and loads the rest into the
    editor through Antistasi's own "applyInitialLoadout" step. That step switches on the slot override
    for every slot the loadout fills, so recruits get exactly those items. Slots whose item is not
    unlocked are left unset, which Antistasi fills at random as usual.
    Nothing is saved: the player presses Antistasi's Save button to keep it.

    Arguments:
    0: Arsenal display <DISPLAY>

    Return Value: none
*/

params ["_display"];

private _key = missionNamespace getVariable "currentRebelLoadout";
private _own = localNamespace getVariable "commanderLoadout";
if (!hasInterface || {isNil "_key"} || {isNil "_own"} || {isNil "jna_dataList"}) exitWith {};

private _unlocked = createHashMap;
{
    { if ((_x select 1) == -1) then { _unlocked set [toLower (_x select 0), true] } } forEach _x;
} forEach jna_dataList;

private _skipped = [];
private _ok = {
    params ["_class"];
    if (_class == "" || {toLower _class in _unlocked}) exitWith { true };
    _skipped pushBackUnique _class;
    false
};

private _copy = +_own;

// Weapons and binoculars: [class, muzzle, pointer, optic, [mag, ammo], [mag, ammo], bipod]
{
    private _weapon = _copy select _x;
    if (_weapon isEqualTo []) then { continue };
    // Arsenal lists base weapons; a preset class with built-in attachments counts as its base.
    private _base = [_weapon select 0] call BIS_fnc_baseWeapon;
    if !([_base] call _ok) then { _copy set [_x, nil]; continue };
    _weapon set [0, _base];
    { if !([_weapon select _x] call _ok) then { _weapon set [_x, ""] } } forEach [1, 2, 3, 6];
    {
        private _mag = _weapon select _x;
        if (_mag isNotEqualTo [] && {!([_mag select 0] call _ok)}) then { _weapon set [_x, []] };
    } forEach [4, 5];
} forEach [0, 1, 2, 8];

// Uniform, vest, backpack: [class, [[item, count], [mag, count, ammo], [[weapon...], count]]]
{
    private _container = _copy select _x;
    if (_container isEqualTo []) then { continue };
    if !([_container select 0] call _ok) then { _copy set [_x, nil]; continue };
    _container set [1, (_container select 1) select {
        private _class = _x select 0;
        if (_class isEqualType []) then { _class = _class select 0 };
        [_class] call _ok
    }];
} forEach [3, 4, 5];

// Headgear and facewear
{ if !([_copy select _x] call _ok) then { _copy set [_x, nil] } } forEach [6, 7];

// Map, GPS, radio, compass, watch, NVG
private _assigned = _copy select 9;
{ if !([_x] call _ok) then { _assigned set [_forEachIndex, nil] } } forEach +_assigned;

// applyInitialLoadout reads the role from rebelLoadouts and only switches overrides on, so clear them
// first and put the stored loadout back right after: nothing changes until the player saves.
{
    ["OverrideTab", [_display displayCtrl (ctrlIDC _x + 30), false]] call SCRT_fnc_arsenal_loadoutArsenal;
} forEach (allControls _display select { _x getVariable ["OverrideTab", false] });

private _stored = rebelLoadouts get _key;
rebelLoadouts set [_key, _copy];
["applyInitialLoadout"] call SCRT_fnc_arsenal_loadoutArsenal; // uses _display from this scope
if (isNil "_stored") then { rebelLoadouts deleteAt _key } else { rebelLoadouts set [_key, _stored] };
localNamespace setVariable ["commanderLoadout", _own]; // applyInitialLoadout overwrote it with the editor loadout

playSound "A3AP_UiSuccess";
if (_skipped isNotEqualTo []) then {
    systemChat format ["[AUQOL] Copied your loadout. Not unlocked, so left to Antistasi: %1", _skipped joinString ", "];
} else {
    systemChat "[AUQOL] Copied your loadout. Press Save to keep it.";
};
