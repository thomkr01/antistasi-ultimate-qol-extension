/*
    Author: AUQOL
    Hands a unit back after smart combat tactics: forgets its team and spot, puts its stance back to
    the AI's choice if AUQOL had set it (and nobody changed it since), and sends it back into
    formation if AUQOL had moved it and it can still move.

    Arguments:
    0: Unit <OBJECT>

    Return Value: none
*/

params ["_unit"];
if (isNil {_unit getVariable "auqol_tacTeam"}) exitWith {};

// auqol_tacMoved: the spot was dropped for treatment, but the unit was still sent out and waits where it stopped.
private _moved = !isNil {_unit getVariable "auqol_tacDest"} || {_unit getVariable ["auqol_tacMoved", false]};
{ _unit setVariable [_x, nil] } forEach ["auqol_tacMoved", "auqol_pushTeam", "auqol_tacTeam", "auqol_tacDest", "auqol_tacIndoor", "auqol_tacProgress", "auqol_tacNextSeek"];
if (!local _unit || {!alive _unit}) exitWith { _unit setVariable ["auqol_tacStance", nil] };

if (_unit getVariable ["auqol_tacStance", false]) then {
    if (unitPos _unit == "Middle") then { _unit setUnitPos "AUTO" };
    _unit setVariable ["auqol_tacStance", nil];
};
// A unit that reached its doMove spot waits there until told to follow again.
if (_moved && {_unit checkAIFeature "PATH"} && {currentCommand _unit in ["", "MOVE"]}) then { _unit doFollow leader _unit };
