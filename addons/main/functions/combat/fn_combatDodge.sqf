/*
    Author: AUQOL
    AI get away from thrown hand grenades. From the thrower's "Fired" event (any unit, player or AI):
    for a frag (ammo simulation shotGrenade, so any mod's grenades), about 1.5 s after the throw every AI
    on foot within 10 m of the grenade that is local to this machine runs 12 m directly away from it,
    then rejoins formation 6 s later. Units Antistasi has busy, garrisons and players are left alone
    (AUQOL_fnc_combatIsEligible), and a unit's smart combat spot is dropped so it picks a new one.

    Arguments:
    0: Thrower <OBJECT>
    1: Weapon <STRING>
    6: Projectile <OBJECT>

    Return Value: none
*/

params ["_thrower", "_weapon", "", "", "_ammo", "", "_projectile"];
if (_weapon != "Throw" || {!auqol_ready} || {!auqol_combat_dodge}) exitWith {};
if (auqol_combat_yieldToAIMods && auqol_combat_aiModLoaded) exitWith {};
if ((auqol_combat_ammoSim getOrDefaultCall [_ammo, { toLowerANSI getText (configFile >> "CfgAmmo" >> _ammo >> "simulation") }, true]) isNotEqualTo "shotgrenade") exitWith {};

// ACE Advanced Throwing raises this event when the grenade is primed, while it is still in the hand,
// so the dodge waits until the grenade has left the thrower (at once for a vanilla throw).
private _dodge = { [{
    params ["_projectile"];
    if (isNull _projectile) exitWith {};
    private _pos = getPosATL _projectile;
    {
        private _unit = _x;
        _unit setVariable ["auqol_tacDest", nil];
        private _spot = _pos getPos [12, _pos getDir _unit];
        _unit doMove _spot;
        _unit setVariable ["auqol_tacDodge", true];
        [{
            params ["_unit"];
            if (alive _unit && {local _unit} && {_unit getVariable ["auqol_tacDodge", false]} && {currentCommand _unit in ["", "MOVE"]}) then { _unit doFollow leader _unit };
            _unit setVariable ["auqol_tacDodge", nil];
        }, [_unit], 6] call CBA_fnc_waitAndExecute;
    } forEach ((_pos nearEntities ["CAManBase", 10]) select { [_x] call AUQOL_fnc_combatIsEligible });
}, [_this select 0], 1.2] call CBA_fnc_waitAndExecute };
[{ isNull (_this select 0) || {(_this select 0) distance (_this select 1) > 3} }, _dodge, [_projectile, _thrower], 30] call CBA_fnc_waitUntilAndExecute;
