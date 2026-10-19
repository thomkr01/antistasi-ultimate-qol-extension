/*
    Author: AUQOL
    Runs when the local player presses the Reveal target key (T by default). If the player is looking
    at a living enemy, every unit of the player's group local to this machine gets full knowledge of
    it, and when the player leads the group its AI are told to target it. They then open fire under
    their current combat mode, so a Hold fire order is still respected. The launcher check runs right after.

    Arguments: none
    Return Value: none
*/

if (!hasInterface || {!auqol_ready} || {!auqol_squad_revealKey}) exitWith {};

private _player = player;
if (isNull _player || {!alive _player}) exitWith {};

private _target = cursorTarget;
if (isNull _target) then { _target = cursorObject };
if (isNull _target || {!alive _target} || {!(_target isKindOf "AllVehicles")}) exitWith {};
if !([side _target] call AUQOL_fnc_isHostileSide) exitWith {};

private _group = group _player;
private _local = units _group select { local _x };
{ _x reveal [_target, 4] } forEach _local;

if (leader _group isEqualTo _player) then {
    { _x doTarget _target } forEach (_local select { !isPlayer _x && {alive _x} });
};

// Knowledge just changed, so check launchers now instead of at the next pass.
call AUQOL_fnc_squadLaunchers;

[format ["Reveal: %1 (%2) shown to %3 units", typeOf _target, side _target, count _local], true] call AUQOL_fnc_log;
