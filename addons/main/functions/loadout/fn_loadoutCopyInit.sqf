/*
    Author: AUQOL
    "arsenalOpened" scripted event (client). When the arsenal is Antistasi's Set Rebel Loadout editor,
    turns the third bottom-bar button into "Copy from user". Antistasi blanks that button (the BIS
    Random button, IDC 44150) in its own handler, which runs in a spawned script and ends the
    "jn_fnc_arsenal" loading screen when it is done, so this waits for that first.

    Arguments:
    0: Arsenal display <DISPLAY>

    Return Value: none
*/

params ["_display"];

if (!hasInterface || {!auqol_ready} || {!auqol_loadout_copyFromUser}) exitWith {};
if !(uiNamespace getVariable ["isLoadoutArsenal", false]) exitWith {};

[{
    isNull (_this select 0) || {!("jn_fnc_arsenal" in (missionNamespace getVariable ["BIS_fnc_startLoadingScreen_ids", []]))}
}, {
    params ["_display"];
    if (isNull _display) exitWith {};

    private _button = _display displayCtrl 44150; // IDC_RSCDISPLAYARSENAL_CONTROLSBAR_BUTTONRANDOM
    _button ctrlRemoveAllEventHandlers "ButtonClick";
    _button ctrlSetText "COPY FROM USER";
    _button ctrlSetTooltip "Load your own loadout into this role (unlocked items only). Press Save to keep it.";
    _button ctrlEnable true;
    _button ctrlAddEventHandler ["ButtonClick", { [ctrlParent (_this select 0)] call AUQOL_fnc_loadoutCopyFromUser }];
}, [_display], 15] call CBA_fnc_waitUntilAndExecute;
