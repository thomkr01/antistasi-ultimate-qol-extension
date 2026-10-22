/*
    Author: AUQOL
    Ambush discipline. While you lead your group in STEALTH behaviour with its combat mode on fire at
    will (YELLOW or RED), the group is put on Hold fire (GREEN) so nobody gives the position away; the
    first shot you fire (the Fired handler, XEH_postInit), leaving STEALTH, or a combat mode you set
    yourself puts the original mode back and the whole squad opens up on what it knows. Under Hold fire
    the engine still lets AI defend themselves. Runs every second on the player's machine.
    Arguments:
    0: You fired <BOOL> (default: false)
    Return Value: none
*/
params [["_fired", false]];
private _player = player;
if (!hasInterface || {isNull _player}) exitWith {};
private _group = group _player;
// A group held earlier that is no longer yours (you changed group) gets its mode back.
private _old = missionNamespace getVariable ["auqol_ambushGroup", grpNull];
if (!isNull _old && _old isNotEqualTo _group) then {
    private _oldMode = _old getVariable ["auqol_ambushMode", ""];
    if (_oldMode != "" && {local _old} && {combatMode _old == "GREEN"}) then { _old setCombatMode _oldMode };
    _old setVariable ["auqol_ambushMode", nil];
    auqol_ambushGroup = grpNull;
};
if (!local _group) exitWith {};
private _held = _group getVariable ["auqol_ambushMode", ""];
private _stealth = auqol_squad_ambush && {leader _group isEqualTo _player} && {behaviour _player == "STEALTH"};
// Your own shot also ends the ambush for as long as you stay in Stealth.
if (_fired && _stealth) then { _group setVariable ["auqol_ambushDone", true] };
if (_held != "") exitWith {
    if (_fired || {!_stealth} || {combatMode _group != "GREEN"}) then {
        // A mode you set yourself while holding stays.
        if (combatMode _group == "GREEN") then { _group setCombatMode _held };
        _group setVariable ["auqol_ambushMode", nil];
        // Once ended, the hold does not start again until you leave Stealth (else it would be back within a second).
        _group setVariable ["auqol_ambushDone", true];
    };
};
if (!_stealth) then { _group setVariable ["auqol_ambushDone", nil] };
if (_stealth && {!_fired} && {!(_group getVariable ["auqol_ambushDone", false])} && {combatMode _group in ["YELLOW", "RED"]}) then {
    _group setVariable ["auqol_ambushMode", combatMode _group];
    auqol_ambushGroup = _group;
    _group setCombatMode "GREEN";
};
