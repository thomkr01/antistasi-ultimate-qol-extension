/*
    Author: AUQOL
    Launcher switch for the AI in the local player's group. Runs when the group spots a new enemy
    (EnemyDetected, AUQOL_fnc_squadGroupHooks), on the Reveal target key, and every 5 s as a fallback. An AI with a loaded
    launcher that knows about an enemy vehicle it can see and its launcher can engage (by the
    ammunition's aiAmmoUsageFlags: 256 air, 128 or 512 ground vehicles) within range takes the
    launcher out at once and targets it. Knowledge comes from the unit's own spotting, the squad, or
    the Reveal target key. The engine's own weapon choice takes over again once the target is gone.

    Smart combat AI (AUQOL_fnc_combatTick) also calls it with the members of an AI group facing armor.

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
    private _magazine = (secondaryWeaponMagazine _unit) param [0, ""];
    if (_launcher == "" || _magazine == "" || {currentWeapon _unit == _launcher}
        || {!isNull objectParent _unit} || {lifeState _unit == "INCAPACITATED"} || {_unit getVariable ["incapacitated", false]}) then { continue };

    private _flags = auqol_launcherFlags getOrDefaultCall [_magazine, {
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
    }, true];
    private _antiAir = 256 in _flags;
    private _antiGround = 128 in _flags || {512 in _flags};
    if (!_antiAir && !_antiGround) then { continue };

    private _eye = eyePos _unit;
    private _target = (_unit targets [true, [500, 2000] select _antiAir]) select {
        !(_x isKindOf "Man") && {alive _x}
        && {[_antiGround && {_unit distance _x < 500}, _antiAir] select (_x isKindOf "Air")}
        && {([_unit, "VIEW", _x] checkVisibility [_eye, aimPos _x]) > 0.5}
    } param [0, objNull];

    if (!isNull _target) then {
        _unit selectWeapon _launcher;
        _unit doTarget _target;
        [format ["Launcher: %1 takes out %2 for %3", name _unit, _launcher, typeOf _target], true] call AUQOL_fnc_log;
    };
} forEach (_units select { local _x && {!isPlayer _x} && {alive _x} });
