/*
    Author: AUQOL
    Radio net: whether a group is the crew of an Antistasi rebel post, and of which kind. Antistasi gives every
    unit of a post crew the post's marker (A3A_fnc_FIAinitBases sets "markerX", public), so the group is a post
    when its leader's marker is in one of Antistasi's post lists (watchpostsFIA, atpostsFIA, aapostsFIA,
    hmgpostsFIA, roadblocksFIA). A patrol walking past a post is not one. A post kind is kept on the group for
    good (auqol_radioType, this machine only); other groups are read again each time, which is a getVariable
    and five list lookups. High command squads are checked by the callers, since a squad can be added to or
    taken out of high command any time.

    Arguments:
    0: Group <GROUP>

    Return Value: "watch", "at", "aa", "hmg", "roadblock", or "" (not a post) <STRING>
*/

params ["_group"];
private _type = _group getVariable "auqol_radioType";
if (!isNil "_type") exitWith { _type };
private _marker = (leader _group) getVariable ["markerX", ""];
if (_marker isEqualTo "") exitWith { "" };
_type = "";
{
    _x params ["_list", "_kind"];
    if (_marker in (missionNamespace getVariable [_list, []])) exitWith { _type = _kind };
} forEach [["watchpostsFIA", "watch"], ["atpostsFIA", "at"], ["aapostsFIA", "aa"], ["hmgpostsFIA", "hmg"], ["roadblocksFIA", "roadblock"]];
if (_type isNotEqualTo "") then { _group setVariable ["auqol_radioType", _type] };
_type
