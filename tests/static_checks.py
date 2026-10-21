#!/usr/bin/env python3
"""Static checks for AUQOL that do not need the Arma 3 engine.

Run from the repository root:

    python3 tests/static_checks.py [--cba PATH] [--ace PATH] [--antistasi PATH] [--wiki PATH]

Without source paths only the self-contained checks run. With them, every external function,
variable, event name and class name the mod relies on is looked up in the real sources:

    --cba        clone of https://github.com/CBATeam/CBA_A3
    --ace        clone of https://github.com/acemod/ACE3
    --antistasi  clone of https://github.com/SilenceIsFatto/A3-Antistasi-Ultimate
    --wiki       "dist" branch of https://github.com/acemod/arma3-wiki (parsed BI wiki: commands and events)

Exit code 0 when every executed check passes, 1 otherwise. Checks that were skipped are listed.
"""

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ADDON = ROOT / "addons" / "main"
PREFIX = "\\z\\auqol\\addons\\main\\"

failures = []
skipped = []
passed = []


def check(name, problems):
    if problems:
        failures.append((name, problems))
    else:
        passed.append(name)


def sqf_files():
    return sorted(ROOT.glob("addons/**/*.sqf")) + sorted(ROOT.glob("optionals/**/*.sqf"))


def strip_comments(text):
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return re.sub(r"//[^\n]*", "", text)


def strip_strings(text):
    return re.sub(r'"(?:[^"]|"")*"', '""', text)


def sqf_code(include_ingame=False):
    files = sqf_files() + (sorted(ROOT.glob("tests/ingame/*.sqf")) if include_ingame else [])
    return {p: strip_comments(p.read_text()) for p in files}


# --- CfgFunctions ------------------------------------------------------------------------------

def cfg_functions():
    text = strip_comments((ADDON / "config.cpp").read_text())
    block = re.search(r"class CfgFunctions\s*\{(.*)\};", text, re.S).group(1)
    functions = {}
    for folder, body in re.findall(r'file\s*=\s*"([^"]+)";(.*?)\n\s*\};', block, re.S):
        for name in re.findall(r"class\s+(\w+)\s*\{\s*\};", body):
            functions[f"AUQOL_fnc_{name}"] = folder + "\\fn_" + name + ".sqf"
    return functions


def check_functions():
    functions = cfg_functions()
    problems = []
    registered_files = set()
    for fnc, path in functions.items():
        if not path.startswith(PREFIX):
            problems.append(f"{fnc}: path {path} is outside {PREFIX}")
            continue
        local = ADDON / path[len(PREFIX):].replace("\\", "/")
        registered_files.add(local.resolve())
        if not local.is_file():
            problems.append(f"{fnc}: missing file {local.relative_to(ROOT)}")
    for f in ADDON.rglob("fn_*.sqf"):
        if f.resolve() not in registered_files:
            problems.append(f"{f.relative_to(ROOT)} is not registered in CfgFunctions")
    used = set()
    for path, code in sqf_code(include_ingame=True).items():
        for fnc in re.findall(r"\bAUQOL_fnc_\w+", code):
            used.add(fnc)
            if fnc not in functions:
                problems.append(f"{path.relative_to(ROOT)} calls undefined {fnc}")
    for fnc in functions:
        if fnc not in used:
            problems.append(f"{fnc} is registered but never called")
    check("CfgFunctions: every function has a file, every file is registered, every call is defined", problems)
    return functions


def check_config_paths():
    problems = []
    text = (ADDON / "config.cpp").read_text()
    for path in re.findall(r"compileScript \['([^']+)'\]", text):
        local = ADDON / path[len(PREFIX):].replace("\\", "/")
        if not path.startswith(PREFIX) or not local.is_file():
            problems.append(f"XEH script {path} not found")
    prefix = (ADDON / "$PBOPREFIX$").read_text().strip()
    if "\\" + prefix + "\\" != PREFIX:
        problems.append(f"$PBOPREFIX$ is {prefix}, expected {PREFIX.strip(chr(92))}")
    if not re.search(r'requiredAddons\[\]\s*=\s*\{\s*"cba_main"\s*\}', text):
        problems.append('auqol_main must require exactly {"cba_main"}')
    check("config.cpp: XEH paths exist, PBO prefix matches, CBA is the only hard dependency", problems)

    # FILEMAP.md must mention every code folder and top-level doc, so it stays in step with the repo.
    filemap = (ROOT / "FILEMAP.md").read_text()
    problems = []
    folders = [p.relative_to(ADDON).as_posix() + "/" for p in sorted(ADDON.glob("*/*")) if p.is_dir()]
    docs = [p.relative_to(ROOT).as_posix() for p in sorted(ROOT.glob("*.md")) + sorted((ROOT / "docs").glob("*.md"))]
    for name in folders + docs:
        if f"`{name}" not in filemap:
            problems.append(f"{name} missing from FILEMAP.md")
    check("FILEMAP.md lists every code folder and doc", problems)


# --- Settings ----------------------------------------------------------------------------------

def settings():
    text = strip_comments((ADDON / "XEH_preInit.sqf").read_text())
    return re.findall(r'^\s*"(auqol_\w+)",\s*"(CHECKBOX|SLIDER|LIST|EDITBOX)"', text, re.M)


def check_settings():
    declared = settings()
    names = {n for n, _ in declared}
    problems = []
    if len(names) != len(declared):
        problems.append("duplicate setting names")
    docs = (ROOT / "docs" / "configuration.md").read_text()
    for name in names:
        if f"`{name}`" not in docs:
            problems.append(f"{name} missing from docs/configuration.md")
    # Every auqol_ global read in code is a setting or assigned somewhere in the mod.
    assigned = set()
    reads = set()
    for code in sqf_code().values():
        nostr = strip_strings(code)
        assigned.update(re.findall(r"\b(auqol_\w+)\s*=(?!=)", nostr))
        reads.update(re.findall(r"\b(auqol_\w+)\b", nostr))
    for var in sorted(reads - names - assigned):
        problems.append(f"global {var} is read but never declared or assigned")
    check("CBA settings: unique, documented in docs/configuration.md, no undeclared auqol_ globals", problems)
    return names


# --- Regression checks for fixed edge cases ----------------------------------------------------

def check_regressions():
    """Static guards for the 1.8.1 fixes and later baselines. They prove the safeguard is in the code, not that it works in game."""
    def code(rel):
        return strip_comments((ADDON / rel).read_text())
    problems = []
    gather = code("functions/loot/fn_lootGather.sqf")
    guard = gather.find("remoteExecutedOwner == owner _caller")
    for later in ("AUQOL_fnc_lootCaches", "spawn SCRT_fnc_loot_gatherLoot", "auqol_lootRequested"):
        if guard == -1 or gather.find(later) < guard:
            problems.append(f"lootGather: sender check must come before {later}")
    for needed in ("isPlayer _caller", "isNull objectParent _caller", "_caller distance _object"):
        if needed not in gather[:max(guard, 0) + 200]:
            problems.append(f"lootGather: caller check {needed} missing")
    if gather.find('"auqol_lootRequested", -10]') > gather.find("AUQOL_fnc_lootCaches"):
        problems.append("lootGather: duplicate-request check must come before emptying caches")
    action = code("functions/loot/fn_lootAddAction.sqf")
    if 'remoteExecCall ["AUQOL_fnc_lootGather", 2]' not in action or "CBA_fnc_serverEvent" in action:
        problems.append("lootAddAction: request must go by remoteExecCall with the caller")
    loadout = code("functions/loadout/fn_loadoutFilter.sqf")
    if "[_class] call _filterWeapon" not in loadout:
        problems.append("loadoutFilter: weapons stored in containers must go through _filterWeapon")
    react = code("functions/squad/fn_squadReactApply.sqf")
    if 'setVariable ["auqol_reactSkills", _skills apply { _unit skill _x }, true]' not in react \
            or 'if (isNil "_saved"' not in react:
        problems.append("squadReactApply: original skills must be saved once and publicly")
    night = code("functions/night/fn_nightApply.sqf")
    if 'setVariable ["auqol_nightSkills", _base +' not in night or "if (!_changed)" not in night \
            or 'setVariable ["auqol_nightSkills", _night, true]' not in code("XEH_postInit.sqf"):
        problems.append("nightApply: original skills must be published when the unit changes owner and others' later values kept on restore")
    if "auqol_nightSkills" not in code("functions/squad/fn_squadReactApply.sqf"):
        problems.append("squadReactApply: must hand back night skills before saving its baseline")
    player = code("functions/player/fn_playerApply.sqf")
    for bad in ("setCustomAimCoef 1", "setUnitRecoilCoefficient 1"):
        if bad in player:
            problems.append(f"playerApply: restores a fixed value ({bad}) instead of the saved one")
    crew = code("functions/eject/fn_ejectCrew.sqf")
    evaluate = code("functions/eject/fn_ejectEvaluate.sqf")
    if "auqol_eject_enabled" not in crew:
        problems.append("ejectCrew: must recheck auqol_eject_enabled after the wait")
    if '"auqol_eject_evaluate"' not in evaluate or '"auqol_eject_evaluate"' not in code("XEH_postInit.sqf"):
        problems.append("ejectEvaluate: pending check must be handed to the new owner")
    stuck = code("functions/stuck/fn_stuckEvaluate.sqf")
    if '_now - (_state get "bestAt") < 3 * auqol_stuck_timeout' not in stuck:
        problems.append("stuckEvaluate: movement without a new closest point must stop counting as progress")
    markers = code("functions/map/fn_mapVehicleMarkers.sqf")
    if "([_x] call _iconOf) == _icon" not in markers or "auqol_map_pending set [_x, time];\n            continue;" not in markers:
        problems.append("mapVehicleMarkers: pairing must match the icon and re-pair markers Antistasi moved")
    # 1.15.0: Antistasi stores the helper unit in "helped" (an object), so a bool default breaks the check.
    for path in sorted(ADDON.rglob("*.sqf")):
        if re.search(r'"helped",\s*(false|true)', strip_comments(path.read_text())):
            problems.append(f"{path.name}: Antistasi's \"helped\" is an object; read it with objNull and isNull")
    support = code("functions/combat/fn_combatSupport.sqf")
    if "_unit canAdd" not in support:
        problems.append("combatSupport: magazine sharing must check the receiver has room (canAdd)")
    # 1.20.1: the night pass filters one per-side enemy list instead of a nearEntities search per soldier,
    # the squad AI's concealment baseline stays public, and the recurring timers start staggered.
    if "inAreaArray [getPosATL _unit, _reach, _reach]" not in night or "nearEntities" not in night:
        problems.append("nightApply: full pass must use the per-side enemy list, single checks nearEntities")
    if 'setVariable ["auqol_concealCoef", [_base, _unit getUnitTrait "camouflageCoef", _factor], !isPlayer _unit]' not in code("functions/conceal/fn_concealTick.sqf"):
        problems.append("concealTick: squad AI concealment baseline must stay public, the player's local")
    if "call CBA_fnc_addPerFrameHandler;" in code("functions/common/fn_settingsInitialized.sqf").replace("_this call CBA_fnc_addPerFrameHandler", ""):
        problems.append("settingsInitialized: recurring timers must start through _every (staggered)")
    check("Regression guards: loot request, nested loadout items, skill baselines, sway/recoil restore, ejection, stuck progress, marker pairing, helped flag, magazine room, night search, concealment publicity, staggered timers", problems)


# --- Wiki-backed checks ------------------------------------------------------------------------

SQF_KEYWORDS = {"private", "params", "if", "then", "else", "exitWith", "forEach", "while", "do", "switch",
                "case", "default", "true", "false", "nil", "call", "spawn", "select", "count", "continue",
                "from", "to", "step", "for", "with", "isNil", "isNull", "not", "and", "or"}
MAGIC = {"_this", "_x", "_y", "_forEachIndex", "_thisEventHandler", "_thisSetting"}
EXTERNAL_GLOBALS = {"teamPlayer", "HR_GRG_Vehicles", "HR_GRG_Sources", "missionNamespace", "player",
                    "BIS_fnc_holdActionAdd", "BIS_fnc_holdActionRemove", "SCRT_fnc_loot_gatherLoot",
                    "SCRT_fnc_common_getNearPlayers", "SCRT_fnc_arsenal_loadoutArsenal", "BIS_fnc_addScriptedEventHandler",
                    "BIS_fnc_baseWeapon", "BIS_fnc_rscLayer", "rebelLoadouts", "jna_dataList"}


def check_wiki(wiki):
    commands = {p.stem.lower(): p for p in (wiki / "commands").glob("*.yml")}
    events = {}
    for kind in (wiki / "events").iterdir():
        for p in kind.glob("*.yml"):
            events.setdefault(kind.name, {})[p.stem] = p

    # 1. Every bare identifier is a real SQF command or a known variable/function (addon and in-game test scripts).
    problems = []
    for path, code in sqf_code(include_ingame=True).items():
        code = strip_strings(code)
        code = re.sub(r"#define[^\n]*", "", code)
        defines = set(re.findall(r"#define\s+(\w+)", path.read_text()))
        for ident in sorted(set(re.findall(r"(?<![\w#])([A-Za-z]\w*)\b", code))):
            if ident.lower() in commands or ident in SQF_KEYWORDS or ident in EXTERNAL_GLOBALS or ident in defines:
                continue
            if re.match(r"(auqol_|AUQOL_fnc_|CBA_fnc_|ace_\w+_fnc_|HR_GRG_fnc_|A3A_)", ident):
                continue
            if re.fullmatch(r"\d\w*", ident):
                continue
            problems.append(f"{path.relative_to(ROOT)}: '{ident}' is not an Arma 3 command or known symbol")
    check("SQF: every command used exists in the Arma 3 wiki command list", problems)

    # 2. Event handler names and the parameter positions the code relies on.
    used_object = set()
    used_mission = set()
    for code in sqf_code().values():
        used_object.update(re.findall(r'addEventHandler \["(\w+)"', code))
        used_mission.update(re.findall(r'addMissionEventHandler \["(\w+)"', code))
    problems = []
    for name in used_object:
        if name not in events.get("standard", {}) and name not in events.get("group", {}):
            problems.append(f"object or group event handler {name} not in the wiki")
    for name in used_mission:
        if name not in events.get("mission", {}):
            problems.append(f"mission event handler {name} not in the wiki")
    expected_params = {
        ("standard", "Dammaged"): ["unit"],
        ("standard", "Fuel"): ["vehicle", "hasFuel"],
        ("standard", "GetIn"): ["vehicle"],
        ("mission", "Service"): ["serviceVehicle", "servicedVehicle", "serviceType"],
        ("mission", "MarkerCreated"): ["marker"],
        ("mission", "MarkerDeleted"): ["marker"],
        ("group", "EnemyDetected"): ["group", "newTarget"],
        ("group", "UnitJoined"): ["group", "newUnit"],
    }
    for (kind, name), params in expected_params.items():
        path = events.get(kind, {}).get(name)
        if not path:
            problems.append(f"{kind} event {name} not in the wiki")
            continue
        actual = re.findall(r"^- name: (\w+)", path.read_text(), re.M)
        if actual[:len(params)] != params:
            problems.append(f"{name} params are {actual}, code assumes {params}")
    check("Event handlers: names exist and the parameter positions used match the wiki", problems)

    # 3. Locality heuristic: files using local-argument commands must contain a locality guard.
    local_arg = {stem for stem, p in commands.items() if re.search(r"^argument_loc: Local", p.read_text(), re.M)}
    problems = []
    for path, code in sqf_code().items():
        nostr = strip_strings(code)
        used = {c for c in re.findall(r"\b([A-Za-z]\w*)\b", nostr) if c.lower() in local_arg}
        used -= {"params", "private"}
        if used and not re.search(r"\b(local|isServer|hasInterface)\b", nostr):
            problems.append(f"{path.relative_to(ROOT)} uses local-argument {sorted(used)} without a local/isServer/hasInterface guard")
    check("Locality (heuristic): local-argument commands are guarded", problems)


# --- Source-backed checks ----------------------------------------------------------------------

def all_text(root, patterns):
    out = []
    for pattern in patterns:
        for p in root.rglob(pattern):
            try:
                out.append(p.read_text(errors="ignore"))
            except OSError:
                pass
    return "\n".join(out)


def check_cba(cba):
    problems = []
    for fnc in sorted({f for c in sqf_code().values() for f in re.findall(r"\bCBA_fnc_\w+", c)}):
        name = fnc[len("CBA_fnc_"):]
        if not list(cba.rglob(f"fnc_{name}.sqf")):
            problems.append(f"{fnc} not found in CBA_A3")
    text = all_text(cba / "addons", ["*.sqf", "*.hpp", "*.cpp"])
    for needed in ['"CBA_settingsInitialized"', "class ADDON", "Extended_PreInit_EventHandlers",
                   "Extended_PostInit_EventHandlers", '"InitPost"', '"unit"', '"loadout"']:
        if needed not in text:
            problems.append(f"{needed} not found in CBA_A3")
    if 'PREFIX cba' not in text or not (cba / "addons" / "main" / "config.cpp").is_file():
        problems.append("cba_main CfgPatches class not found")
    check("CBA_A3: every CBA function, event and config class used exists", problems)


def check_ace(ace):
    problems = []
    code = "\n".join(sqf_code().values())
    for comp, name in sorted(set(re.findall(r"\bace_(\w+?)_fnc_(\w+)", code))):
        if not (ace / "addons" / comp / "functions" / f"fnc_{name}.sqf").is_file():
            problems.append(f"ace_{comp}_fnc_{name} not found in ACE3")
    # ACE variables: ace_<component>_<name> must appear as GVAR/QGVAR(<name>) in that component.
    for var in sorted(set(re.findall(r'"(ace_[A-Za-z0-9_]+)"', code))):
        if "_fnc_" in var:
            continue
        if var in ("ace_main", "ace_medical_engine"):  # CfgPatches classes (PREFIX ace, COMPONENT name), not variables
            if not (ace / "addons" / var[len("ace_"):] / "config.cpp").is_file():
                problems.append(f"{var} CfgPatches not found in ACE3")
            continue
        found = False
        for comp_dir in (ace / "addons").iterdir():
            comp = comp_dir.name
            if var.startswith(f"ace_{comp}_"):
                name = var[len(f"ace_{comp}_"):]
                src = all_text(comp_dir, ["*.sqf", "*.hpp", "*.cpp"])
                if re.search(rf"\bQ?GVAR\({re.escape(name)}\)", src):
                    found = True
                    break
        if not found:
            problems.append(f"{var} not found as a variable in ACE3")
    for define, value in (("REFUEL_INFINITE_FUEL", "-10"),):
        if not re.search(rf"#define {define} {value}\b", (ace / "addons" / "refuel" / "defines.hpp").read_text()):
            problems.append(f"{define} is not {value} in ACE3")
    text = all_text(ace / "addons" / "refuel", ["*.hpp"])
    if "class Land_CanisterFuel_F" not in text:
        problems.append("Land_CanisterFuel_F not found in ACE refuel config")
    compat = all_text(ace / "addons", ["config.cpp"])
    for patch in ("rhs_main_loadorder", "rhsusf_main_loadorder", "CUP_Vehicles_LoadOrder"):
        if f'"{patch}"' not in compat:
            problems.append(f"CfgPatches {patch} not referenced by ACE compat")
    check("ACE3: every ACE function, variable, constant and class used exists", problems)


def check_antistasi(au):
    problems = []
    code = "\n".join(sqf_code().values())
    src = all_text(au / "A3A" / "addons", ["*.sqf", "*.hpp", "*.cpp", "*.inc"])
    for fnc in sorted(set(re.findall(r"\bHR_GRG_fnc_(\w+)", code))):
        if not list((au / "A3A" / "addons" / "garage").rglob(f"fn_{fnc}.sqf")):
            problems.append(f"HR_GRG_fnc_{fnc} not found in Antistasi garage")
    for needed in ("HR_GRG_Vehicles", "HR_GRG_Sources", "A3A_hasAce", "teamPlayer =", '"surrendered"',
                   "#define HR_GRG_SOURCEINDEX 6", "class HR_GRG", 'requiredAddons[] = {"A3A_core"}'):
        if needed not in src:
            problems.append(f"{needed} not found in Antistasi Ultimate")
    # The stored fuel layout the garage restore writes to: [fuel, fuelCargo, aceFuelCargo].
    getfuel = next((au / "A3A" / "addons" / "garage").rglob("fn_getFuel.sqf")).read_text()
    if 'getFuelCargo _vehicle, _vehicle getVariable ["ace_refuel_currentFuelCargo"' not in getfuel:
        problems.append("garage fuel state layout changed (fn_getFuel.sqf)")
    # Loot gathering: the crate's function, action, radius parameter and class AUQOL mirrors.
    loot = au / "A3A" / "addons" / "scrt" / "Loot"
    gather = (loot / "fn_loot_gatherLoot.sqf").read_text()
    if 'params ["_vehicle", "_radius", ["_overridePosition",[]]]' not in gather:
        problems.append("SCRT_fnc_loot_gatherLoot parameters changed")
    if "_overridePosition isEqualTo [] && {[getPosATL player, _radius] call A3A_fnc_enemyNearCheck}" not in gather:
        problems.append("SCRT_fnc_loot_gatherLoot no longer skips its enemy check when given a position")
    if not list((au / "A3A" / "addons" / "scrt").rglob("fn_common_getNearPlayers.sqf")) or not list((au / "A3A" / "addons").rglob("fn_enemyNearCheck.sqf")):
        problems.append("SCRT_fnc_common_getNearPlayers or A3A_fnc_enemyNearCheck not found")
    addaction = (loot / "fn_loot_addActionLoot.sqf").read_text()
    for needed in ('"lootActionID"', "STR_antistasi_actions_loot_around_text", "holdaction_box_ca.paa", "lootCrateDistance"):
        if needed not in addaction:
            problems.append(f"{needed} not found in fn_loot_addActionLoot.sqf")
    for needed in ('_faction get "ammobox"', 'setVariable ["A3A_canGarage", true, true]', '"GroundWeaponHolder"', '"lastLooted"',
                   "class lootCrateDistance", '["lootCrate", "A3AP_Box_Syndicate_Ammo_F"]', "class A3AP_Box_Syndicate_Ammo_F"):
        if needed not in src:
            problems.append(f"{needed} not found in Antistasi Ultimate")
    # Withstand: the cooldown A3A_fnc_selfRevive reads from missionNamespace.
    selfrevive = next((au / "A3A" / "addons" / "core").rglob("fn_selfRevive.sqf")).read_text()
    if 'missionNamespace getVariable ["A3A_selfReviveTimeout", 300]' not in selfrevive:
        problems.append("A3A_fnc_selfRevive no longer reads missionNamespace A3A_selfReviveTimeout")
    # Rebel loadout editor ("Copy from user"): the editor flag, the stored player loadout, the editor step
    # AUQOL reuses (and the _display it reads from the caller), the slot override switch, the blanked
    # Random button, and the arsenal's unlimited marker.
    editor = (au / "A3A" / "addons" / "scrt" / "Arsenal" / "fn_arsenal_loadoutArsenal.sqf").read_text()
    for needed in ('case "applyInitialLoadout":', 'localNamespace setVariable ["commanderLoadout", getUnitLoadout player];',
                   "private _loadout = _rebelLoadouts get currentRebelLoadout;", "['showMessage',[_display,",
                   'case "OverrideTab":', "private _tabBtnCtrl = _display displayCtrl (_IDC - 30);",
                   '_tabBtnCtrl setVariable ["OverrideTab", _override];',
                   "_ctrlButtonRandom = _display displayctrl IDC_RSCDISPLAYARSENAL_CONTROLSBAR_BUTTONRANDOM;",
                   'if(_amount == -1)exitWith{"[   ∞  ]  ";};'):
        if needed not in editor:
            problems.append(f"{needed} not found in fn_arsenal_loadoutArsenal.sqf")
    jna_init = (au / "A3A" / "addons" / "jeroen_arsenal" / "JNA" / "fn_arsenal_init.sqf").read_text()
    for needed in ('[missionNamespace, "arsenalOpened", {', 'case (uiNamespace getVariable ["isLoadoutArsenal", false]):'):
        if needed not in jna_init:
            problems.append(f"{needed} not found in JNA fn_arsenal_init.sqf")
    handle = (au / "A3A" / "addons" / "jeroen_arsenal" / "JNA" / "fn_arsenal_handleAction.sqf").read_text()
    if '["jn_fnc_arsenal", "Loading Nutz™ Arsenal"] call bis_fnc_startloadingscreen;' not in handle:
        problems.append("JNA no longer opens with the jn_fnc_arsenal loading screen")
    # Stuck recovery: unit state variables Antistasi sets, read to leave busy units alone.
    for needed in ('setVariable ["incapacitated"', 'setVariable ["helping"', 'setVariable ["rearming"'):
        if needed not in src:
            problems.append(f"{needed} not found in Antistasi Ultimate")
    # Live vehicle markers: the marker name, type and update loop AUQOL_fnc_mapVehicleMarkers recognises.
    markers = next((au / "A3A" / "addons" / "core").rglob("fn_vehicleMarkers.sqf")).read_text()
    for needed in ('createMarkerLocal [format ["%2%1", random 100,_text], position _veh];', '_typeX = format ["%1%2",_formatX,_typeX];',
                   '_mrkFinal setMarkerTextLocal _text;', '"_motor_inf"', '"_mech_inf"', '"_armor"', '"_plane"', '"_uav"', '"_air"',
                   '"_naval"', '"_unknown"', 'sleep 60;'):
        if needed not in markers:
            problems.append(f"{needed} not found in fn_vehicleMarkers.sqf")
    # Loot request: remoteExecCall to an AUQOL function needs the mission to allow mod functions.
    remote = (au / "A3A" / "addons" / "maps" / "MissionDescription" / "CfgRemoteExec.hpp").read_text()
    if not re.search(r"class Functions\s*\{\s*mode = 2;", remote):
        problems.append("Antistasi CfgRemoteExec no longer allows all functions (loot request uses remoteExecCall)")
    if "STR_antistasi_actions_looter_cooldown_text" not in gather:
        problems.append("STR_antistasi_actions_looter_cooldown_text not found in fn_loot_gatherLoot.sqf")
    # Marker pairing mirrors the icon rules in this order.
    order = [markers.find(f'_veh isKindOf "{c}"') for c in ("Truck", "Wheeled_APC_F", "Tank", "Plane_Base_F", "UAV_02_base_F", "Helicopter", "Boat_F")]
    if -1 in order or order != sorted(order):
        problems.append("fn_vehicleMarkers.sqf vehicle icon rules changed (AUQOL_fnc_mapVehicleMarkers mirrors them)")
    check("Antistasi Ultimate: garage, loot, Withstand, loadout editor, vehicle marker and unit state names used exist", problems)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--cba", type=Path)
    parser.add_argument("--ace", type=Path)
    parser.add_argument("--antistasi", type=Path)
    parser.add_argument("--wiki", type=Path)
    args = parser.parse_args()

    check_functions()
    check_config_paths()
    check_settings()
    check_regressions()
    for label, path, fn in (("Arma 3 wiki", args.wiki, check_wiki), ("CBA_A3", args.cba, check_cba),
                            ("ACE3", args.ace, check_ace), ("Antistasi Ultimate", args.antistasi, check_antistasi)):
        if path and path.is_dir():
            fn(path)
        else:
            skipped.append(f"{label} checks (no source path given)")

    for name in passed:
        print(f"PASS  {name}")
    for name, problems in failures:
        print(f"FAIL  {name}")
        for p in problems:
            print(f"      - {p}")
    for name in skipped:
        print(f"SKIP  {name}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
