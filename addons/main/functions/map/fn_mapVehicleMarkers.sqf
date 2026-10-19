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

    New markers come from the MarkerCreated mission event (auqol_map_pending), so a pass only looks at
    markers created since the last one; Antistasi sets the text after creating the marker, so a pending
    marker waits up to 10 s for it. A full allMapMarkers scan every 30 s catches anything the event
    missed. A tracked marker is only moved when its vehicle is more than 5 m from it.

    Arguments: none
    Return Value: none
*/

if (!hasInterface || {!auqol_ready} || {!auqol_map_liveVehicles}) exitWith {};

// Drop markers Antistasi deleted, then move the rest when their vehicle has moved.
{
    // A deleted marker has no type; cheaper than searching allMapMarkers for each tracked marker.
    if (markerType _x == "" || {isNull _y}) then { auqol_map_tracked deleteAt _x; continue };
    if (alive _y && {(markerPos _x) distance2D _y > 5}) then { _x setMarkerPosLocal getPos _y };
} forEach +auqol_map_tracked;

private _candidates = keys auqol_map_pending;
if (time >= auqol_map_nextScan) then {
    auqol_map_nextScan = time + 30;
    _candidates = allMapMarkers;
};

{
    if (_x in auqol_map_tracked || {_x in auqol_map_ignored}) then { auqol_map_pending deleteAt _x; continue };
    private _text = markerText _x;
    // Antistasi sets the text last, so a marker without text yet is checked again next pass.
    if (_text == "") then {
        private _since = auqol_map_pending getOrDefault [_x, -1];
        if (_since < 0) then { auqol_map_pending set [_x, time]; continue };
        if (markerType _x == "" || {time - _since > 10}) then { auqol_map_pending deleteAt _x };
        continue;
    };
    auqol_map_pending deleteAt _x;
    if ((_x select [0, count _text]) != _text
        || {!((_x select [count _text]) regexMatch "[0-9.e+-]+")}
        || {!(markerType _x regexMatch "[nbo]_(motor_inf|mech_inf|armor|plane|uav|air|naval|unknown)")}) then {
        auqol_map_ignored set [_x, true];
        continue;
    };
    private _taken = values auqol_map_tracked;
    private _near = nearestObjects [markerPos _x, ["LandVehicle", "Air", "Ship"], 150];
    private _index = _near findIf { alive _x && {!(_x in _taken)} };
    // Not paired yet: keep it pending so the next pass tries again.
    if (_index == -1) then { auqol_map_pending set [_x, time] } else { auqol_map_tracked set [_x, _near select _index] };
} forEach _candidates;
