/*
    Author: AUQOL
    Look to spot. Every 0.5 s on the player's machine: living hostile soldiers and vehicles within 1500 m
    that the player can see and that are within auqol_squad_lookAngle degrees of the centre of the view
    are revealed (reveal level 3) to the AI of the player's group local to this machine, unless the group
    already knows them at that level, and told to nearby friendly AI groups (AUQOL_fnc_combatShareContact). Every enemy in the cone counts. No focus is set, so the squad's smart
    combat AI (fire team target split, launchers) decides which enemy to fight first; the Reveal target
    key (AUQOL_fnc_squadRevealTarget) keeps its focus behaviour. The launcher check runs when something new
    was revealed. Nothing is sent over the network and no message is shown. Skipped while the map is open.

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
    alive _x && {[side _x] call AUQOL_fnc_isHostileSide} && {!captive _x} && {_group knowsAbout _x < 3}
    && {acos (_look vectorCos (aimPos _x vectorDiff _eye)) < auqol_squad_lookAngle}
    && {([_player, "VIEW", _x] checkVisibility [_eye, aimPos _x]) > 0.2}
};
if (_new isEqualTo []) exitWith {};

{
    private _unit = _x;
    { _unit reveal [_x, 3] } forEach _new;
} forEach _ai;

// Nearby friendly AI groups (300 m, smart combat contact sharing) learn about up to three of them too,
// at the same level, so their own combat starts. Only knowledge is shared, no orders.
{ [_group, _x, true, 3] call AUQOL_fnc_combatShareContact } forEach (_new select [0, 3]);

[] call AUQOL_fnc_squadLaunchers;
[format ["Look to spot: %1 enemies revealed to %2 units", count _new, count _ai]] call AUQOL_fnc_log;
