/*
    Author: AUQOL
    Concealment and shooting (from the CAManBase Fired handler, for units AUQOL_fnc_concealTick looks
    after). Shots fired within 10 m of where the count started are counted; moving farther starts a new
    count. A unit is revealed for auqol_conceal_cooldown seconds when it fires a launcher or goes over
    its allowed shots there: a random 4 to 8 at the default auqol_conceal_shots of 4, plus as many again
    with a ghillie suit, plus twice the setting with a suppressor, and half without one, then divided by
    the uniform's camouflage (AUQOL_fnc_concealCamo). -1 allows any number of shots.

    Arguments:
    0: Unit <OBJECT>
    1: Weapon <STRING>

    Return Value: none
*/

params ["_unit", "_weapon"];

if (isNil {_unit getVariable "auqol_conceal"}) exitWith {};

private _shots = auqol_conceal_shots;
private _spot = _unit getVariable ["auqol_concealShots", [getPosATL _unit, 0, -1]];
_spot params ["_pos", "_count", "_allowed"];
if (_unit distance2D _pos >= 10) then { _pos = getPosATL _unit; _count = 0; _allowed = -1 };
_count = _count + 1;

if (_allowed == -1) then {
    _allowed = round random [_shots, _shots + 2, _shots + 4];
    if (auqol_conceal_ghillieCache getOrDefault [uniform _unit, false]) then { _allowed = _allowed + round random [_shots, _shots + 2, _shots + 4] };
    // A suppressor is a muzzle item that lowers how far the shot is heard (flash hiders and brakes don't).
    private _muzzle = (_unit weaponAccessories _weapon) param [0, ""];
    private _suppressed = _muzzle != "" && {getNumber (configFile >> "CfgWeapons" >> _muzzle >> "ItemInfo" >> "AmmoCoef" >> "audibleFire") < 1};
    _allowed = [round (_allowed / 2), _allowed + _shots * 2] select _suppressed;
    // A camouflage uniform hides the shooter's position longer: 0.5 camouflage allows twice the shots.
    _allowed = round (_allowed / ([_unit] call AUQOL_fnc_concealCamo));
};
_unit setVariable ["auqol_concealShots", [_pos, _count, _allowed]];

if ((_weapon != "" && {_weapon == secondaryWeapon _unit}) || {_shots != -1 && _count >= _allowed}) then {
    [_unit] call (_unit getVariable "auqol_concealReveal");
};
