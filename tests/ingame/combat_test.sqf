// Debug console, "Local exec" (single player or host). Spawns an enemy (OPFOR) fire team 150 m in
// front of you among whatever cover is there, reveals you to it, and prints every 3 s what the
// smart combat tactics are doing: each member's fire team, its spot and its distance to it.
// Expect the two teams to take turns moving between covered spots toward you, crouched outdoors and
// standing at building positions. Hide inside a house within 80 m to see two of them clear it.
// Clean up afterwards: { deleteVehicle _x } forEach units (missionNamespace getVariable ["auqol_test_combat", grpNull]);
private _group = createGroup [east, true];
private _pos = player getRelPos [150, 0];
{ _group createUnit [_x, _pos, [], 5, "FORM"] } forEach ["O_Soldier_TL_F", "O_Soldier_AR_F", "O_Soldier_F", "O_Soldier_LAT_F", "O_Soldier_F", "O_medic_F"];
_group reveal [player, 2];
missionNamespace setVariable ["auqol_test_combat", _group];
[{
    params ["_group", "_handle"];
    if (isNull _group || {units _group isEqualTo []}) exitWith { [_handle] call CBA_fnc_removePerFrameHandler };
    private _lines = (units _group) apply {
        private _dest = _x getVariable ["auqol_tacDest", []];
        format ["%1 team %2 %3 %4", name _x, _x getVariable ["auqol_tacTeam", "-"], unitPos _x,
            ["no spot", format ["%1 m from spot%2", round (_x distance2D _dest), ["", " (indoor)"] select (_x getVariable ["auqol_tacIndoor", false])]] select (_dest isNotEqualTo [])];
    };
    hintSilent (format ["Tactics running: %1\n", !isNil {_group getVariable "auqol_tacPFH"}] + (_lines joinString "\n"));
}, 3, _group] call CBA_fnc_addPerFrameHandler;
systemChat "[AUQOL test] Enemy fire team spawned 150 m ahead and told where you are.";
