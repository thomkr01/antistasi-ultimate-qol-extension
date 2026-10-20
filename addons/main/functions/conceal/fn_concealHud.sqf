/*
    Author: AUQOL
    The concealment indicator for the local player, like Hide Among The Grass shows: a stealth icon
    with "HIDDEN" (grey) or "SEEN" (white), or "OFF" when the player switched concealment off with the
    toggle key. Nothing is shown with auqol_conceal_hud off, or while the feature is off or HATG is loaded.

    Arguments: none
    Return Value: none
*/

if (!hasInterface) exitWith {};
disableSerialization;
private _ctrl = uiNamespace getVariable ["auqol_conceal_ctrl", controlNull];
private _show = auqol_conceal_hud && auqol_conceal_enabled && !auqol_conceal_hatg && {alive player};
if (!_show) exitWith { if (!isNull _ctrl) then { _ctrl ctrlSetStructuredText parseText "" } };

if (isNull _ctrl) then {
    ("auqol_conceal" call BIS_fnc_rscLayer) cutRsc ["RscTitleDisplayEmpty", "PLAIN", 0, false, true];
    private _display = uiNamespace getVariable ["RscTitleDisplayEmpty", displayNull];
    if (isNull _display) exitWith {};
    (_display displayCtrl 1202) ctrlShow false; // the empty title's vignette
    _ctrl = _display ctrlCreate ["RscStructuredText", -1];
    _ctrl ctrlSetPosition [safeZoneX + safeZoneW * 0.47, safeZoneY + safeZoneH * 0.86, safeZoneW * 0.06, safeZoneH * 0.1];
    _ctrl ctrlEnable false;
    _ctrl ctrlCommit 0;
    uiNamespace setVariable ["auqol_conceal_ctrl", _ctrl];
};
if (isNull _ctrl) exitWith {};

private _state = switch (true) do {
    case (auqol_conceal_off): { ["OFF", "#80ff6060"] };
    case (!isNil {player getVariable "auqol_concealCoef"}): { ["HIDDEN", "#80808080"] };
    default { ["SEEN", "#ffffffff"] };
};
_state params ["_text", "_colour"];
_ctrl ctrlSetStructuredText parseText format [
    "<img align='center' size='2' color='%1' image='\A3\UI_F_Curator\Data\RscCommon\RscAttributeBehaviour\stealth_ca.paa'/><br/><t align='center' size='0.8' color='%1'>%2</t>",
    _colour, _text
];
