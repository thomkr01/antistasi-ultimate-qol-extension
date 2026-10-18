// Optional: raises the engine's total soldier load limit. Not loaded unless you add this PBO yourself.
// This is a static config value with no per-unit or runtime switch, so it affects every unit,
// including AI, and also lowers how much weight drains vanilla stamina for everyone.
class CfgPatches {
    class auqol_maxload {
        name = "Antistasi Ultimate QoL Extension - Raised soldier load limit (optional)";
        author = "AUQOL Contributors";
        units[] = {};
        weapons[] = {};
        requiredVersion = 2.12;
        requiredAddons[] = {"auqol_main", "A3_Data_F_AoW_Loadorder"};
    };
};

class CfgInventoryGlobalVariable {
    // Vanilla 1000 mass units, times the mod's default 1000x multiplier.
    maxSoldierLoad = 1000000;
};
