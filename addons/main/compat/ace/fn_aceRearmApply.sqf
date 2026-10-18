/*
    Author: AUQOL
    Keeps an ACE rearm source stocked (server only). Only ACE's "limited ammo supply based on caliber"
    mode (ace_rearm_supply = 1) has a finite supply count:
    - mode 0 (unlimited, ACE default) is already infinite and is left alone;
    - mode 2 (magazine-specific supply) is a stockpile of loaded magazines, not a refillable count,
      and is left alone.
    ACE raises no event when supply is consumed, so sources are set to a very large count and topped
    up by the 30-second server check in AUQOL_fnc_settingsInitialized.

    Arguments:
    0: Ammo source <OBJECT>
    1: Infinite <BOOL>

    Return Value: none
*/

#define AUQOL_ACE_SUPPLY 1000000

params ["_source", "_infinite"];

if (!isServer || {!(missionNamespace getVariable ["ace_rearm_enabled", false])} || {(missionNamespace getVariable ["ace_rearm_supply", 0]) != 1}) exitWith {};
if (isNil "ace_rearm_fnc_getSupplyCount" || {isNil "ace_rearm_fnc_setSupplyCount"}) exitWith {
    if (isNil "auqol_aceRearmWarned") then {
        auqol_aceRearmWarned = true;
        ["WARNING: ACE rearm is enabled but ace_rearm_fnc_getSupplyCount/setSupplyCount were not found; ACE ammo sources are left unchanged."] call AUQOL_fnc_log;
    };
};
if (isNull _source || {!alive _source}) exitWith {};

private _cfg = configOf _source;
private _default = [_cfg >> "ace_rearm_defaultSupply", "NUMBER", getNumber (_cfg >> "transportAmmo")] call CBA_fnc_getConfigEntry;
if (_default <= 0) exitWith {};

if (_infinite) then {
    auqol_aceRearmSources pushBackUnique _source;
    if (([_source] call ace_rearm_fnc_getSupplyCount) < AUQOL_ACE_SUPPLY) then {
        [_source, AUQOL_ACE_SUPPLY] call ace_rearm_fnc_setSupplyCount;
        [format ["ACE ammo source %1 (%2) topped up", typeOf _source, _source], true] call AUQOL_fnc_log;
    };
} else {
    if !(_source in auqol_aceRearmSources) exitWith {};
    auqol_aceRearmSources deleteAt (auqol_aceRearmSources find _source);
    [_source, _default] call ace_rearm_fnc_setSupplyCount;
};
