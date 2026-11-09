/*
    Author: AUQOL
    Radio net: whether a group is the crew of an Antistasi rebel post, and of which kind. A post's crew is
    spawned at its marker, so the group is a post when its leader stands within 50 m of a marker in one of
    Antistasi's post lists (watchpostsFIA, atpostsFIA, aapostsFIA, hmgpostsFIA, roadblocksFIA). Posts do not
    move, so the answer is kept on the group for good (auqol_radioType, this machine only). High command
    squads are checked by the callers, since a squad can be added to or taken out of high command any time.

    Arguments:
    0: Group <GROUP>

    Return Value: "watch", "at", "aa", "hmg", "roadblock", or "" (not a post) <STRING>
*/

params ["_group"];
private _type = _group getVariable "auqol_radioType";
if (!isNil "_type") exitWith { _type };
private _leader = leader _group;
if (!alive _leader) exitWith { "" }; // not kept: the group is read again once it has a living leader
_type = "";
private _pos = getPosATL _leader;
{
    _x params ["_list", "_kind"];
    if ((missionNamespace getVariable [_list, []]) findIf { _pos distance2D getMarkerPos _x < 50 } != -1) exitWith { _type = _kind };
} forEach [["watchpostsFIA", "watch"], ["atpostsFIA", "at"], ["aapostsFIA", "aa"], ["hmgpostsFIA", "hmg"], ["roadblocksFIA", "roadblock"]];
_group setVariable ["auqol_radioType", _type];
_type
