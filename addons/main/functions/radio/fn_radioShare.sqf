/*
    Author: AUQOL
    Radio net: a group of the rebel side passes an enemy it has spotted to the rest of the side over the
    radio. Called from every AI group's EnemyDetected hook (AUQOL_fnc_combatGroupHook) and, with LAMBS Danger
    loaded, each time LAMBS shares a sighting (its lambs_main_OnInformationShared event, XEH_postInit).
    Runs where the sending group is local (server or headless client), since knowsAbout is read there.

    Who sends: Antistasi rebel posts (watchpost, AT, AA, HMG, roadblock), high command squads, garrisons with
    auqol_radio_garrisons on, and with LAMBS any AI group of the side that LAMBS let share. Never a group led by
    a player: they share through the T key, look to spot and smart combat contact reports.
    Steps:
    1. The sender needs a radio (AUQOL_fnc_radioHasRadio), unless auqol_radio_requireRadio is off.
    2. Cascade guard: an enemy goes out on the radio at most once every 15 s per machine (auqol_radioAt on the
       enemy). A receiver that learns about him gets its own EnemyDetected, and that stops here.
    3. Receivers (AUQOL_fnc_radioReceivers) within range of the enemy, measured from each receiver's leader:
       AA posts 2000 m for aircraft, AT posts 1000 m for vehicles, everyone else 750 m. Twice that when the
       sender or the receiver carries a radio backpack, or always when a radio is not required. A receiver
       needs a radio as well, is not CARELESS and is simulated. Garrisons: the 8 nearest.
    4. Each receiver gets the sender's own knowledge (knowsAbout, at most 4) through the auqol_combat_reveal
       event on its leader's machine. Nothing else: no orders, waypoints or combat modes change, so
       Antistasi and PATCOM keep control of where everyone goes. Crews with sight of him shoot on their own.
    5. Each player of the side within auqol_radio_calloutRange of the enemy (twice that for vehicles and
       aircraft) gets a call-out ("AA post: Contact! ...", AUQOL_fnc_squadCallout) on their own machine.

    Arguments:
    0: Sending group <GROUP>
    1: Enemy <OBJECT>
    2: From LAMBS <BOOL> (default: false): any AI group of the side may send

    Return Value: none
*/

params ["_group", "_target", ["_fromLambs", false]];
if (!auqol_ready || {!auqol_radio_net} || {!local _group} || {!alive _target} || {captive _target}) exitWith {};
private _side = side _group;
if (_side isNotEqualTo (missionNamespace getVariable ["teamPlayer", sideUnknown]) || {isPlayer leader _group}
    || {!alive leader _group} || {(side group _target) getFriend _side >= 0.6}
    || {time < (_target getVariable ["auqol_radioAt", -1e9]) + 15}) exitWith {}; // cheap early exit; LAMBS can share many times a second

["radio net", {
    private _boss = missionNamespace getVariable ["theBoss", objNull];
    private _kind = if (!isNull _boss && {_group in hcAllGroups _boss}) then { "hc" } else { [_group] call AUQOL_fnc_radioGroupType };
    if (_kind isEqualTo "") then { _kind = call { if (auqol_radio_garrisons) exitWith { "garrison" }; ["", "lambs"] select _fromLambs } };
    if (_kind isEqualTo "") exitWith {};

    ([_group] call AUQOL_fnc_radioHasRadio) params ["_hasRadio", "_senderBag"];
    if (!_hasRadio) exitWith {};
    private _level = (_group knowsAbout _target) min 4;
    if (_level <= 0) exitWith {};
    _target setVariable ["auqol_radioAt", time];

    private _isAir = _target isKindOf "Air";
    private _isVehicle = !(_target isKindOf "CAManBase");
    private _receivers = [] call AUQOL_fnc_radioReceivers;
    private _garrisons = []; // [distance, index in _receivers]: numbers only, so sort never compares groups
    private _sent = 0;
    {
        _x params ["_receiver", "_receiverKind"];
        private _leader = leader _receiver;
        private _range = call {
            if (_receiverKind isEqualTo "aa" && _isAir) exitWith { 2000 };
            if (_receiverKind isEqualTo "at" && _isVehicle && !_isAir) exitWith { 1000 };
            750
        };
        private _distance = _leader distance2D _target;
        // Cheapest checks first; the radio check reads gear at most every 30 s per group.
        if (_receiver isNotEqualTo _group && {_distance < _range * 2} && {alive _leader} && {side _receiver isEqualTo _side}
            && {simulationEnabled vehicle _leader} && {behaviour _leader isNotEqualTo "CARELESS"}) then {
            ([_receiver] call AUQOL_fnc_radioHasRadio) params ["_receiverRadio", "_receiverBag"];
            if (_receiverRadio && {_distance < _range * ([1, 2] select (_senderBag || _receiverBag))}) then {
                if (_receiverKind isEqualTo "garrison") then { _garrisons pushBack [_distance, _forEachIndex] } else {
                    ["auqol_combat_reveal", [_receiver, _target, _level], _leader] call CBA_fnc_targetEvent;
                    _sent = _sent + 1;
                };
            };
        };
    } forEach _receivers;
    _garrisons sort true;
    {
        private _receiver = _receivers select (_x select 1) select 0;
        ["auqol_combat_reveal", [_receiver, _target, _level], leader _receiver] call CBA_fnc_targetEvent;
    } forEach (_garrisons select [0, 8]);

    if (auqol_squad_callouts) then {
        private _calloutRange = auqol_radio_calloutRange * ([1, 2] select _isVehicle);
        private _label = switch (_kind) do {
            case "watch": { "Watchpost" };
            case "at": { "AT post" };
            case "aa": { "AA post" };
            case "hmg": { "HMG post" };
            case "roadblock": { "Roadblock" };
            default { groupId _group };
        };
        {
            if (side group _x isEqualTo _side && {_x distance2D _target < _calloutRange}) then {
                ["auqol_radio_callout", [_target, _group, _label], _x] call CBA_fnc_targetEvent;
            };
        } forEach (allPlayers - entities "HeadlessClient_F");
    };
    [format ["Radio net: %1 (%2) shared %3 (knows %4) with %5 groups", groupId _group, _kind, typeOf _target, _level toFixed 1, _sent + (count _garrisons min 8)], true] call AUQOL_fnc_log;
}] call AUQOL_fnc_perfRun;
