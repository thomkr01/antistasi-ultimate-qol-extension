// Event wiring. Handlers check settings when they fire, so registering them before settings are ready is safe.

// Network events. Each runs on the machine that owns the object passed as target.
["auqol_eject_unit", { _this call AUQOL_fnc_ejectUnit }] call CBA_fnc_addEventHandler;
["auqol_service_refill", { _this call AUQOL_fnc_serviceRefillLocal }] call CBA_fnc_addEventHandler;
["auqol_loot_message", {
    systemChat localize (_this select 0);
    playSound "A3AP_UiFailure";
}] call CBA_fnc_addEventHandler;
if (isServer) then {
    ["auqol_loot_gather", { _this call AUQOL_fnc_lootGather }] call CBA_fnc_addEventHandler;
};

// Added on every machine: the handlers act only where the vehicle is local, which follows locality changes.
["LandVehicle", "InitPost", { (_this select 0) call AUQOL_fnc_ejectInitVehicle }, true, ["StaticWeapon"], true] call CBA_fnc_addClassEventHandler;
["All", "InitPost", { (_this select 0) call AUQOL_fnc_serviceInitObject }, true, ["Man"], true] call CBA_fnc_addClassEventHandler;
["All", "InitPost", { [_this select 0] call AUQOL_fnc_lootInitObject }, true, ["Man"], true] call CBA_fnc_addClassEventHandler;

// Vanilla resupply (2.12+): fires repeatedly while a vehicle is being rearmed, repaired or refuelled.
addMissionEventHandler ["Service", { _this call AUQOL_fnc_serviceOnService }];

["CBA_settingsInitialized", { call AUQOL_fnc_settingsInitialized }] call CBA_fnc_addEventHandler;
