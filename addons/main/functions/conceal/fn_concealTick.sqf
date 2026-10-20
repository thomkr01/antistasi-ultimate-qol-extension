/*
    Author: AUQOL
    Concealment ("hide among the grass"), on each player's machine for the player and, with
    auqol_conceal_squad, the AI of their group local to it. A unit that can hide (AUQOL_fnc_concealCanHide)
    gets its camouflageCoef trait set near 0, so enemy AI can no longer see it, whatever their gear; a
    revealed unit gets back the value it had. Off while Hide Among The Grass is loaded, which then does
    the same job, and after the player switched it off for their squad with the toggle key.

    Revealed for auqol_conceal_cooldown seconds: when hit, when anyone fires within
    auqol_conceal_distance, and when firing too much (AUQOL_fnc_concealOnFired). Getting into a vehicle
    reveals at once, since the trait would hide the whole vehicle.

    Arguments:
    0: Units to check <ARRAY> (optional, default: the player and their local squad AI)

    Return Value: none
*/

if (!hasInterface || {!auqol_ready} || {isNull player}) exitWith {};

params [["_units", nil, [[]]]];
private _on = auqol_conceal_enabled && {!auqol_conceal_hatg};
if (isNil "_units") then {
    _units = [];
    if (_on) then {
        _units pushBack player;
        if (auqol_conceal_squad) then { _units append ((units group player) select { local _x && {!isPlayer _x} }) };
    };
    // Units hidden earlier that left the group or the scope get revealed too.
    { _units pushBackUnique _x } forEach (auqol_conceal_hidden select { !isNull _x });
};

{
    private _unit = _x;
    if (isNil {_unit getVariable "auqol_conceal"} && {alive _unit}) then {
        _unit setVariable ["auqol_conceal", true];
        private _reveal = { (_this select 0) setVariable ["auqol_concealUntil", time + auqol_conceal_cooldown]; [[_this select 0]] call AUQOL_fnc_concealTick };
        _unit addEventHandler ["Dammaged", _reveal];
        _unit addEventHandler ["FiredNear", { params ["_unit", "_firer", "_distance"]; if (_firer != _unit && _distance <= auqol_conceal_distance) then { _this call (_unit getVariable "auqol_concealReveal") } }];
        _unit setVariable ["auqol_concealReveal", _reveal];
        _unit addEventHandler ["GetInMan", { [[_this select 0]] call AUQOL_fnc_concealTick }];
    };

    private _hide = _on && {!auqol_conceal_off} && {local _unit} && {_unit == player || {auqol_conceal_squad && {_unit in units group player}}}
        && {[_unit] call AUQOL_fnc_concealCanHide};
    private _saved = _unit getVariable "auqol_concealCoef"; // [value before hiding, value written]
    if (_hide) then {
        private _now = _unit getUnitTrait "camouflageCoef";
        // Someone else (Antistasi's role traits after a respawn) set it meanwhile: that is the new baseline.
        if (isNil "_saved" || {abs (_now - (_saved select 1)) > 0.001}) then {
            _unit setUnitTrait ["camouflageCoef", _now * 0.01];
            _unit setVariable ["auqol_concealCoef", [_now, _unit getUnitTrait "camouflageCoef"], true];
            auqol_conceal_hidden pushBackUnique _unit;
        };
    } else {
        // shortcut: a hidden AI that moved to another machine is restored there, once it is in that player's squad.
        if (!isNil "_saved" && {local _unit}) then {
            if (abs ((_unit getUnitTrait "camouflageCoef") - (_saved select 1)) <= 0.001) then {
                _unit setUnitTrait ["camouflageCoef", _saved select 0];
            };
            _unit setVariable ["auqol_concealCoef", nil, true];
        };
        auqol_conceal_hidden deleteAt (auqol_conceal_hidden find _unit);
    };
} forEach _units;

call AUQOL_fnc_concealHud;
