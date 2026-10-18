/*
    Author: AUQOL
    Registers AUQOL's hooks in ACE's player loops (client, once). Each hook reads the AUQOL setting on
    every ACE tick, so toggling a setting needs no re-registration. Missing ACE components are skipped.

    - ACE sway (ace_common_enableSway): ACE re-applies setCustomAimCoef every 0.5 s from its sway
      factors, so no sway is a "multiplier" factor of 0 (ace_common_fnc_addSwayFactor, public API).
    - ACE Advanced Fatigue: exertion is the metabolic cost multiplied by every duty factor, so
      unlimited stamina is a duty factor of 0 (ace_advanced_fatigue_fnc_addDutyFactor; used by ACE's
      own components but not marked public). The fatigue loop takes carried mass from the
      ace_movement_totalLoad variable, falling back to loadAbs, so weightless movement keeps that
      variable at 0 for the local player from the same hook.

    Arguments: none
    Return Value: none
*/

if (!hasInterface || {!isNil "auqol_aceFactorsRegistered"}) exitWith {};
auqol_aceFactorsRegistered = true;

if (!isNil "ace_common_fnc_addSwayFactor") then {
    ["multiplier", { [1, 0] select auqol_player_noSway }, "auqol_noSway"] call ace_common_fnc_addSwayFactor;
};

if (missionNamespace getVariable ["ace_advanced_fatigue_enabled", false]) then {
    if (isNil "ace_advanced_fatigue_fnc_addDutyFactor") exitWith {
        ["WARNING: ACE Advanced Fatigue is enabled but ace_advanced_fatigue_fnc_addDutyFactor was not found; unlimited stamina and ACE carried-mass removal are unavailable while ACE fatigue is on."] call AUQOL_fnc_log;
    };
    ["auqol_stamina", {
        if (auqol_player_weightless) then { _this setVariable ["ace_movement_totalLoad", 0] };
        [1, 0] select auqol_player_unlimitedStamina
    }] call ace_advanced_fatigue_fnc_addDutyFactor;
};
