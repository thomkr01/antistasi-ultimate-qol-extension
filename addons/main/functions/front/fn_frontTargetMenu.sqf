/*
    Author: AUQOL
    "Where is target?" in the command menu's Status page: lists the enemies your group knows within 1500 m,
    nearest first, nine to a page. Picking one asks the AI you had selected (AUQOL_fnc_frontReport).

    Arguments:
    0: AI you had selected <ARRAY>

    Return Value: none
*/
params [["_units", []]];
if (!hasInterface || {!auqol_ready} || {!auqol_front_menu}) exitWith {};
private _known = ((group player) targets [true, 1500]) select { alive _x } apply { [player distance _x, _x] };
_known sort true;
auqol_front_menuTargets = _known apply { _x select 1 };
auqol_front_menuUnits = _units;
if (auqol_front_menuTargets isEqualTo []) exitWith { ["No known enemies"] call AUQOL_fnc_squadNotify };

private _pages = ceil (count auqol_front_menuTargets / 9);
for "_page" from 1 to _pages do {
    private _menu = [[format ["Where is target? (%1/%2)", _page, _pages], true]];
    for "_i" from (_page - 1) * 9 to ((_page * 9) min count auqol_front_menuTargets) - 1 do {
        private _target = auqol_front_menuTargets select _i;
        private _name = [getText (configOf _target >> "displayName"), "Infantry"] select (_target isKindOf "Man");
        _menu pushBack [format ["%1, %2 m", _name, round (player distance _target / 10) * 10], [], "", -5,
            [["expression", format ["[auqol_front_menuTargets select %1, auqol_front_menuUnits] call AUQOL_fnc_frontReport", _i]]], "1", "1"];
    };
    if (_page < _pages) then { _menu pushBack ["Next", [], format ["#USER:auqol_frontMenuPage%1", _page + 1], -5, [["expression", ""]], "1", "1"] };
    missionNamespace setVariable [format ["auqol_frontMenuPage%1", _page], _menu];
};
// Picking this entry unselected the units; select them again so the answer comes from them.
{ player groupSelectUnit [_x, true] } forEach (_units select { alive _x });
showCommandingMenu "#USER:auqol_frontMenuPage1";
