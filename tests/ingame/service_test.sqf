// Debug console, "Local exec".
// Spawns a fuel truck and an empty-tanked car next to it, puts you in the car's driver seat so the
// vanilla proximity refuel starts, and reports the truck's service stock (must stay full) and its
// own engine fuel (must not be made infinite). Run it from your own client in MP ("Local exec").
[] spawn {
    private _report = {
        params ["_text"];
        systemChat ("[AUQOL test] " + _text);
        diag_log text ("[AUQOL test] " + _text);
    };
    private _pos = player getRelPos [25, 0];
    private _truck = createVehicle ["B_Truck_01_fuel_F", _pos, [], 0, "NONE"];
    private _car = createVehicle ["C_Offroad_01_F", _truck getRelPos [8, 90], [], 0, "NONE"];
    sleep 2;
    _truck setFuel 0.5;
    _car setFuel 0;
    private _ace = missionNamespace getVariable ["ace_refuel_enabled", false];
    [format ["Start: truck service stock=%1, truck engine fuel=%2, car fuel=%3, ACE refuel=%4",
        [getFuelCargo _truck, _truck getVariable ["ace_refuel_capacity", "n/a"]] select _ace, fuel _truck, fuel _car, _ace]] call _report;
    if (_ace) exitWith {
        ["ACE refuel: expect truck capacity -10 (infinite). Refuel the car with the nozzle, then run: [getFuelCargo cursorObject, cursorObject getVariable 'ace_refuel_capacity', fuel cursorObject] on the truck."] call _report;
    };
    player moveInDriver _car;
    sleep 30; // vanilla proximity refuel is gradual
    [format ["After 30 s: truck service stock=%1 (expect 1), truck engine fuel=%2 (expect 0.5), car fuel=%3 (expect > 0)",
        getFuelCargo _truck, fuel _truck, fuel _car]] call _report;
};
