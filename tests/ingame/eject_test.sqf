// Debug console, "Local exec" in single player or "Server exec" on a server you host.
// Spawns two hostile crewed MRAPs 60 m in front of the player: one is left intact (must keep its
// crew), the other has its wheels destroyed (crew must be ejected). Results go to system chat and RPT.
[] spawn {
    private _hostile = [west, east, independent] select { (_x getFriend side group player) < 0.6 };
    if (_hostile isEqualTo []) exitWith { systemChat "[AUQOL test] No side is hostile to the player." };
    private _side = _hostile select 0;
    private _class = ["B_MRAP_01_F", "O_MRAP_02_F", "I_MRAP_03_F"] select ([west, east, independent] find _side);
    private _report = {
        params ["_text"];
        systemChat ("[AUQOL test] " + _text);
        diag_log text ("[AUQOL test] " + _text);
    };

    private _spawn = {
        params ["_offset"];
        private _pos = player getRelPos [60, _offset];
        private _veh = createVehicle [_class, _pos, [], 0, "NONE"];
        createVehicleCrew _veh;
        _veh
    };
    private _parked = [-20] call _spawn;
    private _broken = [20] call _spawn;
    sleep 3;
    private _crewBefore = count crew _broken;

    {
        if ("wheel" in toLowerANSI _x) then { _broken setHitPointDamage [_x, 1] };
    } forEach ((getAllHitPointsDamage _broken) param [0, []]);
    sleep 12;

    [format ["Damaged %1: canMove=%2, crew before=%3, crew now=%4 (expect 0)", _class, canMove _broken, _crewBefore, count crew _broken]] call _report;
    [format ["Parked %1: canMove=%2, crew now=%3 (expect unchanged, >0)", _class, canMove _parked, count crew _parked]] call _report;
    ["Delete the test vehicles with: { deleteVehicleCrew _x; deleteVehicle _x } forEach (nearestObjects [player, [""MRAP_01_base_F"", ""MRAP_02_base_F"", ""MRAP_03_base_F""], 200]);"] call _report;
};
