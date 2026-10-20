/*
    Author: AUQOL
    Runs when the local player presses the Reveal target key (T by default). If the player is looking
    at a living enemy, or else at one within 15 degrees of where he looks (the nearest to his aim that
    he can see, within 1500 m), every unit of the player's group local to this machine gets full knowledge of
    it. When the player leads the group, that enemy becomes the squad's focus for 30 s: the newest
    press always replaces the previous focus (the old enemy stays known), and AUQOL_fnc_squadRevealFocus
    re-issues the order every second to any AI that turned to another target, until the enemy dies.
    They fire under their current combat mode, so a Hold fire order is still respected. The launcher
    check runs right after, and nearby friendly AI groups are told about the enemy
    (AUQOL_fnc_combatShareContact). A short CBA notification on this player's screen confirms the press.

    Arguments: none
    Return Value: none
*/

if (!hasInterface || {!auqol_ready} || {!auqol_squad_revealKey}) exitWith {};

private _player = player;
if (isNull _player || {!alive _player}) exitWith {};

private _target = cursorTarget;
if (isNull _target || {!alive _target}) then { _target = cursorObject };
// Not aiming exactly at an enemy: the visible one nearest to where the player looks, within 15 degrees and 1500 m.
if (isNull _target || {!alive _target} || {!(_target isKindOf "AllVehicles")} || {!([side _target] call AUQOL_fnc_isHostileSide)}) then {
    private _eye = AGLToASL positionCameraToWorld [0, 0, 0];
    private _look = getCameraViewDirection _player;
    private _best = 15;
    _target = objNull;
    {
        private _angle = acos (_look vectorCos (aimPos _x vectorDiff _eye));
        if (_angle < _best && {alive _x} && {[side _x] call AUQOL_fnc_isHostileSide} && {([_player, "VIEW", _x] checkVisibility [_eye, aimPos _x]) > 0.2}) then {
            _best = _angle;
            _target = _x;
        };
    } forEach (_player nearEntities [["CAManBase", "LandVehicle", "Air", "Ship"], 1500]);
};
if (isNull _target) exitWith {};

private _group = group _player;
private _local = units _group select { local _x };
{ _x reveal [_target, 4] } forEach _local;

if (leader _group isEqualTo _player) then {
    _group setVariable ["auqol_revealFocus", [_target, time + 30]];
    [_group] call AUQOL_fnc_squadRevealFocus;
    // One 1 s handler per group; it reads the current focus, so a new press only replaces the variable.
    if (isNil {_group getVariable "auqol_revealHandler"}) then {
        _group setVariable ["auqol_revealHandler", [{
            params ["_group", "_handler"];
            if !([_group] call AUQOL_fnc_squadRevealFocus) then {
                [_handler] call CBA_fnc_removePerFrameHandler;
                if (!isNull _group) then { _group setVariable ["auqol_revealHandler", nil] };
            };
        }, 1, _group] call CBA_fnc_addPerFrameHandler];
    };
};

// Nearby friendly AI groups learn about it too (smart combat contact sharing).
[_group, _target, true] call AUQOL_fnc_combatShareContact;

// Knowledge just changed, so check launchers now instead of at the next pass.
[] call AUQOL_fnc_squadLaunchers;

// Feedback for the player who pressed the key only, nothing sent over the network.
[format ["%1 marked for your squad", getText (configOf _target >> "displayName")]] call CBA_fnc_notify;

[format ["Reveal: %1 (%2) shown to %3 units", typeOf _target, side _target, count _local], true] call AUQOL_fnc_log;
