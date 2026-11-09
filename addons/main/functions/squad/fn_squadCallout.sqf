/*
    Author: AUQOL
    Radio call-out: one of your AI (or, from the radio net, a post) says where an enemy is, in your group chat ("Contact! infantry, bearing 313,
    120 m"), the direction in the system chosen with auqol_front_system and always seen from you
    (AUQOL_fnc_frontDirection), and the bearing dial shows him (AUQOL_fnc_frontHud). Called when your group spots
    a new enemy, by look to spot and the binocular spotter, at most one every 4 s; the Reveal target key and the
    "Where is it?" menu get one at once. Text only, local to the player.
    Arguments:
    0: Enemy <OBJECT>
    1: Who says it <OBJECT> (optional, default: a random AI of your group)
    2: Now <BOOL> (optional, default: false): ignores the 4 s limit (the T key); with a speaker also auqol_squad_callouts (the menu)
    3: From <STRING> (optional, default: ""): a radio net call-out from another group ("AA post"), said in side chat
       with that name first; side chat needs a radio on both ends, so without one it shows in system chat
    Return Value: none
*/
params ["_target", ["_speaker", objNull], ["_force", false], ["_from", ""]];
// The menu (a speaker and force) always answers; the T key (force) skips the 4 s limit but respects the setting.
if (!hasInterface || {!alive _target} || {!auqol_squad_callouts && {!_force || {isNull _speaker}}} || {!_force && {time < auqol_calloutNext}}) exitWith {};
if (isNull _speaker && _from isEqualTo "") then {
    private _speakers = units group player select { !isPlayer _x && {alive _x} && {lifeState _x in ["HEALTHY", "INJURED"]} };
    if (_speakers isNotEqualTo []) then { _speaker = selectRandom _speakers };
};
if (isNull _speaker) exitWith {};
auqol_calloutNext = time + 4;
private _what = ["enemy infantry", getText (configOf _target >> "displayName")] select !(_target isKindOf "Man");
private _text = format ["Contact! %1, %2, %3 m", _what, [_target] call AUQOL_fnc_frontDirection, round (player distance _target / 10) * 10];
call {
    if (_from isEqualTo "") exitWith { _speaker groupChat _text };
    _text = format ["%1: %2", _from, _text];
    if ([player] call AUQOL_fnc_radioItem && {[_speaker] call AUQOL_fnc_radioItem}) exitWith { _speaker sideChat _text };
    systemChat _text;
};
[_target] call AUQOL_fnc_frontHud;
