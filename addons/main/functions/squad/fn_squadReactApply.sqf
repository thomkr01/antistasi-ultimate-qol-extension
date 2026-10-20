/*
    Author: AUQOL
    Faster reactions for friendly AI local to this machine: raises the sub-skills that decide how
    quickly AI spot, share and turn onto a target (spotTime, spotDistance, aimingSpeed, commanding)
    to at least auqol_squad_reactionSkill. Accuracy (aimingAccuracy, aimingShake) is left to
    Antistasi, which scales it with rebel training, so AI react sooner but do not hit better.

    Covers the AI in groups led by a player and, with auqol_squad_reactionAll, every friendly AI
    (Antistasi's teamPlayer side: garrisons, static and turret gunners, high-command squads). Runs on
    every machine for its own AI. Event-driven: a unit is checked when it spawns and again 5 s later
    (after Antistasi has set its skills), when it becomes local to this machine (server <-> headless
    client) and when it joins a player's group. A full pass every 60 s catches skills set later and
    units that stopped being covered. Each unit costs four skill reads; it only writes when a value
    is below the floor, and units no longer covered get back the values AUQOL replaced. The saved values are a public
    unit variable, so they survive a change of owner (server <-> headless client).

    Arguments:
    0: Units to check <ARRAY> (optional, default: every unit on this machine)

    Return Value: none
*/

if (!auqol_ready) exitWith {};

params [["_units", nil, [[]]]];
if (isNil "_units") then { _units = allUnits };

private _friendly = missionNamespace getVariable ["teamPlayer", sideUnknown];
if !(_friendly isEqualType sideUnknown) then { _friendly = sideUnknown };
private _playerGroup = if (hasInterface) then { group player } else { grpNull };
private _skills = ["spotTime", "spotDistance", "aimingSpeed", "commanding"];

{
    private _unit = _x;
    // A unit that changed side still carries night-reduced skills: hand them back before saving a baseline.
    if (!isNil {_unit getVariable "auqol_nightSkills"}) then { [[_unit]] call AUQOL_fnc_nightApply };
    private _saved = _unit getVariable "auqol_reactSkills";
    if (auqol_squad_reaction && {auqol_squad_reactionAll || {isPlayer leader group _unit}}) then {
        // Saved once, before the first write, and public: skills travel with the unit when it moves
        // between the server and a headless client, so the new owner must get the baseline too rather
        // than read the raised values as the original ones.
        if (isNil "_saved" && {_skills findIf { _unit skill _x < auqol_squad_reactionSkill } != -1}) then {
            _unit setVariable ["auqol_reactSkills", _skills apply { _unit skill _x }, true];
        };
        {
            if (_unit skill _x < auqol_squad_reactionSkill) then { _unit setSkill [_x, auqol_squad_reactionSkill] };
        } forEach _skills;
    } else {
        if (!isNil "_saved") then {
            { _unit setSkill [_x, _saved select _forEachIndex] } forEach _skills;
            _unit setVariable ["auqol_reactSkills", nil, true];
        };
    };
} forEach (_units select {
    local _x && {!isPlayer _x} && {alive _x}
    && {side group _x == _friendly || {group _x == _playerGroup} || {!isNil {_x getVariable "auqol_reactSkills"}}}
});
