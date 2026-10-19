/*
    Author: AUQOL
    Server handler for the loot action, sent by AUQOL_fnc_lootAddAction with remoteExecCall. Runs
    Antistasi's own SCRT_fnc_loot_gatherLoot, the function the loot crate uses, so enemy check, cooldown,
    unlocked-item rules and money split are identical.
    With the feature on, the gather radius is auqol_loot_radius and the enemies-nearby check uses its own
    auqol_loot_enemyRadius around the object; passing the position makes Antistasi skip its own check,
    which uses the gather radius. With it off, the crate is Antistasi's call with lootCrateDistance.

    The request is checked before anything is moved or deleted: it must come from the machine that owns
    the caller (remoteExecutedOwner; the host player is local), the caller must be a living player on
    foot within 10 m of the object (the action allows 5 m, the rest is lag), and the object must still
    carry the action. A second request for the same object within 10 s is refused here, because
    Antistasi only records its cooldown once the spawned gather starts.

    Arguments:
    0: Vehicle or loot crate <OBJECT>
    1: Player who held the action <OBJECT>

    Return Value: none
*/

params [["_object", objNull, [objNull]], ["_caller", objNull, [objNull]]];

if (!isServer || {!alive _object} || {isNil "SCRT_fnc_loot_gatherLoot"}) exitWith {};

if !(alive _caller && {isPlayer _caller} && {isNull objectParent _caller} && {_caller distance _object < 10}
    && {local _caller || {isRemoteExecuted && {remoteExecutedOwner == owner _caller}}}) exitWith {
    [format ["Refused loot request for %1 from %2 (owner %3)", typeOf _object, name _caller, remoteExecutedOwner], true] call AUQOL_fnc_log;
};

private _kind = [_object] call AUQOL_fnc_lootIsTarget;
if (_kind == 0 || {_kind == 1 && {!auqol_loot_enabled}}) exitWith {};

if (serverTime - (_object getVariable ["auqol_lootRequested", -10]) < 10) exitWith {
    ["auqol_loot_message", ["STR_antistasi_actions_looter_cooldown_text"], _caller] call CBA_fnc_targetEvent;
};

if (!auqol_loot_enabled) exitWith {
    _object setVariable ["auqol_lootRequested", serverTime];
    [_object, missionNamespace getVariable ["lootCrateDistance", 50]] spawn SCRT_fnc_loot_gatherLoot;
};

private _radius = 10 max round auqol_loot_radius min 2000;
private _enemyRadius = 10 max round auqol_loot_enemyRadius min 2000;

if ([getPosATL _object, _enemyRadius] call A3A_fnc_enemyNearCheck) exitWith {
    {
        ["auqol_loot_message", ["STR_antistasi_actions_looter_enemies_nearby"], _x] call CBA_fnc_targetEvent;
    } forEach ([_radius, _object] call SCRT_fnc_common_getNearPlayers);
};

// Antistasi's own 10 s cooldown, checked here as well so caches are not emptied for a run it will refuse.
if (serverTime - (_object getVariable ["lastLooted", -10]) < 10) exitWith {
    ["auqol_loot_message", ["STR_antistasi_actions_looter_cooldown_text"], _caller] call CBA_fnc_targetEvent;
};

_object setVariable ["auqol_lootRequested", serverTime];
if (auqol_loot_caches) then { [_object] call AUQOL_fnc_lootCaches };

[format ["Gathering loot into %1 for %2 (radius %3, enemy check %4)", typeOf _object, name _caller, _radius, _enemyRadius], true] call AUQOL_fnc_log;
[_object, _radius, getPosATL _object] spawn SCRT_fnc_loot_gatherLoot;
