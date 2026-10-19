// Debug console, "Local exec". Regression test for "Copy from user" (AUQOL_fnc_loadoutFilter) with made-up
// unlock data, so it changes nothing and needs no Antistasi. Locked attachments and magazines must be
// removed from weapons in the weapon slots and from weapons stored in the uniform, vest and backpack.
private _unlocked = createHashMap;
{ _unlocked set [toLower _x, true] } forEach ["arifle_MX_F", "optic_Hamr", "30Rnd_65x39_caseless_mag",
    "U_B_CombatUniform_mcam", "V_PlateCarrier1_rgr", "B_AssaultPack_mcamo", "FirstAidKit", "ItemMap"];

private _rifle = ["arifle_MX_F", "muzzle_snds_H", "acc_pointer_IR", "optic_Hamr", ["30Rnd_65x39_caseless_mag_Tracer", 30], [], ""];
private _clean = ["arifle_MX_F", "", "", "optic_Hamr", [], [], ""];
private _loaded = ["arifle_MX_F", "", "", "optic_Hamr", ["30Rnd_65x39_caseless_mag", 17], [], ""];
private _locked = ["srifle_EBR_F", "", "", "", [], [], ""];
private _loadout = [
    _rifle, [], [],
    ["U_B_CombatUniform_mcam", [["FirstAidKit", 2], ["30Rnd_65x39_caseless_mag", 3, 30], [_rifle, 1], [_locked, 1]]],
    ["V_PlateCarrier1_rgr", [[_loaded, 2], ["30Rnd_65x39_caseless_mag_Tracer", 2, 30]]],
    ["B_AssaultPack_mcamo", [[_rifle, 1], ["muzzle_snds_H", 1]]],
    "", "", [], ["ItemMap", "", "", "", "", ""]
];
private _before = +_loadout;

([_loadout, _unlocked] call AUQOL_fnc_loadoutFilter) params ["_copy", "_skipped"];

private _checks = [
    ["primary weapon loses locked muzzle, pointer and magazine", _copy select 0, _clean],
    ["uniform keeps items, magazine ammo and cleaned weapon, drops locked weapon", (_copy select 3) select 1,
        [["FirstAidKit", 2], ["30Rnd_65x39_caseless_mag", 3, 30], [_clean, 1]]],
    ["vest keeps unlocked loaded magazine and weapon count, drops locked magazines", (_copy select 4) select 1, [[_loaded, 2]]],
    ["backpack weapon cleaned, locked attachment item dropped", (_copy select 5) select 1, [[_clean, 1]]],
    ["input loadout unchanged", _loadout, _before],
    ["skipped lists every locked class once", count _skipped, 4]
];
{
    _x params ["_name", "_got", "_want"];
    private _pass = _got isEqualTo _want;
    private _line = format ["[AUQOL test] %1 %2%3", ["FAIL", "PASS"] select _pass, _name, [format [" (got %1)", _got], ""] select _pass];
    systemChat _line; diag_log text _line;
} forEach _checks;
