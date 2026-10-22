#include "script_version.hpp"

#define QUOTE(var) #var
#define VERSION_STR MAJOR.MINOR.PATCH

class CfgPatches {
    class auqol_main {
        name = "Antistasi Ultimate QoL Extension by TchicX";
        author = "TchicX";
        url = "https://github.com/thomkr01/antistasi-ultimate-qol-extension";
        units[] = {};
        weapons[] = {};
        // 2.12 added the "Service" mission event handler used by the service feature; 2.14 added remoteControlled.
        requiredVersion = 2.14;
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

// AI avoid the prone stance on every surface (what the "AI avoids prone" mod does). Surfaces inherit
// from Default; one that sets its own AIAvoidStance keeps it. Static config, no runtime cost, no switch.
class CfgSurfaces {
    class Default {
        AIAvoidStance = 2;
    };
};

// Ladder climbing speed: the engine's global ladderSpeed (vanilla 0.5) times 2.5, the value Ladder Tweak
// Remastered uses, so loading both changes nothing. Static config, so it applies to every unit, AI
// included, and every machine. Replaces the 1.11-1.27 animation boost, which only changed the look.
class CfgAnimation {
    ladderSpeed = 1.25;
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
            class perfRun {};
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
            class serviceScratches {};
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
            class loadoutFilter {};
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
            class squadNotify {};
            class squadLaunchers {};
            class squadGroupHooks {};
            class squadRevealFocus {};
            class squadLookSpot {};
            class squadSelfTreat {};
            class squadIsOutOfFight {};
            class squadCallout {};
            class squadAmbush {};
            class squadOverwatch {};
            class squadPush {};
            class squadUnpin {};
            class squadBreach {};
        };
        class map {
            file = "\z\auqol\addons\main\functions\map";
            class mapVehicleMarkers {};
        };
        class freeze {
            file = "\z\auqol\addons\main\functions\freeze";
            class freezeVehicles {};
        };
        class anim {
            file = "\z\auqol\addons\main\functions\anim";
            class animAiApply {};
            class animPlayerState {};
            class animLadderSlide {};
            class animFastDismount {};
        };
        class combat {
            file = "\z\auqol\addons\main\functions\combat";
            class combatSuppressed {};
            class combatGroupHook {};
            class combatStart {};
            class combatTick {};
            class combatIsEligible {};
            class combatFindCover {};
            class combatThrow {};
            class combatRelease {};
            class combatShareContact {};
            class combatDodge {};
            class combatDodgeMove {};
            class combatSupport {};
        };
        class night {
            file = "\z\auqol\addons\main\functions\night";
            class nightApply {};
            class nightHasVision {};
        };
        class conceal {
            file = "\z\auqol\addons\main\functions\conceal";
            class concealTick {};
            class concealFactor {};
            class concealOnFired {};
            class concealHud {};
            class concealCamo {};
            class concealLocateShot {};
            class concealLocateCheck {};
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
