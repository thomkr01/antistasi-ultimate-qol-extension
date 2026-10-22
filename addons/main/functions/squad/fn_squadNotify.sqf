/*
    Author: AUQOL
    The Reveal target (T) confirmation, drawn like a CBA notification (same box, colours, fade and
    lifetime, same height) but centred horizontally in the safe zone. Local only. A newer text replaces
    the one on screen.

    Arguments:
        0: Text <STRING>

    Return Value: none
*/

params ["_text"];
if (!hasInterface) exitWith {};
disableSerialization;

("auqol_notify" call BIS_fnc_rscLayer) cutRsc ["RscTitleDisplayEmpty", "PLAIN", 0, true];
private _display = uiNamespace getVariable ["RscTitleDisplayEmpty", displayNull];
if (isNull _display) exitWith {};
(_display displayCtrl 1202) ctrlShow false; // the empty title's vignette

private _background = _display ctrlCreate ["RscText", -1];
_background ctrlSetBackgroundColor [0, 0, 0, 0.25];
private _ctrl = _display ctrlCreate ["RscStructuredText", -1];
_ctrl ctrlSetStructuredText parseText format ["<t align='center' size='%1'>%2</t>", 0.55 / (getResolution select 5), _text];

// Same height and minimum box as CBA's (6 and 12 x 3 grid units; honours its saved HUD position).
private _gridW = safeZoneW / 40;
private _gridH = safeZoneH / 25;
private _top = profileNamespace getVariable ["IGUI_cba_ui_notify_y", safeZoneY + 6 * _gridH];
private _width = (ctrlTextWidth _ctrl) max (12 * _gridW);
_ctrl ctrlSetPosition [0, 0, _width, 3 * _gridH];
_ctrl ctrlCommit 0;
private _height = (ctrlTextHeight _ctrl) max (3 * _gridH);
private _left = safeZoneX + (safeZoneW - _width) / 2;
_top = (_top min (safeZoneY + safeZoneH - _height)) max safeZoneY;

_background ctrlSetPosition [_left, _top, _width, _height];
_ctrl ctrlSetPosition [_left, _top + (_height - ctrlTextHeight _ctrl) / 2, _width, ctrlTextHeight _ctrl];
{
    _x ctrlSetFade 1;
    _x ctrlCommit 0;
    _x ctrlSetFade 0;
    _x ctrlCommit 0.2;
} forEach [_background, _ctrl];

// Fade out after CBA's notification lifetime, unless a newer notification replaced these controls.
[{
    params ["_background", "_ctrl"];
    {
        if (!isNull _x) then {
            _x ctrlSetFade 1;
            _x ctrlCommit 1;
        };
    } forEach [_background, _ctrl];
}, [_background, _ctrl], missionNamespace getVariable ["cba_ui_notifyLifetime", 4]] call CBA_fnc_waitAndExecute;
