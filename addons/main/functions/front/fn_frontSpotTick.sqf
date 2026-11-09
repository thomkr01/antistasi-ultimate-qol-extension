/*
    Author: AUQOL
    The binocular spotters' 5 s pass (AUQOL_fnc_frontSpot). Each spotter looks along the next of five bearings
    across its 60 degree sector (15 degrees apart, back and forth) and may spot hostile soldiers and vehicles
    within 1000 m in a 20 degree wedge around it that your group does not know well yet: the chance is how
    much of him it can see (checkVisibility), less with distance (half at 1000 m), and at night without night
    vision or thermal (AUQOL_fnc_nightHasVision) less by the same darkness night spotting uses. A spotted enemy
    is revealed to your squad at full knowledge, shared with friendly AI groups within 300 m
    (AUQOL_fnc_combatShareContact) and called out with its bearing (AUQOL_fnc_squadCallout).

    Spotting ends, and the unit gets its weapon and stance back, when you give it any order, it is hit or suppressed,
    an enemy is known within 150 m of it, it is told to fire (T focus, look to spot) or picks a target within 400 m
    it may fire at (not on Hold fire, so an ambush spotter keeps watching), takes out its launcher, is moved by a
    grenade dodge or Antistasi, gets in a vehicle, goes down,
    leaves your group, after 5 minutes, or with auqol_front_spotter off. While it treats itself or is treated it
    waits in place and carries on afterwards. It goes back into formation unless you
    ordered it elsewhere. The handler removes itself when no spotter is left.

    Arguments: none
    Return Value: none
*/
if (!hasInterface) exitWith {};
private _group = group player;
private _dark = (1 - sunOrMoon) * (1 - 0.6 * moonIntensity * (1 - overcast));
{
    private _unit = _x;
    private _spot = _unit getVariable ["auqol_spot", []];
    _spot params [["_dir", 0], ["_step", 0], ["_weapon", ""], ["_setStance", false], ["_damage", 0], ["_until", 0]];
    // Treating himself or being treated (in place, he is stopped): wait, do not pull him away mid-treatment.
    if (_spot isNotEqualTo [] && {alive _unit} && {time < _unit getVariable ["auqol_treatUntil", 0] || {_unit getVariable ["helping", false]} || {!isNull (_unit getVariable ["helped", objNull])}}) then { continue };
    private _enemy = _unit findNearestEnemy _unit;
    private _fight = getAttackTarget _unit;
    private _ordered = alive _unit && {!stopped _unit};
    if (_spot isEqualTo [] || {!auqol_front_spotter} || {!alive _unit} || {!local _unit} || _ordered || {time > _until}
        || {group _unit isNotEqualTo _group} || {!isNull objectParent _unit} || {!(lifeState _unit in ["HEALTHY", "INJURED"])}
        || {damage _unit > _damage + 0.01} || {getSuppression _unit > 0.5} || {captive _unit} || {_unit getVariable ["rearming", false]} || {binocular _unit == ""}
        // He is told to fire (T focus, look to spot) or picks a fight he may open (within 400 m, not on Hold fire): the fight wins.
        || {currentCommand _unit in ["FIRE", "ATTACK", "ATTACKFIRE"]} || {!isNull _fight && {combatMode _unit in ["YELLOW", "RED"]} && {_unit distance _fight < 400}}
        || {currentWeapon _unit != "" && {currentWeapon _unit == secondaryWeapon _unit}}
        || {!isNull _enemy && {_unit distance _enemy < 150}}) then {
        _unit setVariable ["auqol_spot", nil];
        auqol_front_spotters deleteAt (auqol_front_spotters find _unit);
        if (!alive _unit || {!local _unit}) then { continue };
        if (currentWeapon _unit == binocular _unit && _weapon != "") then { _unit selectWeapon _weapon };
        if (_setStance && {unitPos _unit == "Middle"}) then { _unit setUnitPos "AUTO" };
        _unit doWatch objNull;
        // An order you gave wins; otherwise back into formation.
        if (!_ordered && {stopped _unit} && {!captive _unit}) then { _unit doFollow leader _unit };
        [format ["Spotter: %1 stopped spotting", name _unit], true] call AUQOL_fnc_log;
        continue;
    };
    // AI put the binoculars away by themselves; take them out again.
    if (currentWeapon _unit != binocular _unit) then { _unit selectWeapon binocular _unit };
    // Steps -2..2 and back: 0 1 2 3 4 3 2 1 0 ... mapped to -2..2.
    _step = _step + 1;
    _spot set [1, _step];
    private _offset = (abs ((_step + 2) % 8 - 4)) - 2;
    private _look = (_dir + _offset * 15 + 360) % 360;
    private _eye = eyePos _unit;
    _unit doWatch ASLToAGL (_eye vectorAdd [100 * sin _look, 100 * cos _look, 0]);
    private _light = [1 - 0.8 * _dark, 1] select ([_unit] call AUQOL_fnc_nightHasVision);
    private _found = (_unit nearEntities [["CAManBase", "LandVehicle", "Air", "Ship"], 1000]) select {
        alive _x && {!captive _x} && {[side _x] call AUQOL_fnc_isHostileSide} && {_group knowsAbout _x < 1.5}
        && {abs (((_unit getDir _x) - _look + 540) % 360 - 180) <= 10}
        && {random 1 < ([_unit, "VIEW", _x] checkVisibility [_eye, aimPos _x]) * (1 - 0.5 * (_unit distance _x) / 1000) * _light}
    };
    if (_found isEqualTo []) then { continue };
    { private _found1 = _x; { _x reveal [_found1, 4] } forEach (units _group select { local _x }) } forEach _found;
    { [_group, _x, true, 4] call AUQOL_fnc_combatShareContact } forEach (_found select [0, 3]);
    [_found select 0, _unit] call AUQOL_fnc_squadCallout;
    [] call AUQOL_fnc_squadLaunchers;
    [format ["Spotter: %1 spotted %2 enemies on bearing %3", name _unit, count _found, round _look], true] call AUQOL_fnc_log;
} forEach +auqol_front_spotters;

if (auqol_front_spotters isEqualTo []) then {
    [auqol_front_spotHandler] call CBA_fnc_removePerFrameHandler;
    auqol_front_spotHandler = -1;
};
