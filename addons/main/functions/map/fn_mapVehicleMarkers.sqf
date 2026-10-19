/*
    Author: AUQOL
    Live map markers for the vehicles Antistasi marks (convoy objectives, mission vehicles, supply
    boxes and enemy vehicles your side has spotted). Antistasi's A3A_fnc_vehicleMarkers creates a
    local marker per vehicle on each client and moves it only once every 60 s; this pass, run every
    second on each client, moves those markers to their vehicle. Antistasi still creates and deletes
    them, so nothing new appears on the map.

    A marker is recognised by the shape A3A_fnc_vehicleMarkers gives it: its name is its text followed
    by a random number, and its type is a NATO vehicle icon. It is paired with the nearest vehicle
    within 150 m of where it was created; one that cannot be paired yet is tried again on later passes.

    Arguments: none
    Return Value: none
*/

if (!hasInterface || {!auqol_ready} || {!auqol_map_liveVehicles}) exitWith {};

// Drop markers Antistasi deleted, then move the rest.
{
    if (!(_x in allMapMarkers) || {isNull _y}) then { auqol_map_tracked deleteAt _x; continue };
    if (alive _y) then { _x setMarkerPosLocal getPos _y };
} forEach +auqol_map_tracked;

{
    if (_x in auqol_map_tracked || {_x in auqol_map_ignored}) then { continue };
    private _text = markerText _x;
    // Antistasi sets the text last, so a marker without text yet is checked again next pass.
    if (_text == "") then { continue };
    if ((_x select [0, count _text]) != _text
        || {!((_x select [count _text]) regexMatch "[0-9.e+-]+")}
        || {!(markerType _x regexMatch "[nbo]_(motor_inf|mech_inf|armor|plane|uav|air|naval|unknown)")}) then {
        auqol_map_ignored set [_x, true];
        continue;
    };
    private _taken = values auqol_map_tracked;
    private _near = nearestObjects [markerPos _x, ["LandVehicle", "Air", "Ship"], 150];
    private _index = _near findIf { alive _x && {!(_x in _taken)} };
    if (_index != -1) then { auqol_map_tracked set [_x, _near select _index] };
} forEach allMapMarkers;
