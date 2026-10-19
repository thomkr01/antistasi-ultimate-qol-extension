/*
    Author: AUQOL
    Keeps the AI of a player-led group on the enemy the player last revealed with the Reveal target
    key (AUQOL_fnc_squadRevealTarget). Every AI local to this machine that is not already attacking it
    is told to target it, and to fire at it when its combat mode allows firing (YELLOW or RED). The
    engine's own target choice stays in charge of which weapon and when; this only puts the revealed
    enemy first. The focus ends when that enemy is out of the fight (AUQOL_fnc_squadIsOutOfFight), so
    a crippled vehicle does not keep drawing fire. A gunner holding his launcher takes his rifle
    when the focus is a soldier, and a unit treating itself (AUQOL_fnc_squadSelfTreat) finishes first. Called on the key press and every second after it.

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
        if (combatMode _x in ["YELLOW", "RED"]) then { _x doFire _target };
    };
} forEach (units _group select {
    local _x && {!isPlayer _x} && {alive _x} && {lifeState _x != "INCAPACITATED"} && {!(_x getVariable ["incapacitated", false])}
    && {time >= _x getVariable ["auqol_treatUntil", 0]}
});
true
