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

if (isServer) then {
    // Antistasi garage fuel sources only drain when a vehicle is pulled out, so a slow check is enough.
    [{ call AUQOL_fnc_serviceGarageRestore }, 10] call CBA_fnc_addPerFrameHandler;

    // ACE limited rearm has no consumption event; sources start at a very large supply and are topped up here.
    [{
        auqol_aceRearmSources = auqol_aceRearmSources select { !isNull _x };
        { [_x, auqol_service_ammo] call AUQOL_fnc_aceRearmApply } forEach +auqol_aceRearmSources; // copy: disabling removes entries
    }, 30] call CBA_fnc_addPerFrameHandler;

    call AUQOL_fnc_capacityApplyAll;
};

if (hasInterface) then {
    call AUQOL_fnc_aceRegisterFactors;

    ["unit", {
        call AUQOL_fnc_playerApply;
        [true] call AUQOL_fnc_capacityRequest;
    }, true] call CBA_fnc_addPlayerEventHandler;
    ["loadout", { [false] call AUQOL_fnc_capacityRequest }] call CBA_fnc_addPlayerEventHandler;

    // Antistasi re-applies role traits (loadCoef) after respawn and role changes without an event;
    // this re-check is three cheap getters every 5 seconds and only writes when a value drifted.
    [{ call AUQOL_fnc_playerApply }, 5] call CBA_fnc_addPerFrameHandler;
};

call AUQOL_fnc_diagnostics;
