/*
    Author: AUQOL
    Hard to locate (from the CAManBase Fired handler, where the shooter is local): works out how far
    away enemies can still pinpoint a player or their squad AI from the shot alone, and tells every
    machine (AUQOL_fnc_concealLocateCheck). Beyond that distance a shot gives them nothing; only seeing
    the shooter does. Works with AUQOL concealment and with the Hide Among The Grass mod alike.

    Distance, from the gear's own config values:
    - auqol_conceal_locateRange for a rifle round, times the square root of how loud this round is
      (CfgAmmo audibleFire, 45 for a rifle) and how much the muzzle device lets through (the
      suppressor's AmmoCoef audibleFire, 0.04 to 0.1 for most), since sound carries with the square
      root of its loudness. A suppressed rifle comes out at 100 to 160 m.
    - In the dark the muzzle flash counts: (1 + darkness x (visibleFire - 0.8)), so an open muzzle is
      seen 20 % farther and a suppressor (visibleFire 0.2 to 0.5) hides it. Enemies with night vision
      get the daylight distance.
    - Times the uniform's camouflage (AUQOL_fnc_concealCamo, ghillie 0.6 or less), x0.8 prone.
    - Every further shot from the same spot (within 10 m, within a minute) adds 25 %, up to 3 times.
    - Times a random 0.8 to 1.2.
    Sent at most once a second per shooter.

    Arguments:
    0: Unit <OBJECT>
    1: Weapon <STRING>
    2: Ammo <STRING>

    Return Value: none
*/

params ["_unit", "_weapon", "_ammo"];

if (!auqol_conceal_locate || {!isPlayer _unit && {!isPlayer leader _unit}} || {!isNull objectParent _unit}) exitWith {};

private _spot = _unit getVariable ["auqol_locateSpot", [getPosATL _unit, 0, -1e9]];
_spot params ["_pos", "_count", "_last"];
if (_unit distance2D _pos >= 10 || {time - _last > 60}) then { _pos = getPosATL _unit; _count = 0 };
_count = _count + 1;
_unit setVariable ["auqol_locateSpot", [_pos, _count, time]];

if (time < _unit getVariable ["auqol_locateNext", 0]) exitWith {};
_unit setVariable ["auqol_locateNext", time + 1];

private _muzzle = (_unit weaponAccessories _weapon) param [0, ""];
private _coef = configFile >> "CfgWeapons" >> _muzzle >> "ItemInfo" >> "AmmoCoef";
private _audible = [1, getNumber (_coef >> "audibleFire")] select isNumber (_coef >> "audibleFire");
private _visible = [1, getNumber (_coef >> "visibleFire")] select isNumber (_coef >> "visibleFire");
private _loud = getNumber (configFile >> "CfgAmmo" >> _ammo >> "audibleFire");
if (_loud <= 0) then { _loud = 45 };

private _range = auqol_conceal_locateRange * sqrt (_loud * _audible / 45) * ([_unit] call AUQOL_fnc_concealCamo)
    * ([1, 0.8] select (stance _unit == "PRONE")) * ((1 + 0.25 * (_count - 1)) min 3) * random [0.8, 1, 1.2];
_range = _range max 20 min (auqol_conceal_locateRange * 3);
// Same darkness as night spotting (AUQOL_fnc_nightApply).
private _dark = (1 - sunOrMoon) * (1 - 0.6 * moonIntensity * (1 - overcast));

["auqol_locate_shot", [_unit, _range * (1 + _dark * (_visible - 0.8)), _range]] call CBA_fnc_globalEvent;
