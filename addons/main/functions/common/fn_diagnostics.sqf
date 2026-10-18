/*
    Author: AUQOL
    Reports which integrations and features are active on this machine. Logged once when settings are
    ready; can also be run from the debug console, which additionally prints the lines to system chat.

    Arguments: none

    Return Value: Report lines <ARRAY of STRING>

    Example: call AUQOL_fnc_diagnostics;
*/

private _isLoaded = { isClass (configFile >> "CfgPatches" >> _this) };
private _onOff = { ["off", "ON"] select _this };
private _setting = { missionNamespace getVariable [_this, false] };

private _aceRefuel = "ace_refuel_enabled" call _setting;
private _aceRearm = "ace_rearm_enabled" call _setting;
private _aceRepair = "ace_repair_enabled" call _setting;
private _aceFatigue = "ace_advanced_fatigue_enabled" call _setting;
private _aceSway = "ace_common_enableSway" call _setting;
private _rearmMode = missionNamespace getVariable ["ace_rearm_supply", -1];

private _lines = [
    format ["Version %1 | server=%2 interface=%3 dedicated=%4", getText (configFile >> "CfgPatches" >> "auqol_main" >> "versionStr"), isServer, hasInterface, isDedicated],
    format ["Detected: Antistasi=%1 (garage data=%2) ACE=%3 RHS=%4 CUP=%5",
        "A3A_core" call _isLoaded, !isNil "HR_GRG_Vehicles", "ace_main" call _isLoaded,
        ("rhs_main_loadorder" call _isLoaded) || {"rhsusf_main_loadorder" call _isLoaded}, "CUP_Vehicles_LoadOrder" call _isLoaded],
    format ["Ejection: %1 (out of fuel counts: %2)", ("auqol_eject_enabled" call _setting) call _onOff, ("auqol_eject_outOfFuel" call _setting) call _onOff],
    format ["Fuel service: %1 | handled by %2 | garage sources: %3",
        ("auqol_service_fuel" call _setting) call _onOff,
        ["vanilla fuel cargo", "ACE refuel infinite source"] select _aceRefuel,
        (("auqol_service_garageFuel" call _setting) && {"auqol_service_fuel" call _setting} && {!isNil "HR_GRG_Vehicles"}) call _onOff],
    format ["Ammo service: %1 | handled by %2",
        ("auqol_service_ammo" call _setting) call _onOff,
        if (_aceRearm) then {
            ["ACE unlimited supply (already infinite, untouched)", "ACE limited supply top-up", "ACE magazine supply (untouched)"] param [_rearmMode, "ACE (unknown supply mode)"]
        } else {"vanilla ammo cargo"}],
    format ["Repair service: %1 | handled by %2",
        ("auqol_service_repair" call _setting) call _onOff,
        ["vanilla repair cargo", "ACE repair (no stock, untouched)"] select _aceRepair],
    format ["Total carry limit (maxSoldierLoad): %1", getNumber (configFile >> "CfgInventoryGlobalVariable" >> "maxSoldierLoad")],
    format ["Loot from vehicles: %1, radius %2 m, enemy check %3 m (Antistasi loot function found: %4)",
        ("auqol_loot_enabled" call _setting) call _onOff, missionNamespace getVariable ["auqol_loot_radius", 0],
        missionNamespace getVariable ["auqol_loot_enemyRadius", 0], !isNil "SCRT_fnc_loot_gatherLoot"],
    format ["Withstand cooldown: %1, %2 s", ("auqol_withstand_enabled" call _setting) call _onOff, missionNamespace getVariable ["A3A_selfReviveTimeout", 300]],
    format ["Copy from user button: %1 (Antistasi loadout editor found: %2)", ("auqol_loadout_copyFromUser" call _setting) call _onOff, !isNil "SCRT_fnc_arsenal_loadoutArsenal"],
    format ["AI stuck recovery: %1, scope %2, timeout %3 s, steps refresh %4 regroup %5 hop %6 teleport %7",
        ("auqol_stuck_enabled" call _setting) call _onOff,
        ["your squad", "near players", "all friendly AI"] param [missionNamespace getVariable ["auqol_stuck_scope", 0], "?"],
        missionNamespace getVariable ["auqol_stuck_timeout", 0],
        ("auqol_stuck_refreshOrders" call _setting) call _onOff, ("auqol_stuck_regroup" call _setting) call _onOff,
        ("auqol_stuck_reposition" call _setting) call _onOff, ("auqol_stuck_teleport" call _setting) call _onOff]
];

if (isServer) then {
    _lines pushBack format ["ACE rearm sources topped up: %1", count auqol_aceRearmSources];
};

if (hasInterface) then {
    _lines pushBack format ["Player: no sway %1 (%2) | unlimited stamina %3 (%4) | weightless %5 | squad AI too %6",
        ("auqol_player_noSway" call _setting) call _onOff, ["vanilla aim coef", "ACE sway factor"] select _aceSway,
        ("auqol_player_unlimitedStamina" call _setting) call _onOff, ["vanilla stamina", "ACE Advanced Fatigue"] select _aceFatigue,
        ("auqol_player_weightless" call _setting) call _onOff, ("auqol_player_squad" call _setting) call _onOff];
};

{ [_x] call AUQOL_fnc_log } forEach _lines;
if (hasInterface && {!isNull findDisplay 49 || {!isNull findDisplay 312}}) then {
    { systemChat ("[AUQOL] " + _x) } forEach _lines;
};

_lines
