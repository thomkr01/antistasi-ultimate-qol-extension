/*
    Author: AUQOL
    Clears scratches: damage so light that nothing on the vehicle is actually broken, which still makes
    the game offer "Repair" (vanilla, ACE repair) after a single bullet. Runs from the vehicle's
    Dammaged handler where the vehicle is local. One check 2 s after the first hit of a burst: when
    the overall damage and every hit point are below auqol_service_scratchLevel, the vehicle is set
    back to undamaged, so the repair prompt only shows when there is something to fix. Anything at or
    above the level is left as it is, including the rest of the damage. Any vehicle, any mod: only
    damage values are read.

    Arguments:
    0: Vehicle <OBJECT>

    Return Value: none
*/

params ["_vehicle"];
if (!auqol_ready || {!auqol_service_scratches} || {!local _vehicle} || {_vehicle getVariable ["auqol_scratchPending", false]}) exitWith {};
_vehicle setVariable ["auqol_scratchPending", true];

[{
    params ["_vehicle"];
    _vehicle setVariable ["auqol_scratchPending", nil];
    if (!alive _vehicle || {!local _vehicle}) exitWith {};
    private _worst = selectMax (((getAllHitPointsDamage _vehicle) param [2, []]) + [damage _vehicle]);
    if (_worst > 0 && _worst < auqol_service_scratchLevel) then {
        _vehicle setDamage [0, false];
        [format ["Scratches: cleared %1 (worst damage %2)", typeOf _vehicle, _worst], true] call AUQOL_fnc_log;
    };
}, [_vehicle], 2] call CBA_fnc_waitAndExecute;
