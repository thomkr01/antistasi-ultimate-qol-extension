/*
    Author: AUQOL
    Applies the three local-player settings to the current player unit (client only). Called on
    setting changes, on player unit change (respawn, team switch) and every 5 seconds; every branch
    only writes when the value differs, and only restores values AUQOL itself changed.

    - No sway: setCustomAimCoef 0. Skipped while ACE sway is active (ACE overwrites the coefficient;
      AUQOL's ACE sway factor handles it, see AUQOL_fnc_aceRegisterFactors).
    - Unlimited stamina: enableStamina false. Skipped under ACE Advanced Fatigue, which disables
      vanilla stamina itself and is handled by AUQOL's duty factor.
    - Weightless: loadCoef trait 0 (equipment weight multiplier for stamina). ACE movement rebuilds
      loadCoef from its saved base value ace_movement_loadCoef on every loadout change, so that base
      is set to 0 as well.

    Arguments: none
    Return Value: none
*/

if (!hasInterface || {!auqol_ready}) exitWith {};

private _unit = player;
if (isNull _unit || {!alive _unit}) exitWith {};

// --- Sway
if !(missionNamespace getVariable ["ace_common_enableSway", false] && {!isNil "ace_common_fnc_addSwayFactor"}) then {
    if (auqol_player_noSway) then {
        if (getCustomAimCoef _unit != 0) then {
            _unit setCustomAimCoef 0;
            _unit setVariable ["auqol_swaySet", true];
        };
    } else {
        if (_unit getVariable ["auqol_swaySet", false]) then {
            _unit setCustomAimCoef 1;
            _unit setVariable ["auqol_swaySet", nil];
        };
    };
};

// --- Stamina
if !(missionNamespace getVariable ["ace_advanced_fatigue_enabled", false]) then {
    if (auqol_player_unlimitedStamina) then {
        if (isStaminaEnabled _unit) then {
            _unit enableStamina false;
            _unit setVariable ["auqol_staminaSet", true];
        };
    } else {
        if (_unit getVariable ["auqol_staminaSet", false]) then {
            _unit enableStamina true;
            _unit setVariable ["auqol_staminaSet", nil];
        };
    };
};

// --- Carried weight
private _hasAceMovement = !isNil "ace_movement_fnc_handleVirtualMass";
if (auqol_player_weightless) then {
    private _current = _unit getUnitTrait "loadCoef";
    if (_current != 0) then {
        // Remember the value to restore: ACE's saved base when present (excludes ACE virtual mass), else the trait.
        _unit setVariable ["auqol_loadCoef", _unit getVariable ["ace_movement_loadCoef", _current]];
        if (_hasAceMovement) then { _unit setVariable ["ace_movement_loadCoef", 0, true] };
        _unit setUnitTrait ["loadCoef", 0];
    };
} else {
    private _original = _unit getVariable "auqol_loadCoef";
    if (!isNil "_original") then {
        if (_hasAceMovement) then { _unit setVariable ["ace_movement_loadCoef", _original, true] };
        _unit setUnitTrait ["loadCoef", _original];
        _unit setVariable ["auqol_loadCoef", nil];
        // Let ACE Advanced Fatigue fall back to loadAbs until ACE movement recalculates the total.
        _unit setVariable ["ace_movement_totalLoad", nil];
    };
};
