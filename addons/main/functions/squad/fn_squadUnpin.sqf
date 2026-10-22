/*
    Author: AUQOL
    Frees squad AI that stand planted on a fire order, every second on the player's machine (1.32.2). A fire or
    attack order (look to spot, the Reveal target focus, a launcher order, the engine's own) keeps a unit on the spot
    shooting instead of following you; when the target is far away, behind cover or already dead to the
    group's knowledge, it can stand there for a long time. A unit of the group you lead (local, on foot) that has
    held such an order for 8 s with you more than 25 m away, and has no target it can really see (none, over
    400 m or checkVisibility under 0.1), is told to follow you again (doFollow). Not touched: units with overwatch,
    breach or push orders (auqol_owUntil, auqol_pushOwned), walking to a smart combat spot, treating, stopped,
    pathing off, incapacitated, captive, in vehicles. Orders you give yourself come later and win.

    Arguments: none
    Return Value: none
*/
private _player = player;
if (!hasInterface || {isNull _player} || {!auqol_squad_unpin}) exitWith {};
private _group = group _player;
if (leader _group isNotEqualTo _player) exitWith {};
{
    private _unit = _x;
    if !(currentCommand _unit in ["FIRE", "ATTACK", "ATTACKFIRE"]) then { _unit setVariable ["auqol_pinAt", nil]; continue };
    private _since = _unit getVariable ["auqol_pinAt", -1];
    if (_since < 0) then { _unit setVariable ["auqol_pinAt", time]; continue };
    if (time - _since < 8 || {_unit distance2D _player < 25}) then { continue };
    if (isNil {_unit getVariable "auqol_owUntil"} && {!(_unit getVariable ["auqol_pushOwned", false])} && {isNil {_unit getVariable "auqol_tacDest"}}
        && {time >= _unit getVariable ["auqol_treatUntil", 0]} && {isNull objectParent _unit} && {!stopped _unit}
        && {_unit checkAIFeature "PATH"} && {lifeState _unit in ["HEALTHY", "INJURED"]} && {!captive _unit}
        && {!(_unit getVariable ["incapacitated", false])} && {!(_unit getVariable ["helping", false])} && {!(_unit getVariable ["rearming", false])}) then {
        private _target = getAttackTarget _unit;
        if (isNull _target || {_unit distance _target > 400} || {([_unit, "VIEW", _target] checkVisibility [eyePos _unit, aimPos _target]) < 0.1}) then {
            _unit setVariable ["auqol_pinAt", nil];
            _unit doFollow _player;
            [format ["Unpin: %1 freed from %2 (target %3, %4 m from you)", name _unit, currentCommand _unit, typeOf _target, round (_unit distance2D _player)], true] call AUQOL_fnc_log;
        };
    };
} forEach (units _group select { local _x && {!isPlayer _x} && {alive _x} });
