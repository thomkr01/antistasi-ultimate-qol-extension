// Debug console, "Local exec" on your own client. Prints what the player features currently apply.
private _lines = [
    format ["Aim coef=%1 (expect 0 with no sway; under ACE sway it is re-applied every 0.5 s)", getCustomAimCoef player],
    format ["Vanilla stamina enabled=%1 (expect false with unlimited stamina and no ACE fatigue)", isStaminaEnabled player],
    format ["loadCoef=%1 (expect 0 with weightless running)", player getUnitTrait "loadCoef"],
    format ["Uniform %1/%2, vest %3/%4, backpack %5/%6 (current max vs config max; expect %7)",
        maxLoad uniformContainer player, getContainerMaxLoad uniform player,
        maxLoad vestContainer player, getContainerMaxLoad vest player,
        maxLoad backpackContainer player, getContainerMaxLoad backpack player,
        missionNamespace getVariable ["auqol_capacity_value", 0]],
    format ["ACE fatigue duty factor registered=%1", (missionNamespace getVariable ["ace_advanced_fatigue_dutyList", createHashMap]) getOrDefault ["auqol_stamina", ""] isEqualType {}]
];
{ systemChat ("[AUQOL test] " + _x); diag_log text ("[AUQOL test] " + _x) } forEach _lines;
