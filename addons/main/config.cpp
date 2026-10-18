#include "script_version.hpp"

#define QUOTE(var) #var
#define VERSION_STR MAJOR.MINOR.PATCH

class CfgPatches {
    class auqol_main {
        name = "Antistasi Ultimate QoL Extension";
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
        class capacity {
            file = "\z\auqol\addons\main\functions\capacity";
            class capacityRequest {};
            class capacityApply {};
            class capacityApplyAll {};
        };
        class ace {
            file = "\z\auqol\addons\main\compat\ace";
            class aceRefuelApply {};
            class aceRearmApply {};
            class aceRegisterFactors {};
        };
    };
};
