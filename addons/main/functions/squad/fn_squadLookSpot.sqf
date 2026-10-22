/*
    Author: AUQOL
    Look to spot. Every 0.5 s on the player's machine: living hostile soldiers and vehicles within 1500 m
    that the player can see and that are within auqol_squad_lookAngle degrees of the centre of the view
    are revealed with full knowledge (reveal level 4, as the T key) to the AI of the player's group local
    to this machine, unless the group already knows them at that level, and told to nearby friendly AI
    groups at the same level (AUQOL_fnc_combatShareContact). Every enemy in the cone counts. Squad AI that
    are not attacking anything yet target the enemy nearest the crosshair and fire when their combat
    mode allows (1.31.0), so they open up as fast as after T. No 30 s focus is set: AI already in a fight
    keep their own target, and the Reveal target key (AUQOL_fnc_squadRevealTarget) keeps its focus
    behaviour. The launcher check runs when something new was revealed. No message is shown. Skipped
    while the map is open.

    Arguments: none
    Return Value: none
*/

if (!auqol_ready || {!auqol_squad_lookSpot} || {visibleMap}) exitWith {};

private _player = player;
if (isNull _player || {!alive _player} || {lifeState _player == "INCAPACITATED"}) exitWith {};

private _group = group _player;
private _ai = units _group select { local _x && {!isPlayer _x} && {alive _x} };
if (_ai isEqualTo []) exitWith {};

private _eye = AGLToASL positionCameraToWorld [0, 0, 0];
private _look = getCameraViewDirection _player;
private _new = (_player nearEntities [["CAManBase", "LandVehicle", "Air", "Ship"], 1500]) select {
    alive _x && {!captive _x} && {acos (_look vectorCos (aimPos _x vectorDiff _eye)) < auqol_squad_lookAngle}
    && {[side _x] call AUQOL_fnc_isHostileSide} && {_group knowsAbout _x < 4}
    && {([_player, "VIEW", _x] checkVisibility [_eye, aimPos _x]) > 0.2}
};
if (_new isEqualTo []) exitWith {};

{
    private _unit = _x;
    { _unit reveal [_x, 4] } forEach _new;
} forEach _ai;

// Idle AI open fire like after T (only when you lead the group, as the T focus): the enemy nearest the crosshair, under their own combat mode. Units walking
// to cover or a breach spot only aim (doFire would cancel the walk), and a unit treating itself finishes first.
private _byAim = _new apply { [acos (_look vectorCos (aimPos _x vectorDiff _eye)), _x] };
_byAim sort true;
private _first = _byAim select 0 select 1;
{
    // A rocket is wasted on a soldier: a gunner with his launcher out takes his rifle, as with the T focus.
    if (_first isKindOf "Man" && {currentWeapon _x == secondaryWeapon _x} && {primaryWeapon _x != ""}) then { _x selectWeapon primaryWeapon _x };
    _x doTarget _first;
    private _dest = _x getVariable "auqol_tacDest";
    if (combatMode _x in ["YELLOW", "RED"] && {isNil "_dest" || {_x distance2D _dest < 2.5}}) then { _x doFire _first };
} forEach ([[], _ai] select (leader _group isEqualTo _player) select {
    isNull getAttackTarget _x && {lifeState _x != "INCAPACITATED"} && {time >= _x getVariable ["auqol_treatUntil", 0]}
});

// Reveal level 4 fades, so an enemy you keep looking at comes back here: the call-out, the ally share and
// the log only repeat for it after 20 s.
_new = _new select { time - (_x getVariable ["auqol_lookAt", -100]) > 20 };
if (_new isEqualTo []) exitWith {};
{ _x setVariable ["auqol_lookAt", time] } forEach _new;

// Nearby friendly AI groups (300 m, smart combat contact sharing) learn about up to three of them too,
// at the same level, so their own combat starts. Only knowledge is shared, no orders.
{ [_group, _x, true, 4] call AUQOL_fnc_combatShareContact } forEach (_new select [0, 3]);

[_new select 0] call AUQOL_fnc_squadCallout;
[] call AUQOL_fnc_squadLaunchers;
[format ["Look to spot: %1 enemies revealed to %2 units", count _new, count _ai]] call AUQOL_fnc_log;
