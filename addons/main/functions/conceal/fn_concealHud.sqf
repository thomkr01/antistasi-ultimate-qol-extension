/*
    Author: AUQOL
    The concealment indicator for the local player, the same as Hide Among The Grass shows it: its
    hidden, revealed and disabled icons (used under its APL-SA licence, see README), grey and half
    transparent while hidden, white while seen, centred near the bottom of the screen at HATG's default
    place. Only redrawn when the state changes. Nothing is shown with auqol_conceal_hud off, or while
    the feature is off or HATG itself is loaded.

    Arguments: none
    Return Value: none
*/

if (!hasInterface) exitWith {};
disableSerialization;
private _ctrl = uiNamespace getVariable ["auqol_conceal_ctrl", controlNull];
private _state = switch (true) do {
    case (!auqol_conceal_hud || !auqol_conceal_enabled || auqol_conceal_hatg || {!alive player}): { "" };
    case (auqol_conceal_off): { "disabled" };
    case ((player getVariable ["auqol_concealCoef", [0, 0, 1]]) select 2 <= 0.01): { "hidden" };
    default { "revealed" };
};
if (!isNull _ctrl && {_state == uiNamespace getVariable ["auqol_conceal_state", ""]}) exitWith {};
uiNamespace setVariable ["auqol_conceal_state", _state];

if (isNull _ctrl) then {
    if (_state == "") exitWith {};
    ("auqol_conceal" call BIS_fnc_rscLayer) cutRsc ["RscTitleDisplayEmpty", "PLAIN", 0, false, true];
    private _display = uiNamespace getVariable ["RscTitleDisplayEmpty", displayNull];
    if (isNull _display) exitWith {};
    (_display displayCtrl 1202) ctrlShow false; // the empty title's vignette
    _ctrl = _display ctrlCreate ["RscStructuredText", -1];
    _ctrl ctrlEnable false;
    // HATG's place: horizontally centred, its box bottom 1.7 above the screen bottom, nudged by the
    // interface size (Large reports no usable value, so it gets its own offset).
    private _w = 0.45;
    private _h = 1.7;
    private _size = [1, 0.7, 0.55, 0.47] find (getResolution select 5);
    private _fix = if (_size == -1) then { 0.5 } else { [0.7, 0.3, -0.1, -0.4] select _size };
    _ctrl ctrlSetPosition [safeZoneX + safeZoneWAbs / 2 - _w / 2, safeZoneY + safeZoneH - _h + _fix, _w, _h];
    _ctrl ctrlCommit 0;
    uiNamespace setVariable ["auqol_conceal_ctrl", _ctrl];
};
if (isNull _ctrl) exitWith {};

if (_state == "") exitWith { _ctrl ctrlSetStructuredText parseText "" };
_ctrl ctrlSetStructuredText parseText format [
    "<img align='center' shadow='0' color='%1' size='3' image='\z\auqol\addons\main\data\conceal\%2_ca.paa' /><br />",
    ["#FFFFFFFF", "#80808080"] select (_state == "hidden"), _state
];
