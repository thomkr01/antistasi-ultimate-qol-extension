/*
    Author: AUQOL
    Sets Antistasi's "Withstand" self-revive cooldown. A3A_fnc_selfRevive (player-local) reads
    missionNamespace "A3A_selfReviveTimeout" with a default of 300 s, and the after-effects (screen
    desaturation, aim penalty) last for the same time. Clearing the variable restores the 300 s default.

    Arguments: none
    Return Value: none
*/

if (auqol_withstand_enabled) then {
    missionNamespace setVariable ["A3A_selfReviveTimeout", 1 max round auqol_withstand_timeout];
} else {
    missionNamespace setVariable ["A3A_selfReviveTimeout", nil];
};
