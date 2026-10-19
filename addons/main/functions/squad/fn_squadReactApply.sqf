/*
    Author: AUQOL
    Faster reactions for friendly AI local to this machine: raises the sub-skills that decide how
    quickly AI spot, share and turn onto a target (spotTime, spotDistance, aimingSpeed, commanding)
    to at least auqol_squad_reactionSkill. Accuracy (aimingAccuracy, aimingShake) is left to
    Antistasi, which scales it with rebel training, so AI react sooner but do not hit better.

    Covers the AI in groups led by a player and, with auqol_squad_reactionAll, every friendly AI
    (Antistasi's teamPlayer side: garrisons, static and turret gunners, high-command squads). Runs on
    every machine every 5 s for its own AI, which also catches units Antistasi spawns later and
    skills Antistasi sets after spawn. Each unit costs four skill reads; it only writes when a value
    is below the floor, and units no longer covered get back the values AUQOL replaced.

    Arguments: none
    Return Value: none
*/

if (!auqol_ready) exitWith {};

private _friendly = missionNamespace getVariable ["teamPlayer", sideUnknown];
if !(_friendly isEqualType sideUnknown) then { _friendly = sideUnknown };
private _playerGroup = if (hasInterface) then { group player } else { grpNull };
private _skills = ["spotTime", "spotDistance", "aimingSpeed", "commanding"];

{
    private _unit = _x;
    private _saved = _unit getVariable "auqol_reactSkills";
    if (auqol_squad_reaction && {auqol_squad_reactionAll || {isPlayer leader group _unit}}) then {
        if (isNil "_saved") then { _saved = _skills apply { _unit skill _x } };
        {
            if (_unit skill _x < auqol_squad_reactionSkill) then { _unit setSkill [_x, auqol_squad_reactionSkill] };
        } forEach _skills;
        _unit setVariable ["auqol_reactSkills", _saved];
    } else {
        if (!isNil "_saved") then {
            { _unit setSkill [_x, _saved select _forEachIndex] } forEach _skills;
            _unit setVariable ["auqol_reactSkills", nil];
        };
    };
} forEach (allUnits select {
    local _x && {!isPlayer _x} && {alive _x}
    && {side group _x == _friendly || {group _x == _playerGroup} || {!isNil {_x getVariable "auqol_reactSkills"}}}
});
