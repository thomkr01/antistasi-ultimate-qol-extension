/*
    Author: AUQOL
    Live map markers for the vehicles Antistasi marks (convoy objectives, mission vehicles, supply
    boxes and enemy vehicles your side has spotted). Antistasi's A3A_fnc_vehicleMarkers creates a
    local marker per vehicle on each client and moves it only once every 60 s; this pass moves those
    markers to their vehicle every second while the map or GPS panel is open, every 10 s while both
    are closed, and once when the map is opened. Antistasi still creates and deletes them, so nothing
    new appears on the map.

    A marker is recognised by the shape A3A_fnc_vehicleMarkers gives it: its name is its text followed
    by a random number, and its type is a NATO vehicle icon. Antistasi stores no link between the
    marker and its vehicle, so it is paired with the nearest unpaired vehicle within 150 m of where it
    was created whose kind gives the same icon (car or truck, tank, plane, UAV, helicopter, boat, by the
    same rules Antistasi uses); one that cannot be paired yet is tried again on later passes.

    Antistasi itself still moves each marker to its real vehicle once a minute. A tracked marker that
    Antistasi moved somewhere its paired vehicle cannot be is a wrong pairing: it is left where Antistasi
    put it and paired again from there, so a wrong match is fixed within a minute without the marker
    jumping back and forth.

    New markers come from the MarkerCreated mission event (auqol_map_pending), so a pass only looks at
    markers created since the last one; Antistasi sets the text after creating the marker, so a pending
    marker waits up to 10 s for it. A full allMapMarkers scan every 30 s catches anything the event
    missed. A tracked marker is only moved when its vehicle is more than 5 m from it.

    Arguments: none
    Return Value: none
*/

if (!hasInterface || {!auqol_ready} || {!auqol_map_liveVehicles}) exitWith {};

// Nobody sees the markers move while the map and GPS panel are closed, so then the pass only runs every 10 s.
private _hidden = !visibleMap && {!visibleGPS};
if (_hidden && {time < auqol_map_nextIdle}) exitWith {};
if (_hidden) then { auqol_map_nextIdle = time + 10 };

// The icon suffix A3A_fnc_vehicleMarkers picks for a vehicle, in its order (an APC is a Car, so "motor_inf").
private _iconOf = {
    params ["_veh"];
    switch (true) do {
        case (_veh isKindOf "Truck" || {_veh isKindOf "Car"}): {"motor_inf"};
        case (_veh isKindOf "Wheeled_APC_F"): {"mech_inf"};
        case (_veh isKindOf "Tank"): {"armor"};
        case (_veh isKindOf "Plane_Base_F"): {"plane"};
        case (_veh isKindOf "UAV_02_base_F"): {"uav"};
        case (_veh isKindOf "Helicopter"): {"air"};
        case (_veh isKindOf "Boat_F"): {"naval"};
        default {"unknown"};
    }
};

// Drop markers Antistasi deleted, check the ones Antistasi moved, then move the rest when their vehicle moved.
{
    _y params ["_veh", "_setPos"];
    // A deleted marker has no type; cheaper than searching allMapMarkers for each tracked marker.
    if (markerType _x == "" || {isNull _veh}) then { auqol_map_tracked deleteAt _x; continue };
    private _markerPos = markerPos _x;
    if (_markerPos distance2D _setPos > 1) then {
        // Antistasi put it on its vehicle within the last second; ours could have moved 20 m plus 2 s of its speed.
        if (_veh distance2D _markerPos > 20 + 2 * abs (speed _veh) / 3.6) then {
            auqol_map_tracked deleteAt _x;
            auqol_map_pending set [_x, time];
            continue;
        };
        (auqol_map_tracked get _x) set [1, _markerPos];
    };
    if (alive _veh && {_markerPos distance2D _veh > 5}) then {
        _x setMarkerPosLocal getPos _veh;
        (auqol_map_tracked get _x) set [1, markerPos _x];
    };
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
    private _taken = values auqol_map_tracked apply { _x select 0 };
    private _icon = markerType _x select [2];
    private _near = nearestObjects [markerPos _x, ["LandVehicle", "Air", "Ship"], 150];
    private _index = _near findIf { alive _x && {!(_x in _taken)} && {([_x] call _iconOf) == _icon} };
    // Not paired yet: keep it pending so the next pass tries again.
    if (_index == -1) then { auqol_map_pending set [_x, time] } else { auqol_map_tracked set [_x, [_near select _index, markerPos _x]] };
} forEach _candidates;
