/*
    Author: AUQOL
    Faster AI animations: plays the animations of every AI soldier at auqol_anim_aiSpeed (1 to 2), so
    they move, turn, change stance and get through actions sooner and their next decision comes sooner.
    Any faction or addon unit; no FSM or behaviour is touched. Upper-body animations such as reloading
    are not affected by the engine command.

    setAnimSpeedCoef only takes effect on the machine that runs it, so this runs on every machine for
    every AI: when a unit spawns (XEH_postInit) and in a 15 s pass that also catches values reset by
    others (ACE medical sets a medic back to 1 after treatment). Players are never sped up: a unit that
    became a player is set back to 1 if AUQOL had changed it.

    Arguments:
    0: Units to check <ARRAY> (optional, default: every unit)

    Return Value: none
*/

if (!auqol_ready) exitWith {};

params [["_units", nil, [[]]]];
if (isNil "_units") then { _units = allUnits };

{
    private _ours = _x getVariable "auqol_animAi";
    if (auqol_anim_ai && {!isPlayer _x} && {alive _x}) then {
        if (getAnimSpeedCoef _x != auqol_anim_aiSpeed) then {
            _x setAnimSpeedCoef auqol_anim_aiSpeed;
            _x setVariable ["auqol_animAi", true];
        };
    } else {
        if (!isNil "_ours") then {
            // Players keep any boost the pistol feature gave them (AUQOL_fnc_animPlayerState).
            if !(_x getVariable ["auqol_animBoost", false]) then { _x setAnimSpeedCoef 1 };
            _x setVariable ["auqol_animAi", nil];
        };
    };
} forEach (_units select { _x isKindOf "CAManBase" });
