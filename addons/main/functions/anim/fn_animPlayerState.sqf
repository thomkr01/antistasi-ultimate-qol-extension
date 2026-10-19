/*
    Author: AUQOL
    Faster pistol swap and faster ladders for the local player. Runs from the player's
    AnimStateChanged event and when the fast-ladder key is pressed or released. While the player is in
    a weapon switch to or from the handgun, or on a ladder, their animations play faster; any other
    state puts them back to normal speed. Names are matched by pattern, so addon animations that follow
    the vanilla naming work too.

    The speed is sent to every machine (setAnimSpeedCoef only takes effect where it runs), and under
    ACE Advanced Fatigue the boost is registered in its exclusion list so its 1 s loop leaves it alone.

    Arguments:
    0: Unit <OBJECT>
    1: Animation state <STRING>

    Return Value: none
*/

params ["_unit", "_anim"];
if (_unit isNotEqualTo player || {!auqol_ready}) exitWith {};

_anim = toLowerANSI _anim;
private _coef = 1;
if (auqol_anim_ladder && {"ladder" in _anim}) then {
    _coef = [auqol_anim_ladderSpeed, auqol_anim_ladderFastSpeed] select auqol_anim_ladderKeyHeld;
};
// Weapon switch states are "<from>_<to>"; the handgun is "wpst" in exactly one of the two.
private _parts = _anim splitString "_";
if (auqol_anim_pistolSwap && {count _parts == 2} && {("wpst" in (_parts select 0)) isNotEqualTo ("wpst" in (_parts select 1))}) then {
    _coef = auqol_anim_pistolSwapSpeed;
};

private _boosted = _unit getVariable ["auqol_animBoost", false];
if (_coef == 1 && {!_boosted}) exitWith {};
if (_coef != 1 && _boosted && {getAnimSpeedCoef _unit == _coef}) exitWith {};

_unit setVariable ["auqol_animBoost", _coef != 1];
["auqol_anim_coef", [_unit, _coef]] call CBA_fnc_globalEvent;

private _exclusions = missionNamespace getVariable "ace_advanced_fatigue_setAnimExclusions";
if (!isNil "_exclusions") then {
    if (_coef != 1) then { _exclusions pushBackUnique "auqol" } else { _exclusions deleteAt (_exclusions find "auqol") };
};
