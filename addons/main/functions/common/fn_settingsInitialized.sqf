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

// Starts a recurring timer after its own offset, so timers whose periods share a multiple (5, 15, 30,
// 60 s) don't all run in the same frame. Only the start moves; the period stays the same.
private _offset = 0;
private _every = {
    params ["_code", "_period"];
    _offset = _offset + 0.15;
    [{ _this call CBA_fnc_addPerFrameHandler }, [_code, _period], _offset] call CBA_fnc_waitAndExecute;
};

if (isServer) then {
    // Antistasi garage fuel sources only drain when a vehicle is pulled out, so a slow check is enough.
    [{ ["garage fuel", { call AUQOL_fnc_serviceGarageRestore }] call AUQOL_fnc_perfRun }, 10] call _every;

    // ACE limited rearm has no consumption event; sources start at a very large supply and are topped up here.
    [{ ["ACE rearm", {
        auqol_aceRearmSources = auqol_aceRearmSources select { !isNull _x };
        { [_x, auqol_service_ammo] call AUQOL_fnc_aceRearmApply } forEach +auqol_aceRearmSources; // copy: disabling removes entries
    }] call AUQOL_fnc_perfRun }, 30] call _every;

    // Marks parked empty vehicles and settled wrecks for the engine's dynamic simulation. The engine does
    // the freezing and waking itself, which nobody near can see, so a slow pass is enough.
    [{ ["vehicle freeze", { call AUQOL_fnc_freezeVehicles }] call AUQOL_fnc_perfRun }, 30] call _every;
};

// Faster AI reactions run on every machine for its own AI, so garrisons on the server or a headless
// client are covered as well as each player's squad. Units are handled when they spawn, change owner or
// join a player's group (XEH_postInit, AUQOL_fnc_squadGroupHooks); this full pass once a minute catches
// skills Antistasi sets later. It only writes skills that are below the floor.
[] call AUQOL_fnc_squadReactApply;
[{ ["reaction skills", { [] call AUQOL_fnc_squadReactApply }] call AUQOL_fnc_perfRun }, 60] call _every;

// Night spotting: enemy AI are checked when they spawn and change owner (XEH_postInit). No engine event
// says an enemy came close or a soldier left a vehicle with thermal sights, so this polls every 5 s; by
// day it only looks at units that still carry reduced skills.
[] call AUQOL_fnc_nightApply;
// A fifth of the units each second, so each is still checked every 5 s but no single frame does them all.
[{ ["night spotting", { [] call AUQOL_fnc_nightApply }] call AUQOL_fnc_perfRun }, 1] call _every;

// Faster AI animations: units are set when they spawn; this pass catches values reset by others (ACE
// medical sets a medic back to 1) and units that became or stopped being players. One getter per unit.
[] call AUQOL_fnc_animAiApply;
[{ ["AI animation speed", { [] call AUQOL_fnc_animAiApply }] call AUQOL_fnc_perfRun }, 15] call _every;

// AI stuck checks run on every machine (server, clients, headless clients) for the AI local to it.
// No engine event reports "no progress", so this polls; the pass returns at once when the feature is off.
[{ ["stuck AI", { call AUQOL_fnc_stuckMonitor }] call AUQOL_fnc_perfRun }, 5] call _every;

if (hasInterface) then {
    call AUQOL_fnc_aceRegisterFactors;

    // Player perks follow the player's unit, loadout and group, and recruits joining the group
    // (AUQOL_fnc_squadGroupHooks). Antistasi re-applies role traits (loadCoef) shortly after respawn
    // without an event, so a unit change re-applies again 3 s later. The 15 s pass is the fallback for
    // anything else; it is three cheap getters per unit and only writes when a value drifted.
    // Faster pistol swap and ladders follow the player's animation state on their current unit.
    ["unit", {
        params ["_unit"];
        if (isNil {_unit getVariable "auqol_animEH"}) then {
            _unit setVariable ["auqol_animEH", _unit addEventHandler ["AnimStateChanged", { _this call AUQOL_fnc_animPlayerState }]];
        };
        [[_unit]] call AUQOL_fnc_animAiApply;
        // A boost left on the old unit (died on a ladder) must not keep ACE fatigue's exclusion.
        private _exclusions = missionNamespace getVariable "ace_advanced_fatigue_setAnimExclusions";
        if (!isNil "_exclusions") then { _exclusions deleteAt (_exclusions find "auqol") };
        call AUQOL_fnc_playerApply;
        [{ call AUQOL_fnc_playerApply }, [], 3] call CBA_fnc_waitAndExecute;
    }, true] call CBA_fnc_addPlayerEventHandler;
    ["loadout", { call AUQOL_fnc_playerApply }] call CBA_fnc_addPlayerEventHandler;
    ["group", { call AUQOL_fnc_squadGroupHooks; call AUQOL_fnc_playerApply; [] call AUQOL_fnc_squadSelfTreat; [units group player] call AUQOL_fnc_squadReactApply }, true] call CBA_fnc_addPlayerEventHandler;
    // Self-treat runs 3 s after a hit (its "Dammaged" hook); the 15 s pass also catches damage set
    // without a hit, such as the 0.25 Antistasi's revive leaves.
    [{ ["player perks", { call AUQOL_fnc_playerApply; call AUQOL_fnc_squadSelfTreat }] call AUQOL_fnc_perfRun }, 15] call _every;

    // Concealment: no event says a unit lay down or an enemy came near, so the player and their squad
    // are checked every second (a handful of units); hits, near shots and getting in are events.
    [{ ["concealment", { [] call AUQOL_fnc_concealTick }] call AUQOL_fnc_perfRun }, 1] call _every;
    ["Antistasi Ultimate QoL by TchicX", "auqol_conceal_toggle", ["Toggle hiding", "Switch concealment off or on for you and your squad, for example to be seen on purpose."], {
        auqol_conceal_off = !auqol_conceal_off;
        [] call AUQOL_fnc_concealTick;
        false
    }, {}, [-1, [false, false, false]]] call CBA_fnc_addKeybind; // no default key

    // Fast ladder climbing key. Not blocking the key: Left Shift is still sprint off the ladder.
    ["Antistasi Ultimate QoL by TchicX", "auqol_anim_ladderFast", ["Fast ladder climbing (hold)", "While on a ladder, climb at the 'Ladder speed with the key held' setting."], {
        auqol_anim_ladderKeyHeld = true;
        [player, animationState player] call AUQOL_fnc_animPlayerState;
        false
    }, {
        auqol_anim_ladderKeyHeld = false;
        [player, animationState player] call AUQOL_fnc_animPlayerState;
        false
    }, [0x2A, [true, false, false]]] call CBA_fnc_addKeybind; // 0x2A: DIK_LSHIFT

    // The engine's own Reveal target key (T by default); the handler checks auqol_squad_revealKey.
    addUserActionEventHandler ["revealTarget", "Activate", { call AUQOL_fnc_squadRevealTarget }];

    // Look to spot: no event says the view moved over an enemy, so the view is checked twice a second.
    // The pass returns before any scan when the feature is off or the squad has no AI local here.
    [{ ["look to spot", { [] call AUQOL_fnc_squadLookSpot }] call AUQOL_fnc_perfRun }, 0.5] call _every;

    // Ambush discipline and overwatch follow your behaviour, speed and the enemies you know of; no event says any of that changed.
    [{ ["squad tactics", { [] call AUQOL_fnc_squadAmbush; [] call AUQOL_fnc_squadOverwatch }] call AUQOL_fnc_perfRun }, 1] call _every;
    // Antistasi moves its vehicle markers once a minute; new markers arrive through MarkerCreated, and the
    // 1 s pass only moves tracked markers whose vehicle moved. It does the work every second only while the
    // map or GPS panel is open and every 10 s otherwise; opening the map runs it at once.
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
    addMissionEventHandler ["Map", {
        params ["_opened"];
        if (_opened) then { auqol_map_nextIdle = 0; call AUQOL_fnc_mapVehicleMarkers };
    }];
    [{ ["map markers", { call AUQOL_fnc_mapVehicleMarkers }] call AUQOL_fnc_perfRun }, 1] call _every;

    // Launchers are checked when the group spots a new enemy (AUQOL_fnc_squadGroupHooks) and on the
    // Reveal target key; this pass catches targets that only become visible later and new launchers.
    // It runs every 5 s while the player knows of an enemy vehicle, and every second while one is an
    // aircraft, since a jet's attack run is over within a few seconds.
    [{
        if (isNull player) exitWith {};
        private _vehicles = (player targets [true, 2000]) select { !(_x isKindOf "Man") };
        if (_vehicles isEqualTo [] || {time < auqol_launcherNext && {_vehicles findIf { _x isKindOf "Air" } == -1}}) exitWith {};
        auqol_launcherNext = time + 5;
        ["launchers", { call AUQOL_fnc_squadLaunchers }] call AUQOL_fnc_perfRun;
    }, 1] call _every;
};

call AUQOL_fnc_diagnostics;
