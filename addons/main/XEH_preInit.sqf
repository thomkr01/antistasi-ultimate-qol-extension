// Settings and shared state. Runs on every machine before mission objects are initialised.

auqol_ready = false;
auqol_service_cache = createHashMap;
auqol_aceRearmSources = [];

private _category = "Antistasi Ultimate QoL by TchicX";

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

// --- Local player (server-forced, applied on each player's own machine)
private _playerChanged = { if (auqol_ready) then { call AUQOL_fnc_playerApply } };

[
    "auqol_player_noSway", "CHECKBOX",
    ["No weapon sway", "Removes weapon sway for your own character (setCustomAimCoef 0, or an ACE sway factor of 0 when ACE sway is active)."],
    [_category, "Player"],
    true, 1, _playerChanged
] call CBA_fnc_addSetting;

[
    "auqol_player_unlimitedStamina", "CHECKBOX",
    ["Unlimited stamina", "Disables the vanilla stamina system for your own character, or zeroes ACE Advanced Fatigue exertion when that is active. AI stamina is not changed."],
    [_category, "Player"],
    true, 1, _playerChanged
] call CBA_fnc_addSetting;

[
    "auqol_player_weightless", "CHECKBOX",
    ["Running unaffected by carried weight", "Sets your character's loadCoef trait to 0 so equipment weight no longer drains or reserves stamina, and removes carried mass from ACE Advanced Fatigue. Other movement mechanics are unchanged."],
    [_category, "Player"],
    true, 1, _playerChanged
] call CBA_fnc_addSetting;

[
    "auqol_player_noRecoil", "CHECKBOX",
    ["No recoil", "Removes weapon recoil for your own character (setUnitRecoilCoefficient 0). AI recoil is not changed."],
    [_category, "Player"],
    false, 1, _playerChanged
] call CBA_fnc_addSetting;

// --- Loot gathering (Antistasi Ultimate). The server picks the radius, so both are server-forced.
[
    "auqol_loot_enabled", "CHECKBOX",
    ["Gather loot from vehicles", "Adds the loot crate's 'Gather Scattered Loot' action to every vehicle, and makes the vehicle and the loot crate use the radius below. Off: vehicles lose the action and the crate goes back to Antistasi's own radius."],
    [_category, "Loot gathering"],
    true, 1
] call CBA_fnc_addSetting;

[
    "auqol_loot_radius", "SLIDER",
    ["Loot gather radius (m)", "How far around the vehicle or loot crate loot is gathered from, 10 to 2000 m."],
    [_category, "Loot gathering"],
    [10, 2000, 2000, 0], 1
] call CBA_fnc_addSetting;

[
    "auqol_loot_enemyRadius", "SLIDER",
    ["Enemy check radius (m)", "Gathering is refused while an enemy in combat mode is this close to the vehicle or crate, 10 to 2000 m."],
    [_category, "Loot gathering"],
    [10, 2000, 500, 0], 1
] call CBA_fnc_addSetting;

// --- Antistasi "Withstand" self-revive cooldown (read on each client, so the setting script applies it everywhere)
private _withstandChanged = { if (auqol_ready) then { call AUQOL_fnc_withstandApply } };

[
    "auqol_withstand_enabled", "CHECKBOX",
    ["Shorter Withstand cooldown", "Replaces the 5-minute cooldown of Antistasi's Withstand self-revive with the time below. Needs the mission's Withstand self-revive parameter."],
    [_category, "Withstand"],
    true, 1, _withstandChanged
] call CBA_fnc_addSetting;

[
    "auqol_withstand_timeout", "SLIDER",
    ["Withstand cooldown (s)", "Seconds before Withstand can be used again, 1 to 300. Antistasi's default is 300."],
    [_category, "Withstand"],
    [1, 300, 1, 0], 1, _withstandChanged
] call CBA_fnc_addSetting;

// --- Diagnostics
[
    "auqol_debug", "CHECKBOX",
    ["Verbose diagnostic logging", "Writes one RPT line per ejection, refill and loot run. Leave off during normal play."],
    [_category, "Diagnostics"],
    false, 0
] call CBA_fnc_addSetting;
