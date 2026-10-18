/*
    Author: AUQOL
    Returns whether a side is hostile to the players. Uses Antistasi's rebel side (teamPlayer) when the
    mission defines it, otherwise any player's side. Hostile means getFriend below 0.6, the engine's
    own enemy threshold.

    Arguments:
    0: Side to test <SIDE>

    Return Value: <BOOL>

    Example: [side group _unit] call AUQOL_fnc_isHostileSide;
*/

params [["_side", sideUnknown, [sideUnknown]]];

private _rebels = missionNamespace getVariable ["teamPlayer", sideUnknown];
if (_rebels isEqualType sideUnknown && {_rebels != sideUnknown}) exitWith {
    (_side getFriend _rebels) < 0.6
};

allPlayers findIf { (_side getFriend (side group _x)) < 0.6 } != -1
