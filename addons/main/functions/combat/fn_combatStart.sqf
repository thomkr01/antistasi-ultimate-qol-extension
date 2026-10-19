/*
    Author: AUQOL
    Starts smart combat tactics for a local AI group in contact: one CBA timer per group, every 3 s,
    that runs AUQOL_fnc_combatTick until the group has had no known enemy within range for 30 s. Started
    by the group's EnemyDetected event and by a unit's Suppressed event, so groups that are not
    fighting cost nothing.

    Skipped for groups led by a player (their moves are the player's call), civilians, and everything
    while LAMBS Danger or Vcom AI is loaded and auqol_combat_yieldToAIMods is on.

    Arguments:
    0: Group <GROUP>

    Return Value: none
*/

params ["_group"];
if (!auqol_ready || {!auqol_combat_tactics} || {isNull _group} || {!local _group}) exitWith {};
if (auqol_combat_yieldToAIMods && auqol_combat_aiModLoaded) exitWith {};
if (isPlayer leader _group || {side _group == civilian} || {!isNil {_group getVariable "auqol_tacPFH"}}) exitWith {};

_group setVariable ["auqol_tacIdle", 0];
_group setVariable ["auqol_tacPFH", [{
    params ["_args", "_handle"];
    _args params ["_group"];
    ["combat tactics", { [_group, _handle] call AUQOL_fnc_combatTick }] call AUQOL_fnc_perfRun;
}, 3, [_group]] call CBA_fnc_addPerFrameHandler];
