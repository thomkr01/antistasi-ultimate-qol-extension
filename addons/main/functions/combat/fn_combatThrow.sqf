/*
    Author: AUQOL
    Makes an AI throw a hand grenade or a smoke grenade toward a position, if it carries one: the
    unit faces the spot and throws a second later. Grenades are found by what their ammo does
    (simulation shotGrenade for frags, shotSmoke or shotSmokeX for smoke), so any faction's or mod's
    grenades work. At most one frag per unit every 40 s and one smoke per group every 60 s.

    Arguments:
    0: Unit <OBJECT>
    1: Target position <ARRAY> (AGL)
    2: Kind <STRING> "frag" or "smoke"

    Return Value: none
*/

params ["_unit", "_pos", "_kind"];

private _smoke = _kind == "smoke";
private _holder = [_unit, group _unit] select _smoke;
private _key = ["auqol_tacNextFrag", "auqol_tacNextSmoke"] select _smoke;
if (time < _holder getVariable [_key, 0]) exitWith {};

// Magazine -> [muzzle, kind] from the Throw weapon's muzzles, cached for the mission.
private _muzzle = "";
{
    private _info = auqol_combat_throwables getOrDefaultCall [_x, {
        private _mag = _x;
        private _sim = getText (configFile >> "CfgAmmo" >> getText (configFile >> "CfgMagazines" >> _mag >> "ammo") >> "simulation");
        private _found = ["", ""];
        {
            private _mags = (getArray (configFile >> "CfgWeapons" >> "Throw" >> _x >> "magazines")) apply { toLowerANSI _x };
            if (toLowerANSI _mag in _mags) exitWith {
                _found = [_x, switch (toLowerANSI _sim) do {
                    case "shotgrenade": { "frag" };
                    case "shotsmoke";
                    case "shotsmokex": { "smoke" };
                    default { "" };
                }];
            };
        } forEach getArray (configFile >> "CfgWeapons" >> "Throw" >> "muzzles");
        _found
    }, true];
    if (_info select 1 == _kind) exitWith { _muzzle = _info select 0 };
} forEach (magazines _unit arrayIntersect magazines _unit);
if (_muzzle isEqualTo "") exitWith {};
// A frag thrown at a wall or ceiling right in front of the thrower bounces back onto his own team.
if (!_smoke) then { _muzzle = ["", _muzzle] select (lineIntersectsSurfaces [eyePos _unit, eyePos _unit vectorAdd (((eyePos _unit vectorFromTo AGLToASL _pos) vectorMultiply 4) vectorAdd [0, 0, 0.3]), _unit, objNull, true, 1, "GEOM", "NONE"] isEqualTo []) };
if (_muzzle isEqualTo "") exitWith {};
_holder setVariable [_key, time + ([40, 60] select _smoke)];
_unit doWatch _pos;
[{
    params ["_unit", "_muzzle"];
    if (alive _unit && {local _unit} && {isNull objectParent _unit} && {lifeState _unit in ["HEALTHY", "INJURED"]}) then {
        _unit forceWeaponFire [_muzzle, _muzzle];
    };
    _unit doWatch objNull;
}, [_unit, _muzzle], 1] call CBA_fnc_waitAndExecute;
