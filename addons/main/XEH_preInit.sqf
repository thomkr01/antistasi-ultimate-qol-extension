// Settings and shared state. Runs on every machine before mission objects are initialised.

auqol_ready = false;
auqol_service_cache = createHashMap;
auqol_aceRearmSources = [];

private _category = "Antistasi Ultimate QoL";

// --- Crew ejection (evaluated where each vehicle is local, so the server value is forced on everyone)
[
    "auqol_eject_enabled", "CHECKBOX",
    ["Eject enemy crew from immobilized vehicles", "When an enemy AI land vehicle can no longer move (engine, wheels or tracks destroyed), its living enemy AI occupants are moved out. Players, friendly AI, captives and surrendered units are never ejected."],
    [_category, "Enemy crew ejection"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_eject_outOfFuel", "CHECKBOX",
    ["Also treat an empty fuel tank as immobilized", "canMove does not consider fuel for land vehicles. When enabled, an enemy land vehicle with exactly zero fuel also counts as immobilized."],
    [_category, "Enemy crew ejection"],
    true, 1
] call CBA_fnc_addSetting;

// --- Service stock (applied where each service object is local, and on the server for ACE and the Antistasi garage)
// Setting scripts also fire for the initial value, before AUQOL_fnc_settingsInitialized has run; auqol_ready skips that call.
private _serviceChanged = { if (auqol_ready) then { call AUQOL_fnc_serviceApplyAll } };

[
    "auqol_service_fuel", "CHECKBOX",
    ["Infinite fuel-service stock", "Fuel trucks and other recognized fuel sources never run out of the fuel they hand out (vanilla fuel cargo, or ACE refuel infinite-source mode). Their own engine fuel is not touched."],
    [_category, "Service vehicles"],
    true, 1, _serviceChanged
] call CBA_fnc_addSetting;

[
    "auqol_service_ammo", "CHECKBOX",
    ["Infinite ammunition-service stock", "Ammo trucks and other recognized rearm sources never run out (vanilla ammo cargo, or ACE rearm when it runs in 'limited' supply mode). ACE 'unlimited' mode is already infinite and is left alone."],
    [_category, "Service vehicles"],
    true, 1, _serviceChanged
] call CBA_fnc_addSetting;

[
    "auqol_service_repair", "CHECKBOX",
    ["Infinite repair-service stock", "Repair trucks and other recognized repair sources never run out of vanilla repair cargo. ACE repair has no depleting stock, so nothing changes when ACE repair is enabled."],
    [_category, "Service vehicles"],
    true, 1, _serviceChanged
] call CBA_fnc_addSetting;

[
    "auqol_service_garageFuel", "CHECKBOX",
    ["Infinite Antistasi garage fuel sources", "Antistasi's garage refuels vehicles you pull out from the fuel stored in garaged fuel trucks, and that stored fuel runs out. When enabled, garaged fuel sources are kept full. Requires the fuel-service setting."],
    [_category, "Service vehicles"],
    true, 1
] call CBA_fnc_addSetting;

// --- Local player (each client chooses unless the server forces a value)
private _playerChanged = { if (auqol_ready) then { call AUQOL_fnc_playerApply } };

[
    "auqol_player_noSway", "CHECKBOX",
    ["No weapon sway", "Removes weapon sway for your own character (setCustomAimCoef 0, or an ACE sway factor of 0 when ACE sway is active)."],
    [_category, "Player"],
    true, 0, _playerChanged
] call CBA_fnc_addSetting;

[
    "auqol_player_unlimitedStamina", "CHECKBOX",
    ["Unlimited stamina", "Disables the vanilla stamina system for your own character, or zeroes ACE Advanced Fatigue exertion when that is active. AI stamina is not changed."],
    [_category, "Player"],
    true, 0, _playerChanged
] call CBA_fnc_addSetting;

[
    "auqol_player_weightless", "CHECKBOX",
    ["Running unaffected by carried weight", "Sets your character's loadCoef trait to 0 so equipment weight no longer drains or reserves stamina, and removes carried mass from ACE Advanced Fatigue. Other movement mechanics are unchanged."],
    [_category, "Player"],
    true, 0, _playerChanged
] call CBA_fnc_addSetting;

// --- Carrying capacity (setMaxLoad must run on the server, so the server value is forced)
private _capacityChanged = { if (auqol_ready && {isServer}) then { call AUQOL_fnc_capacityApplyAll } };

[
    "auqol_capacity_enabled", "CHECKBOX",
    ["Increase carrying capacity", "Multiplies the capacity of players' uniform, vest and backpack containers."],
    [_category, "Carrying capacity"],
    true, 1, _capacityChanged
] call CBA_fnc_addSetting;

[
    "auqol_capacity_multiplier", "SLIDER",
    ["Carrying capacity multiplier", "Container capacity multiplier, 1 to 1000. The engine's total soldier load limit (maxSoldierLoad) is a static config value and is not raised by this setting; see the optional auqol_maxload addon."],
    [_category, "Carrying capacity"],
    [1, 1000, 1000, 0], 1, _capacityChanged
] call CBA_fnc_addSetting;

// --- Diagnostics
[
    "auqol_debug", "CHECKBOX",
    ["Verbose diagnostic logging", "Writes one RPT line per ejection, refill and capacity change. Leave off during normal play."],
    [_category, "Diagnostics"],
    false, 0
] call CBA_fnc_addSetting;
