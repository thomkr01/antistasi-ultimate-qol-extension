/*
    Author: AUQOL
    Contact reports between groups: when a group detects a new enemy, nearby AI groups of the same
    side get to know it too (reveal 1.5), so they can join the fight. Their own EnemyDetected event
    then starts their smart combat tactics. Called from every AI group's EnemyDetected hook
    (AUQOL_fnc_combatGroupHook) and from the player group's (AUQOL_fnc_squadGroupHooks), so friendly
    AI near you hear what your squad has spotted. Only knowledge is shared: no group gets new orders,
    and where it goes stays with Antistasi or the mission. reveal only acts where the group is local,
    so it is sent to the machine of each receiving group's leader. One report per group every 10 s (a T key press always goes out),
    to at most 6 groups within 300 m.

    Arguments:
    0: Reporting group <GROUP>
    1: Detected enemy <OBJECT>
    2: Always share, ignoring the 10 s limit <BOOL> (default: false; the T key and look to spot pass true)
    3: Reveal level the receivers get <NUMBER> (default: 1.5; look to spot passes 4, the level its own squad gets)

    Return Value: none
*/

params ["_group", "_target", ["_always", false], ["_level", 1.5]];
if (!auqol_ready || {!auqol_combat_shareContacts} || {!alive _target} || {!_always && {time < _group getVariable ["auqol_tacNextShare", 0]}}) exitWith {};
if (auqol_combat_yieldToAIMods && auqol_combat_aiModLoaded) exitWith {};
_group setVariable ["auqol_tacNextShare", time + 10];

private _side = side _group;
private _origin = getPosATL leader _group;
private _receivers = allGroups select {
    _x isNotEqualTo _group && {side _x isEqualTo _side} && {!isPlayer leader _x}
    && {alive leader _x} && {leader _x distance2D _origin < 300}
};
{
    ["auqol_combat_reveal", [_x, _target, _level], leader _x] call CBA_fnc_targetEvent;
} forEach (_receivers select [0, 6]);
