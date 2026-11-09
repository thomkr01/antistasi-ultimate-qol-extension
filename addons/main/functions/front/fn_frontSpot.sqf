/*
    Author: AUQOL
    "Spot with binoculars" from the command menu: each given AI of your group (local, on foot) with anything in
    its binocular slot (vanilla, RHS, CUP, ACE binoculars, rangefinders and laser designators) stops, takes out
    the binoculars and sweeps the 60 degree sector centred on the bearing you looked at
    (AUQOL_fnc_frontSpotTick). No AI feature is switched off: the unit is only stopped (doStop), so every other
    AUQOL system leaves it alone (stopped units are skipped by smart combat, overwatch, push, breach, unpin and
    stuck recovery), and any order you give it ends the spotting. AI without binoculars say so.

    Arguments:
    0: AI you had selected <ARRAY>
    1: Bearing to watch <NUMBER>

    Return Value: none
*/
params [["_units", []], ["_dir", 0]];
if (!hasInterface || {!auqol_ready} || {!auqol_front_spotter}) exitWith {};
_dir = (round _dir + 360) % 360;
{
    private _unit = _x;
    if (_unit getVariable ["auqol_spot", []] isNotEqualTo []) then {
        // Already spotting: only the sector moves.
        (_unit getVariable "auqol_spot") set [0, _dir];
        _unit groupChat format ["Copy, shifting to bearing %1.", [_dir, 3] call CBA_fnc_formatNumber];
        continue;
    };
    if (binocular _unit == "") then { _unit groupChat "Negative, no binoculars."; continue };
    // [centre bearing, step (-2..2), weapon before, stance AUQOL set, damage at start, end time]
    private _setStance = unitPos _unit == "Auto";
    _unit setVariable ["auqol_spot", [_dir, -2, currentWeapon _unit, _setStance, damage _unit, time + 300]];
    doStop _unit;
    if (_setStance) then { _unit setUnitPos "MIDDLE" };
    _unit selectWeapon binocular _unit;
    auqol_front_spotters pushBackUnique _unit;
    _unit groupChat format ["Copy, spotting bearing %1.", [_dir, 3] call CBA_fnc_formatNumber];
} forEach (_units select { local _x && {!isPlayer _x} && {alive _x} && {group _x isEqualTo group player} && {isNull objectParent _x} && {lifeState _x in ["HEALTHY", "INJURED"]} });

if (auqol_front_spotters isNotEqualTo [] && auqol_front_spotHandler < 0) then {
    // One 5 s handler for every spotter, only while there is one.
    auqol_front_spotHandler = [{ ["binocular spotter", { [] call AUQOL_fnc_frontSpotTick }] call AUQOL_fnc_perfRun }, 5] call CBA_fnc_addPerFrameHandler;
};
