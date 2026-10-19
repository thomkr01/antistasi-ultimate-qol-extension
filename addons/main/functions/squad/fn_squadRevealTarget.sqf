/*
    Author: AUQOL
    Runs when the local player presses the Reveal target key (T by default). If the player is looking
    at a living enemy, every unit of the player's group local to this machine gets full knowledge of
    it. When the player leads the group, that enemy becomes the squad's focus for 30 s: the newest
    press always replaces the previous focus (the old enemy stays known), and AUQOL_fnc_squadRevealFocus
    re-issues the order every second to any AI that turned to another target, until the enemy dies.
    They fire under their current combat mode, so a Hold fire order is still respected. The launcher
    check runs right after, and nearby friendly AI groups are told about the enemy
    (AUQOL_fnc_combatShareContact).

    Arguments: none
    Return Value: none
*/

if (!hasInterface || {!auqol_ready} || {!auqol_squad_revealKey}) exitWith {};

private _player = player;
if (isNull _player || {!alive _player}) exitWith {};

private _target = cursorTarget;
if (isNull _target || {!alive _target}) then { _target = cursorObject };
if (isNull _target || {!alive _target} || {!(_target isKindOf "AllVehicles")}) exitWith {};
if !([side _target] call AUQOL_fnc_isHostileSide) exitWith {};

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
[_group, _target] call AUQOL_fnc_combatShareContact;

// Knowledge just changed, so check launchers now instead of at the next pass.
call AUQOL_fnc_squadLaunchers;

[format ["Reveal: %1 (%2) shown to %3 units", typeOf _target, side _target, count _local], true] call AUQOL_fnc_log;
