/*
    Author: AUQOL
    Smart combat reactions, from the unit's Suppressed event (a hostile round passed close). Runs where
    the unit is local, at most once every 2 s per unit:
    - auqol_combat_revealShooter: the unit's group learns where the fire came from, so it can answer
      it instead of scanning for it. reveal only ever raises knowledge.
    - auqol_combat_takeCover: a standing AI on foot crouches, or goes prone under heavy fire, and goes
      back to its own stance choice 10 s after the last close round. Only units whose stance is left to
      the AI ("Auto") are touched, so stance orders from players, Antistasi or other mods win. Groups led
      by a player are skipped: their stance is the player's call.
    Both stand down when LAMBS Danger or Vcom AI is loaded and auqol_combat_yieldToAIMods is on, since
    those mods already react to suppression.

    Arguments:
    0: Unit <OBJECT>
    2: Shooter <OBJECT>
    3: Instigator <OBJECT>

    Return Value: none
*/

params ["_unit", "", "_shooter", "_instigator"];
if (!local _unit || {!auqol_ready} || {isPlayer _unit} || {!alive _unit} || {captive _unit}) exitWith {};
if (auqol_combat_yieldToAIMods && auqol_combat_aiModLoaded) exitWith {};
if (time < _unit getVariable ["auqol_combatNext", 0]) exitWith {};
_unit setVariable ["auqol_combatNext", time + 2];

private _enemy = [_instigator, _shooter] select isNull _instigator;
if (auqol_combat_revealShooter && {alive _enemy}) then { (group _unit) reveal [_enemy, 1.5] };

if (!auqol_combat_takeCover || {!isNull objectParent _unit} || {isPlayer leader group _unit} || {lifeState _unit == "INCAPACITATED"}) exitWith {};

private _ours = _unit getVariable ["auqol_combatCover", false];
// Someone else changed the stance since AUQOL set it: theirs stays.
if (_ours && {!(unitPos _unit in ["Middle", "Down"])}) exitWith {};
if (!_ours && {unitPos _unit != "Auto" || {stance _unit != "STAND"}}) exitWith {};
_unit setVariable ["auqol_combatCoverUntil", time + 10];

_unit setUnitPos (["MIDDLE", "DOWN"] select (getSuppression _unit > 0.8));
if (_ours) exitWith {};
_unit setVariable ["auqol_combatCover", true];

private _restore = {
    params ["_unit", "_restore"];
    if (!alive _unit) exitWith {};
    private _left = (_unit getVariable ["auqol_combatCoverUntil", 0]) - time;
    if (_left > 0 && {local _unit} && auqol_combat_takeCover) exitWith { [_restore, _this, _left] call CBA_fnc_waitAndExecute };
    _unit setVariable ["auqol_combatCover", nil];
    if (local _unit && {unitPos _unit in ["Middle", "Down"]}) then { _unit setUnitPos "AUTO" };
};
[_restore, [_unit, _restore], 10] call CBA_fnc_waitAndExecute;
