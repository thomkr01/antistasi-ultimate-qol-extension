/*
    Author: AUQOL
    Radio call-out: one of your AI says where an enemy is, in your group chat ("Contact! infantry, bearing 313,
    120 m"), the direction in the system chosen with auqol_front_system and always seen from you
    (AUQOL_fnc_frontDirection), and the bearing dial shows him (AUQOL_fnc_frontHud). Called when your group spots
    a new enemy, by the Reveal target key, look to spot and the binocular spotter, at most one every 4 s; the
    "Where is it?" menu asks for one at once. Text only, local to the player.
    Arguments:
    0: Enemy <OBJECT>
    1: Who says it <OBJECT> (optional, default: a random AI of your group)
    2: Asked for in the menu: ignores the 4 s limit and auqol_squad_callouts <BOOL> (optional, default: false)
    Return Value: none
*/
params ["_target", ["_speaker", objNull], ["_force", false]];
if (!hasInterface || {!alive _target} || {!_force && {!auqol_squad_callouts || {time < auqol_calloutNext}}}) exitWith {};
if (isNull _speaker) then {
    private _speakers = units group player select { !isPlayer _x && {alive _x} && {lifeState _x in ["HEALTHY", "INJURED"]} };
    if (_speakers isNotEqualTo []) then { _speaker = selectRandom _speakers };
};
if (isNull _speaker) exitWith {};
auqol_calloutNext = time + 4;
private _what = ["enemy infantry", getText (configOf _target >> "displayName")] select !(_target isKindOf "Man");
_speaker groupChat format ["Contact! %1, %2, %3 m", _what, [_target] call AUQOL_fnc_frontDirection, round (player distance _target / 10) * 10];
[_target] call AUQOL_fnc_frontHud;
