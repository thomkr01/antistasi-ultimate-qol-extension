// Debug console, "Local exec" on your own client. Prints what the player features currently apply.
private _lines = [
    format ["Aim coef=%1 (expect 0 with no sway; under ACE sway it is re-applied every 0.5 s)", getCustomAimCoef player],
    format ["Vanilla stamina enabled=%1 (expect false with unlimited stamina and no ACE fatigue)", isStaminaEnabled player],
    format ["loadCoef=%1 (expect 0 with weightless running)", player getUnitTrait "loadCoef"],
    format ["Recoil coef=%1 (expect 0 with no recoil on, 1 otherwise)", unitRecoilCoefficient player],
    format ["Total carry limit=%1, carried=%2 (expect a limit of 10000000)", getNumber (configFile >> "CfgInventoryGlobalVariable" >> "maxSoldierLoad"), loadAbs player],
    format ["ACE fatigue duty factor registered=%1", (missionNamespace getVariable ["ace_advanced_fatigue_dutyList", createHashMap]) getOrDefault ["auqol_stamina", ""] isEqualType {}]
];
{ systemChat ("[AUQOL test] " + _x); diag_log text ("[AUQOL test] " + _x) } forEach _lines;
