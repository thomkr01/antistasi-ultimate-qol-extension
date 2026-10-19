/*
    Author: AUQOL
    "Copy from user" in Antistasi's rebel loadout editor (client). Takes the loadout the player wore
    when the editor opened (Antistasi keeps it in localNamespace "commanderLoadout"), drops every item
    the arsenal does not have unlimited (-1, shown as the infinity sign; AUQOL_fnc_loadoutFilter), and loads the rest into the
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

([_own, _unlocked] call AUQOL_fnc_loadoutFilter) params ["_copy", "_skipped"];

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
