/*
    Author: AUQOL
    One stuck-detection pass on this machine. Started once per machine with a 5 s timer by
    AUQOL_fnc_settingsInitialized: the engine has no event for "AI makes no progress", so polling is
    the only way, and 5 s is far below any useful timeout. Only units local to this machine are
    evaluated, so every AI is handled by exactly one machine (its owner) and no two machines ever act
    on the same unit. Tracking lives in a variable on the unit itself, so it disappears with the unit.

    Scope (auqol_stuck_scope):
    0: AI in this player's own group (clients only; a dedicated server has no player).
    1: friendly AI within auqol_stuck_scopeRadius of any player.
    2: all friendly AI.

    Arguments: none
    Return Value: none
*/

if (!auqol_ready || {!auqol_stuck_enabled}) exitWith {};

private _units = [];
if (auqol_stuck_scope == 0) then {
    if (hasInterface && {!isNull player}) then { _units = units group player };
} else {
    private _friendly = missionNamespace getVariable ["teamPlayer", sideUnknown];
    if (!(_friendly isEqualType sideUnknown) || {_friendly == sideUnknown}) then {
        _friendly = if (hasInterface && {!isNull player}) then { side group player } else { sideUnknown };
    };
    _units = allUnits select { local _x && {side group _x == _friendly} };
    if (auqol_stuck_scope == 1) then {
        private _players = allPlayers - entities "HeadlessClient_F";
        _units = _units select {
            private _unit = _x;
            _players findIf { _x distance _unit < auqol_stuck_scopeRadius } != -1
        };
    };
};

{ [_x] call AUQOL_fnc_stuckEvaluate } forEach (_units select { local _x && {!isPlayer _x} });
