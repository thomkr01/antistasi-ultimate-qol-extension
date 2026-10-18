/*
    Author: AUQOL
    Reports a stuck-recovery event for one unit. The RPT line is debug-only. The system chat line goes
    only to the player leading the unit's group (through a CBA target event when that player is on
    another machine) and only when the matching setting is on. Lines are bounded by design: one when a
    unit gets stuck, one per step, one per finished round, one when it moves again.

    Arguments:
    0: Unit <OBJECT>
    1: Message without the unit name <STRING>
    2: Kind: "detect" (stuck, step tried) or "result" (moving again, round failed) <STRING>

    Return Value: none
*/

params ["_unit", "_message", "_kind"];

private _text = format ["%1 %2", name _unit, _message];
[format ["Stuck AI: %1 at %2", _text, mapGridPosition _unit], true] call AUQOL_fnc_log;

if !([auqol_stuck_notifyResult, auqol_stuck_notifyDetect] select (_kind == "detect")) exitWith {};

private _leader = leader group _unit;
if (!isPlayer _leader) exitWith {};
if (local _leader) then {
    systemChat ("[AUQOL] " + _text);
} else {
    ["auqol_stuck_message", [_text], _leader] call CBA_fnc_targetEvent;
};
