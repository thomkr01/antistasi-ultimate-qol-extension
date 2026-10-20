/*
    Author: AUQOL
    Smart combat reactions, from the unit's Suppressed event (a hostile round passed close). Runs where
    the unit is local, at most once every 2 s per unit:
    - auqol_combat_revealShooter: the unit's group learns where the fire came from, so it can answer
      it instead of scanning for it. reveal only ever raises knowledge. Not for a shooter farther away
      than his shot gives him away (hard to locate).
    - auqol_combat_takeCover: a standing AI on foot crouches, or goes prone under heavy fire, and goes
      back to its own stance choice 10 s after the last close round, unless it sits behind outdoor cover
      that smart combat picked, where it stays crouched and smart combat's fire team pass takes the stance over. Never prone with auqol_combat_noProne. Only units whose stance is left to
      the AI ("Auto") are touched, so stance orders from players, Antistasi or other mods win. Groups led
      by a player are skipped: their stance is the player's call.
    It also starts smart combat tactics for the unit's group (AUQOL_fnc_combatStart).
    Everything stands down when LAMBS Danger or Vcom AI is loaded and auqol_combat_yieldToAIMods is on, since
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
[_unit] call AUQOL_fnc_combatGroupHook;
[group _unit] call AUQOL_fnc_combatStart;

private _enemy = [_instigator, _shooter] select isNull _instigator;
// Hard to locate (AUQOL_fnc_concealLocateCheck): a round from beyond the distance where a shot gives the
// shooter away doesn't tell this group where he is, so no reveal and no firing back at him.
private _locate = _enemy getVariable ["auqol_locate", []];
if (_locate isNotEqualTo [] && {time - (_locate select 0) < 5}
    && {_unit distance _enemy > ([_locate select 1, _locate select 2] select ([_unit] call AUQOL_fnc_nightHasVision))}) then { _enemy = objNull };
if (auqol_combat_revealShooter && {alive _enemy}) then { (group _unit) reveal [_enemy, 1.5] };

if (isPlayer leader group _unit) exitWith {};

// Fire back: the whole group suppresses harder for 15 s (AUQOL_fnc_combatTick), and this unit answers
// at once at where it believes the shooter is, if it can't see him (seen, the engine aims anyway) and
// isn't on its way to cover.
if (auqol_combat_suppressiveFire && {alive _enemy}) then {
    (group _unit) setVariable ["auqol_tacUnderFire", time + 15];
    private _dest = _unit getVariable "auqol_tacDest";
    private _ePos = _unit getHideFrom _enemy;
    if ((isNil "_dest" || {_unit distance2D _dest < 2.5}) && {_ePos isNotEqualTo [0, 0, 0]} && {_unit distance2D _ePos < 400}
        && {currentWeapon _unit isEqualTo primaryWeapon _unit} && {[_unit] call AUQOL_fnc_combatIsEligible}
        && {([_unit, "VIEW", _enemy] checkVisibility [eyePos _unit, aimPos _enemy]) < 0.3}) then {
        _unit doSuppressiveFire (AGLToASL _ePos vectorAdd [0, 0, 1]);
    };
};

if (!auqol_combat_takeCover || {!isNull objectParent _unit} || {lifeState _unit == "INCAPACITATED"}) exitWith {};

private _ours = _unit getVariable ["auqol_combatCover", false];
// Someone else changed the stance since AUQOL set it: theirs stays.
if (_ours && {!(unitPos _unit in ["Middle", "Down"])}) exitWith {};
if (!_ours && {unitPos _unit != "Auto" || {stance _unit != "STAND"}}) exitWith {};
_unit setVariable ["auqol_combatCoverUntil", time + 10];

_unit setUnitPos (["MIDDLE", "DOWN"] select (!auqol_combat_noProne && {getSuppression _unit > 0.8}));
if (_ours) exitWith {};
_unit setVariable ["auqol_combatCover", true];

private _restore = {
    params ["_unit", "_restore"];
    if (!alive _unit) exitWith {};
    private _left = (_unit getVariable ["auqol_combatCoverUntil", 0]) - time;
    if (_left > 0 && {local _unit} && auqol_combat_takeCover) exitWith { [_restore, _this, _left] call CBA_fnc_waitAndExecute };
    _unit setVariable ["auqol_combatCover", nil];
    if (!local _unit || {!(unitPos _unit in ["Middle", "Down"])}) exitWith {};
    // Behind outdoor cover that smart combat picked: stay crouched, and the fire team pass now owns the stance.
    private _dest = _unit getVariable "auqol_tacDest";
    if (!isNil "_dest" && {_unit distance2D _dest < 2.5} && {!(_unit getVariable ["auqol_tacIndoor", false])}) exitWith {
        _unit setUnitPos "MIDDLE";
        _unit setVariable ["auqol_tacStance", true];
    };
    _unit setUnitPos "AUTO";
};
[_restore, [_unit, _restore], 10] call CBA_fnc_waitAndExecute;
