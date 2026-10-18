/*
    Author: AUQOL
    Test helper for the debug console: makes the next stuck check treat a unit as already past the
    stuck timeout, so the recovery steps can be watched without waiting. The unit still has to pass
    every eligibility check (it needs a move order or a leader to follow that is more than 8 m away),
    and a unit that is not actually stuck is reported as moving again on the following check.
    Run it where the unit is local ("Local exec" for your own squad in single player or on your client).

    Arguments:
    0: Unit <OBJECT>

    Return Value: Whether the unit is tracked and was marked <BOOL>

    Example: [cursorObject] call AUQOL_fnc_stuckSimulate;
*/

params [["_unit", objNull, [objNull]]];

if (!local _unit) exitWith { systemChat "[AUQOL] Unit is not local here; run this where it is local."; false };
[_unit] call AUQOL_fnc_stuckEvaluate;
private _state = _unit getVariable "auqol_stuck";
if (isNil "_state") exitWith { systemChat "[AUQOL] Unit is not eligible for stuck checks right now (no move order, busy, fighting or in a skipped state)."; false };

_state set ["since", time - auqol_stuck_timeout];
_state set ["nextTry", 0];
_state set ["gaveUp", false];
systemChat format ["[AUQOL] %1 marked as stuck; the next check (within 5 s) runs a recovery step.", name _unit];
true
