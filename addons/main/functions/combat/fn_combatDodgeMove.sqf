/*
    Author: AUQOL
    The dodge itself, run on every machine by the "auqol_combat_dodge" event (AUQOL_fnc_combatDodge sends
    it from the thrower's machine): every AI on foot within 10 m of the grenade that is local to this
    machine runs 12 m directly away from it and rejoins formation 6 s later.

    Arguments:
    0: Grenade position <ARRAY> (ATL)

    Return Value: none
*/

params ["_pos"];
{
    private _unit = _x;
    _unit setVariable ["auqol_tacDest", nil];
    private _spot = _pos getPos [12, _pos getDir _unit];
    _unit doMove _spot;
    _unit setVariable ["auqol_tacDodge", true];
    [{
        params ["_unit"];
        if (alive _unit && {local _unit} && {_unit getVariable ["auqol_tacDodge", false]} && {currentCommand _unit in ["", "MOVE"]}) then {
            private _group = group _unit;
            // A leader has nobody to follow: his current waypoint is set again (the stuck recovery's refresh), so Antistasi's patrol carries on.
            if (_unit isEqualTo leader _group) then {
                if (currentWaypoint _group < count waypoints _group) then { _group setCurrentWaypoint [_group, currentWaypoint _group] };
            } else { _unit doFollow leader _unit };
        };
        _unit setVariable ["auqol_tacDodge", nil];
    }, [_unit], 6] call CBA_fnc_waitAndExecute;
} forEach ((_pos nearEntities ["CAManBase", 10]) select { [_x] call AUQOL_fnc_combatIsEligible });
