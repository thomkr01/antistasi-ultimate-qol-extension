/*
    Author: AUQOL
    Launcher switch for the AI in the local player's group. Runs when the group spots a new enemy
    (EnemyDetected, AUQOL_fnc_squadGroupHooks), on the Reveal target key, and every 5 s as a fallback. An AI with a launcher
    and a round for it that knows about an enemy vehicle it can see and its launcher can engage (by the
    ammunition's aiAmmoUsageFlags: 256 air, 128 or 512 ground vehicles) within range takes the
    launcher out at once and targets it. Knowledge comes from the unit's own spotting, the squad, or
    the Reveal target key. The engine's own weapon choice takes over again once the target is gone.

    Rounds are not wasted: a vehicle out of the fight (AUQOL_fnc_squadIsOutOfFight) is never picked, and vehicles another gunner already
    has under its launcher come last, so two rounds go to two vehicles. A gunner whose vehicle dropped
    out of the fight gets the next one, or puts the launcher away and its group forgets the wreck.
    Besides the passes below, it runs 1 s after each launcher round of a local AI has hit (XEH_postInit).

    Smart combat AI (AUQOL_fnc_combatTick) also calls it with the members of an AI group that knows about an enemy vehicle.

    Arguments:
    0: Units <ARRAY> (optional, default: the AI of the local player's group, when auqol_squad_launchers is on)

    Return Value: none
*/

params [["_units", nil, [[]]]];
if (!auqol_ready) exitWith {};
if (isNil "_units") then {
    _units = [[], units group player] select (hasInterface && auqol_squad_launchers && {!isNull player});
};

{
    private _unit = _x;
    private _launcher = secondaryWeapon _unit;
    if (_launcher == "" || {!isNull objectParent _unit} || {lifeState _unit == "INCAPACITATED"} || {_unit getVariable ["incapacitated", false]}) then { continue };

    // A gunner with the launcher out keeps its target while that target is still in the fight.
    private _holding = currentWeapon _unit == _launcher;
    private _current = getAttackTarget _unit;
    if (_holding && {!isNull _current} && {!([_current] call AUQOL_fnc_squadIsOutOfFight)}) then { continue };

    // Empty right after a shot or once put away unloaded: a spare round it carries counts, the AI reloads when it takes the launcher out.
    private _magazine = (secondaryWeaponMagazine _unit) param [0, ""];
    if (_magazine == "") then {
        private _fits = (compatibleMagazines _launcher) apply { toLowerANSI _x };
        _magazine = (magazines _unit select { toLowerANSI _x in _fits }) param [0, ""];
    };
    private _flags = if (_magazine == "") then { [] } else { auqol_launcherFlags getOrDefaultCall [_magazine, {
        private _entry = configFile >> "CfgAmmo" >> getText (configFile >> "CfgMagazines" >> _magazine >> "ammo") >> "aiAmmoUsageFlags";
        private _total = if (isNumber _entry) then { getNumber _entry } else {
            private _sum = 0;
            { _sum = _sum + parseNumber _x } forEach (getText _entry splitString " +");
            _sum
        };
        // Split the sum back into its flags (the engine only defines powers of two up to 512).
        private _bits = [];
        { if (_total >= _x) then { _bits pushBack _x; _total = _total - _x } } forEach [512, 256, 128, 64, 32, 16, 8, 4, 2, 1];
        _bits
    }, true] };
    private _antiAir = 256 in _flags;
    private _antiGround = 128 in _flags || {512 in _flags};

    private _target = objNull;
    if (_antiAir || _antiGround) then {
        // Vehicles another gunner of these units already has under its launcher come last, so rounds spread over several vehicles.
        private _taken = (_units select { _x isNotEqualTo _unit && {currentWeapon _x == secondaryWeapon _x} && {secondaryWeapon _x != ""} }) apply { getAttackTarget _x };
        private _eye = eyePos _unit;
        private _candidates = (_unit targets [true, [500, 2000] select _antiAir]) select {
            !(_x isKindOf "Man") && {!([_x] call AUQOL_fnc_squadIsOutOfFight)}
            && {[_antiGround && {_unit distance _x < 500}, _antiAir] select (_x isKindOf "Air")}
            && {([_unit, "VIEW", _x] checkVisibility [_eye, aimPos _x]) > 0.5}
        };
        _target = (_candidates select { !(_x in _taken) }) param [0, _candidates param [0, objNull]];
    };

    if (!isNull _target) then {
        if (!_holding) then { _unit selectWeapon _launcher };
        _unit doTarget _target;
        [format ["Launcher: %1 takes out %2 for %3", name _unit, _launcher, typeOf _target], true] call AUQOL_fnc_log;
        continue;
    };
    // Its vehicle is out of the fight and nothing else is worth a round: the launcher goes away and the group forgets the wreck.
    if (_holding && {!isNull _current} && {_current isKindOf "AllVehicles"} && {!(_current isKindOf "Man")}) then {
        _unit forgetTarget _current;
        _unit doTarget objNull;
        if (primaryWeapon _unit != "") then { _unit selectWeapon primaryWeapon _unit } else { if (handgunWeapon _unit != "") then { _unit selectWeapon handgunWeapon _unit } };
        [format ["Launcher: %1 saves its round, %2 is out of the fight", name _unit, typeOf _current], true] call AUQOL_fnc_log;
    };
} forEach (_units select { local _x && {!isPlayer _x} && {alive _x} });
