/*
    Author: AUQOL
    Runs once on each machine when CBA settings are final. Starts the few bounded timers the mod uses
    and applies every feature to objects and players that already exist.

    Arguments: none
    Return Value: none
*/

if (auqol_ready) exitWith {};
auqol_ready = true;

call AUQOL_fnc_serviceApplyAll;
call AUQOL_fnc_withstandApply;

if (isServer) then {
    // Antistasi garage fuel sources only drain when a vehicle is pulled out, so a slow check is enough.
    [{ call AUQOL_fnc_serviceGarageRestore }, 10] call CBA_fnc_addPerFrameHandler;

    // ACE limited rearm has no consumption event; sources start at a very large supply and are topped up here.
    [{
        auqol_aceRearmSources = auqol_aceRearmSources select { !isNull _x };
        { [_x, auqol_service_ammo] call AUQOL_fnc_aceRearmApply } forEach +auqol_aceRearmSources; // copy: disabling removes entries
    }, 30] call CBA_fnc_addPerFrameHandler;
};

// Faster AI reactions run on every machine for its own AI, so garrisons on the server or a headless
// client are covered as well as each player's squad. New units and skills Antistasi sets after spawn
// are picked up within 5 s; the pass only writes skills that are below the floor.
[{ call AUQOL_fnc_squadReactApply }, 5] call CBA_fnc_addPerFrameHandler;

// AI stuck checks run on every machine (server, clients, headless clients) for the AI local to it.
// No engine event reports "no progress", so this polls; the pass returns at once when the feature is off.
[{ call AUQOL_fnc_stuckMonitor }, 5] call CBA_fnc_addPerFrameHandler;

if (hasInterface) then {
    call AUQOL_fnc_aceRegisterFactors;

    // Player perks follow the player's unit, loadout and group, and recruits joining the group
    // (AUQOL_fnc_squadGroupHooks). Antistasi re-applies role traits (loadCoef) shortly after respawn
    // without an event, so a unit change re-applies again 3 s later. The 15 s pass is the fallback for
    // anything else; it is three cheap getters per unit and only writes when a value drifted.
    ["unit", {
        call AUQOL_fnc_playerApply;
        [{ call AUQOL_fnc_playerApply }, [], 3] call CBA_fnc_waitAndExecute;
    }, true] call CBA_fnc_addPlayerEventHandler;
    ["loadout", { call AUQOL_fnc_playerApply }] call CBA_fnc_addPlayerEventHandler;
    ["group", { call AUQOL_fnc_squadGroupHooks; call AUQOL_fnc_playerApply; call AUQOL_fnc_squadSelfTreat }, true] call CBA_fnc_addPlayerEventHandler;
    // Self-treat runs 3 s after a hit (its "Dammaged" hook); the 15 s pass also catches damage set
    // without a hit, such as the 0.25 Antistasi's revive leaves.
    [{ call AUQOL_fnc_playerApply; call AUQOL_fnc_squadSelfTreat }, 15] call CBA_fnc_addPerFrameHandler;

    // The engine's own Reveal target key (T by default); the handler checks auqol_squad_revealKey.
    addUserActionEventHandler ["revealTarget", "Activate", { call AUQOL_fnc_squadRevealTarget }];

    // Antistasi moves its vehicle markers once a minute; new markers arrive through MarkerCreated, and the
    // 1 s pass only moves tracked markers whose vehicle moved. Returns at once when the feature is off.
    addMissionEventHandler ["MarkerCreated", {
        params ["_marker"];
        if (auqol_map_liveVehicles) then { auqol_map_pending set [_marker, time] };
    }];
    addMissionEventHandler ["MarkerDeleted", {
        params ["_marker"];
        auqol_map_pending deleteAt _marker;
        auqol_map_tracked deleteAt _marker;
        auqol_map_ignored deleteAt _marker;
    }];
    [{ call AUQOL_fnc_mapVehicleMarkers }, 1] call CBA_fnc_addPerFrameHandler;

    // Launchers are checked when the group spots a new enemy (AUQOL_fnc_squadGroupHooks) and on the
    // Reveal target key; this 5 s pass catches targets that only become visible later and new launchers.
    [{ call AUQOL_fnc_squadLaunchers }, 5] call CBA_fnc_addPerFrameHandler;
};

call AUQOL_fnc_diagnostics;
