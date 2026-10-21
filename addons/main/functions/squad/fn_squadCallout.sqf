/*
    Author: AUQOL
    Radio call-out: one of your AI says where a revealed enemy is, in your group chat ("Contact!
    infantry, 2 o'clock, 120 m"), clock position relative to where you face. Called by the Reveal target
    key and by look to spot. Text only, local to the player, at most one every 4 s.
    Arguments:
    0: Enemy <OBJECT>
    Return Value: none
*/
params ["_target"];
if (!auqol_squad_callouts || {!alive _target} || {time < auqol_calloutNext}) exitWith {};
private _speakers = units group player select { !isPlayer _x && {alive _x} && {lifeState _x in ["HEALTHY", "INJURED"]} };
if (_speakers isEqualTo []) exitWith {};
auqol_calloutNext = time + 4;
private _clock = (round ((player getRelDir _target) / 30)) % 12;
private _what = ["enemy infantry", getText (configOf _target >> "displayName")] select !(_target isKindOf "Man");
(selectRandom _speakers) groupChat format ["Contact! %1, %2 o'clock, %3 m", _what, [_clock, 12] select (_clock == 0), round (player distance _target / 10) * 10];
