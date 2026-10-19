#include "script_version.hpp"

#define QUOTE(var) #var
#define VERSION_STR MAJOR.MINOR.PATCH

class CfgPatches {
    class auqol_main {
        name = "Antistasi Ultimate QoL Extension by TchicX";
        author = "AUQOL Contributors";
        url = "https://github.com/thomkr01/antistasi-ultimate-qol-extension";
        units[] = {};
        weapons[] = {};
        // 2.12 added the "Service" mission event handler used by the service feature.
        requiredVersion = 2.12;
        requiredAddons[] = {"cba_main"};
        version = MAJOR.MINOR;
        versionStr = QUOTE(VERSION_STR);
        versionAr[] = {MAJOR, MINOR, PATCH};
    };
};

// Total soldier load cap (vanilla 1000): the limit that stops you picking up more once you carry
// something heavy. Raised so total weight never blocks you; container capacities are unchanged.
// Static config, so it applies to every unit, AI included.
// Load order after vanilla comes through cba_main -> cba_common -> A3_Data_F_AoW_Loadorder.
class CfgInventoryGlobalVariable {
    maxSoldierLoad = 10000000;
};

class Extended_PreInit_EventHandlers {
    class auqol_main {
        init = "call compileScript ['\z\auqol\addons\main\XEH_preInit.sqf']";
    };
};

class Extended_PostInit_EventHandlers {
    class auqol_main {
        init = "call compileScript ['\z\auqol\addons\main\XEH_postInit.sqf']";
    };
};

class CfgFunctions {
    class AUQOL {
        tag = "AUQOL";
        class common {
            file = "\z\auqol\addons\main\functions\common";
            class log {};
            class diagnostics {};
            class isHostileSide {};
            class settingsInitialized {};
        };
        class eject {
            file = "\z\auqol\addons\main\functions\eject";
            class ejectInitVehicle {};
            class ejectEvaluate {};
            class ejectIsImmobilized {};
            class ejectIsEligible {};
            class ejectCrew {};
            class ejectUnit {};
        };
        class service {
            file = "\z\auqol\addons\main\functions\service";
            class serviceConfig {};
            class serviceVanillaActive {};
            class serviceInitObject {};
            class serviceApplyObject {};
            class serviceApplyAll {};
            class serviceOnService {};
            class serviceRefillLocal {};
            class serviceGarageRestore {};
        };
        class player {
            file = "\z\auqol\addons\main\functions\player";
            class playerApply {};
        };
        class loot {
            file = "\z\auqol\addons\main\functions\loot";
            class lootIsTarget {};
            class lootInitObject {};
            class lootAddAction {};
            class lootGather {};
            class lootCaches {};
        };
        class loadout {
            file = "\z\auqol\addons\main\functions\loadout";
            class loadoutCopyInit {};
            class loadoutCopyFromUser {};
        };
        class stuck {
            file = "\z\auqol\addons\main\functions\stuck";
            class stuckMonitor {};
            class stuckIsEligible {};
            class stuckEvaluate {};
            class stuckRecover {};
            class stuckFindPosition {};
            class stuckNotify {};
            class stuckSimulate {};
        };
        class squad {
            file = "\z\auqol\addons\main\functions\squad";
            class squadReactApply {};
            class squadRevealTarget {};
            class squadLaunchers {};
            class squadGroupHooks {};
        };
        class map {
            file = "\z\auqol\addons\main\functions\map";
            class mapVehicleMarkers {};
        };
        class withstand {
            file = "\z\auqol\addons\main\functions\withstand";
            class withstandApply {};
        };
        class ace {
            file = "\z\auqol\addons\main\compat\ace";
            class aceRefuelApply {};
            class aceRearmApply {};
            class aceRegisterFactors {};
        };
    };
};
