/*
    Author: AUQOL
    Wounded AI treat themselves. Without a unit, adds the "Dammaged" hook to every AI of the local
    player's group and checks each of them: 3 s after a unit is hit, when a recruit joins, and every
    15 s as a fallback. With a unit, checks that unit; smart combat AI (AUQOL_fnc_combatSupport) calls
    it this way for the members of AI groups in a fight, so they use their own first aid kits too.

    - Really hurt (legs at 0.5 or more, so it limps and cannot run, any other hit point at 0.5 or more,
      or overall damage above 0.25): the unit uses vanilla "Treat yourself" with its first aid kit, or
      its medikit if it is a medic. Without either it waits for a medic as before.
    - Lightly hurt (can run, nothing at 0.5, overall damage 0.25 or less): this is what Antistasi's
      non-medic revive and a first aid kit leave behind, and what keeps the red hurt icon up. It is
      cleared without using a kit; with "Require medikit" on, only if the unit carries a medikit.
      Only for your own squad, since it is there to clear the hurt icon you see.
    Skipped under ACE medical, whose own AI medical treats AI, and for units Antistasi's medical is
    already handling (incapacitated, being helped, helping someone), captives, surrendered units and
    units in vehicles.

    Arguments:
    0: Unit to check <OBJECT> (optional, default: every AI of the player's group)

    Return Value: none
*/

if (!auqol_ready) exitWith {};
if (isClass (configFile >> "CfgPatches" >> "ace_medical_engine")) exitWith {};

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {
    if (!hasInterface || {!auqol_squad_selfTreat}) exitWith {};
    {
        if (isNil {_x getVariable "auqol_treatHooked"}) then {
            _x setVariable ["auqol_treatHooked", true];
            // One check 3 s after the first hit of a burst, reading the damage as it is then.
            _x addEventHandler ["Dammaged", {
                params ["_unit"];
                if (_unit getVariable ["auqol_treatPending", false]) exitWith {};
                _unit setVariable ["auqol_treatPending", true];
                [{ _this setVariable ["auqol_treatPending", nil]; [_this] call AUQOL_fnc_squadSelfTreat }, _unit, 3] call CBA_fnc_waitAndExecute;
            }];
        };
        [_x] call AUQOL_fnc_squadSelfTreat;
    } forEach (units group player select { local _x && {!isPlayer _x} });
};

if (!auqol_squad_selfTreat || {!local _unit} || {isPlayer _unit} || {!alive _unit} || {!isNull objectParent _unit}
    || {captive _unit} || {lifeState _unit == "INCAPACITATED"}
    || {_unit getVariable ["incapacitated", false]} || {_unit getVariable ["surrendered", false]}
    || {_unit getVariable ["helping", false]} || {!isNull (_unit getVariable ["helped", objNull])}
    || {time < (_unit getVariable ["auqol_treatUntil", 0])}) exitWith {};

private _damage = damage _unit;
private _worstHit = selectMax (((getAllHitPointsDamage _unit) param [2, []]) + [0]);
if (_damage == 0 && _worstHit == 0) exitWith {};

private _itemTypes = items _unit apply { getNumber (configFile >> "CfgWeapons" >> _x >> "ItemInfo" >> "type") };

if (_damage <= 0.25 && _worstHit < 0.5) exitWith {
    if (!hasInterface || {group _unit isNotEqualTo group player}) exitWith {};
    if (auqol_squad_selfTreatMedikit && {!(619 in _itemTypes)}) exitWith {};
    _unit setDamage 0;
    [format ["Self-treat: cleared light damage on %1", name _unit], true] call AUQOL_fnc_log;
};

private _isMedic = _unit getUnitTrait "Medic";
private _hasKit = 401 in _itemTypes || {619 in _itemTypes && _isMedic};
if (!_hasKit) exitWith {};

_unit action ["HealSoldierSelf", _unit];
// The animation takes about 10 s; check again after it to clear what a first aid kit leaves.
_unit setVariable ["auqol_treatUntil", time + 10];
[{ [_this] call AUQOL_fnc_squadSelfTreat }, _unit, 11] call CBA_fnc_waitAndExecute;
[format ["Self-treat: %1 treats itself (damage %2, worst hit point %3)", name _unit, _damage, _worstHit], true] call AUQOL_fnc_log;
