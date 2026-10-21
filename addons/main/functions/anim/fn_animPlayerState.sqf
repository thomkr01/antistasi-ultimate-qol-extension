/*
    Author: AUQOL
    Faster pistol swap for the local player, and the primary weapon (else the handgun)
    in hand after getting up from unconscious: the engine brings the launcher out then, a slow animation
    that locks movement. For 3 s after the last "unconscious" state, a launcher in hand is swapped back. Runs from the player's
    AnimStateChanged event. While the player is in a weapon switch to or from the handgun, their
    animations play faster; any other state puts them back to normal speed. Ladders are not sped up: a
    faster animation only made the climb look quicker, the engine's own step timing made it slower. Names are matched by pattern, so addon animations that follow
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

if (auqol_player_wakePrimary) then {
    if ("unconscious" in _anim) then {
        _unit setVariable ["auqol_wasDown", true];
    } else {
        if (_unit getVariable ["auqol_wasDown", false]) then {
            _unit setVariable ["auqol_wasDown", false];
            _unit setVariable ["auqol_wakeUntil", time + 3];
        };
        // shortcut: a launcher you pick on purpose within these 3 s is swapped back, upgrade if that gets in the way.
        private _launcher = secondaryWeapon _unit;
        if (time < _unit getVariable ["auqol_wakeUntil", 0] && _launcher != "" && {currentWeapon _unit == _launcher} && {isNull objectParent _unit} && {local _unit}) then {
            private _weapon = [handgunWeapon _unit, primaryWeapon _unit] select (primaryWeapon _unit != "");
            if (_weapon != "") then { _unit selectWeapon _weapon };
        };
    };
};
private _coef = 1;
// Weapon switch states are "<from>_<to>", some with an "_end" part; the handgun is "wpst" in exactly
// one of the two. The end part, where the pistol comes up, plays 1.5 times faster again.
private _parts = _anim splitString "_";
private _end = count _parts == 3 && {_parts select 2 == "end"};
if (auqol_anim_pistolSwap && {count _parts == 2 || _end} && {("wpst" in (_parts select 0)) isNotEqualTo ("wpst" in (_parts select 1))}) then {
    _coef = auqol_anim_pistolSwapSpeed * ([1, 1.5] select _end);
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
