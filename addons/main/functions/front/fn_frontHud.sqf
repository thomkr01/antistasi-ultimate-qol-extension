/*
    Author: AUQOL
    The bearing dial for the local player: a compass rose that turns with your view, an orange marker on the
    last called-out enemy (the bearing from you to him) and below it "<his bearing> / <your heading>". Shown for
    8 s after each call-out, left of the screen centre, low. The rotation runs on an EachFrame handler that
    exists only while the dial is on screen. Nothing with auqol_front_hud off or Where The Duck Is Front loaded.

    Arguments:
    0: Enemy <OBJECT>

    Return Value: none
*/
params ["_target"];
if (!hasInterface || {!auqol_front_hud} || auqol_front_wtdif) exitWith {};
disableSerialization;
auqol_front_hudTarget = _target;
auqol_front_hudUntil = time + 8;
if (auqol_front_hudHandler >= 0) exitWith {}; // already on screen: it now follows the new enemy

("auqol_front" call BIS_fnc_rscLayer) cutRsc ["RscTitleDisplayEmpty", "PLAIN", 0, false, true];
private _display = uiNamespace getVariable ["RscTitleDisplayEmpty", displayNull];
if (isNull _display) exitWith {};
(_display displayCtrl 1202) ctrlShow false; // the empty title's vignette
private _h = 0.12 * safeZoneH;
private _w = _h / pixelH * pixelW; // square on screen
private _left = safeZoneX + 0.06 * safeZoneW;
private _top = safeZoneY + 0.58 * safeZoneH;
private _ctrls = [];
{
    private _ctrl = _display ctrlCreate ["RscPicture", -1];
    _ctrl ctrlSetText format ["\z\auqol\addons\main\data\front\%1_ca.paa", _x];
    _ctrls pushBack _ctrl;
} forEach ["dial", "marker"];
private _text = _display ctrlCreate ["RscStructuredText", -1];
_ctrls pushBack _text;
{ _x ctrlSetPosition [_left, _top, _w, _h] } forEach (_ctrls select [0, 2]);
_text ctrlSetPosition [_left - _w / 2, _top + _h, _w * 2, 0.04 * safeZoneH];
{ _x ctrlEnable false; _x ctrlCommit 0 } forEach _ctrls;
uiNamespace setVariable ["auqol_front_hudCtrls", _ctrls];

auqol_front_hudHandler = addMissionEventHandler ["EachFrame", {
    disableSerialization;
    (uiNamespace getVariable ["auqol_front_hudCtrls", []]) params [["_dial", controlNull], ["_marker", controlNull], ["_text", controlNull]];
    if (isNull _dial || {time > auqol_front_hudUntil} || {!alive player}) exitWith {
        ("auqol_front" call BIS_fnc_rscLayer) cutText ["", "PLAIN"];
        removeMissionEventHandler ["EachFrame", _thisEventHandler];
        auqol_front_hudHandler = -1;
    };
    private _view = getCameraViewDirection player;
    private _heading = ((_view select 0) atan2 (_view select 1) + 360) % 360;
    private _target = auqol_front_hudTarget;
    private _bearing = if (isNull _target) then { _heading } else { player getDir _target };
    _dial ctrlSetAngle [-_heading, 0.5, 0.5, true];
    _marker ctrlSetAngle [_bearing - _heading, 0.5, 0.5, true];
    _text ctrlSetStructuredText parseText format ["<t align='center' size='%3' shadow='2'><t color='#FF8C00'>%1</t> / %2</t>",
        [(round _bearing) % 360, 3] call CBA_fnc_formatNumber, [(round _heading) % 360, 3] call CBA_fnc_formatNumber, 0.8 / (getResolution select 5)];
}];
