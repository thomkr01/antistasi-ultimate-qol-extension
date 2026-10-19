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

// AI stuck checks run on every machine (server, clients, headless clients) for the AI local to it.
// No engine event reports "no progress", so this polls; the pass returns at once when the feature is off.
[{ call AUQOL_fnc_stuckMonitor }, 5] call CBA_fnc_addPerFrameHandler;

if (hasInterface) then {
    call AUQOL_fnc_aceRegisterFactors;

    ["unit", { call AUQOL_fnc_playerApply }, true] call CBA_fnc_addPlayerEventHandler;

    // Antistasi re-applies role traits (loadCoef) after respawn and role changes without an event;
    // this re-check is three cheap getters every 5 seconds and only writes when a value drifted.
    [{ call AUQOL_fnc_playerApply; call AUQOL_fnc_squadReactApply }, 5] call CBA_fnc_addPerFrameHandler;

    // The engine's own Reveal target key (T by default); the handler checks auqol_squad_revealKey.
    addUserActionEventHandler ["revealTarget", "Activate", { call AUQOL_fnc_squadRevealTarget }];

    // Antistasi moves its vehicle markers once a minute; the pass returns at once when the feature is off.
    // The squad launcher check shares the same 1 s timer; both return at once when switched off.
    [{ call AUQOL_fnc_mapVehicleMarkers; call AUQOL_fnc_squadLaunchers }, 1] call CBA_fnc_addPerFrameHandler;
};

call AUQOL_fnc_diagnostics;
