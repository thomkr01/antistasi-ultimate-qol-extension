/*
    Author: AUQOL
    Faster reactions for the AI in the local player's group: raises the sub-skills that decide how
    quickly AI spot, share and turn onto a target (spotTime, spotDistance, aimingSpeed, commanding)
    to at least auqol_squad_reactionSkill. Accuracy (aimingAccuracy, aimingShake) is left to
    Antistasi, which scales it with rebel training, so the squad reacts sooner but does not hit
    better. Runs from the 5 s player re-check, which also covers new recruits; only writes when a
    value is below the floor, and turning it off restores the values AUQOL replaced.

    Arguments: none
    Return Value: none
*/

if (!hasInterface || {!auqol_ready}) exitWith {};

private _player = player;
if (isNull _player) exitWith {};

private _skills = ["spotTime", "spotDistance", "aimingSpeed", "commanding"];

// shortcut: AI that leave the group keep the raised values; Antistasi usually deletes dismissed AI anyway.
{
    private _unit = _x;
    private _saved = _unit getVariable "auqol_reactSkills";
    if (auqol_squad_reaction) then {
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
} forEach (units group _player select { local _x && {!isPlayer _x} && {alive _x} });
