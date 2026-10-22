/*
    Author: AUQOL
    Keeps the AI of a player-led group on the enemy the player last revealed with the Reveal target
    key (AUQOL_fnc_squadRevealTarget). Every AI local to this machine that is not already attacking it
    is told to target it, and to fire at it when its combat mode allows firing (YELLOW or RED). The
    engine's own target choice stays in charge of which weapon and when; this only puts the revealed
    enemy first. The focus ends when that enemy is out of the fight (AUQOL_fnc_squadIsOutOfFight), so
    a crippled vehicle does not keep drawing fire. A gunner holding his launcher on a vehicle that is
    still in the fight keeps it; one holding it with no such vehicle takes his rifle when the focus is a soldier, and a unit treating itself (AUQOL_fnc_squadSelfTreat) finishes first. Called on the key press and every second after it.

    Arguments:
    0: Group <GROUP>

    Return Value: <BOOL> true while the focus is still active
*/

params [["_group", grpNull, [grpNull]]];
if (isNull _group) exitWith { false };

(_group getVariable ["auqol_revealFocus", []]) params [["_target", objNull], ["_until", 0]];
if ([_target] call AUQOL_fnc_squadIsOutOfFight || {time > _until} || {!auqol_squad_revealKey} || {leader _group isNotEqualTo player}) exitWith {
    _group setVariable ["auqol_revealFocus", nil];
    false
};

{
    if (getAttackTarget _x isNotEqualTo _target) then {
        // A rocket is wasted on a soldier: a gunner with his launcher out takes his rifle for this one.
        if (_target isKindOf "Man" && {currentWeapon _x == secondaryWeapon _x} && {primaryWeapon _x != ""}) then { _x selectWeapon primaryWeapon _x };
        _x doTarget _target;
        // doFire would cancel a walk to cover or into a building (overwatch, breach); the unit fires on arrival.
        private _dest = _x getVariable "auqol_tacDest";
        // Within 400 m and in sight only: a fire order from farther away plants the unit (AUQOL_fnc_squadUnpin frees it).
        if (combatMode _x in ["YELLOW", "RED"] && {isNil "_dest" || {_x distance2D _dest < 2.5}} && {_x distance _target < 400}
            && {([_x, "VIEW", _target] checkVisibility [eyePos _x, aimPos _target]) > 0.3}) then { _x doFire _target };
    };
} forEach (units _group select {
    local _x && {!isPlayer _x} && {alive _x} && {lifeState _x != "INCAPACITATED"} && {!(_x getVariable ["incapacitated", false])}
    && {time >= _x getVariable ["auqol_treatUntil", 0]}
    // A gunner with his launcher on a vehicle still in the fight keeps it (AUQOL_fnc_squadLaunchers): an AA round belongs to the jet, not to the focus.
    && {currentWeapon _x != secondaryWeapon _x || {secondaryWeapon _x == ""} || {(getAttackTarget _x) isKindOf "Man"} || {[getAttackTarget _x] call AUQOL_fnc_squadIsOutOfFight}}
});
true
