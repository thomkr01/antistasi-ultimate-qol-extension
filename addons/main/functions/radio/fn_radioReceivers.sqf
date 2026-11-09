/*
    Author: AUQOL
    Radio net: the groups that can hear it, built at most once every 10 s per machine and only when a sighting
    needs it (auqol_radio_receivers, auqol_radio_nextBuild). One pass over allGroups with cheap checks:
    groups of the rebel side (Antistasi's teamPlayer) with a living leader, each with its kind:
    "player" (led by a player: yours and other players' squads), "hc" (a high command squad of the
    commander), a post kind (AUQOL_fnc_radioGroupType) or "garrison" (any other AI group, only with
    auqol_radio_garrisons on). Whether a group is CARELESS, simulated or has a radio changes faster, so
    AUQOL_fnc_radioShare checks that per sighting.

    Arguments: none

    Return Value: [[group, kind], ...] <ARRAY>
*/

if (time < auqol_radio_nextBuild) exitWith { auqol_radio_receivers };
auqol_radio_nextBuild = time + 10;

private _side = missionNamespace getVariable ["teamPlayer", sideUnknown];
private _boss = missionNamespace getVariable ["theBoss", objNull];
private _hc = if (isNull _boss) then { [] } else { hcAllGroups _boss };
private _list = [];
{
    private _leader = leader _x;
    if (side _x isEqualTo _side && {alive _leader}) then {
        private _kind = call {
            if (isPlayer _leader) exitWith { "player" };
            if (_x in _hc) exitWith { "hc" };
            private _post = [_x] call AUQOL_fnc_radioGroupType;
            if (_post isEqualTo "" && auqol_radio_garrisons) exitWith { "garrison" };
            _post
        };
        if (_kind isNotEqualTo "") then { _list pushBack [_x, _kind] };
    };
} forEach allGroups;
auqol_radio_receivers = _list;
_list
