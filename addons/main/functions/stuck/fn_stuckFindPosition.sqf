/*
    Author: AUQOL
    Finds a safe spot for a stuck unit or vehicle near a centre position. findEmptyPosition looks
    for a spot where an object of that type fits without touching other objects; the spot is then
    rejected when it is in water, on a slope steeper than about 37 degrees, under a roof (inside a
    building), more than 3 m above or below the centre (cliffs, rooftops), or within 100 m of a unit
    or vehicle hostile to the players (AUQOL_fnc_isHostileSide).

    Arguments:
    0: Unit or vehicle to place <OBJECT>
    1: Centre <ARRAY> (position ATL)
    2: Search radius <NUMBER>

    Return Value: Position ATL, or [] when nothing safe was found <ARRAY>
*/

params ["_object", "_center", "_radius"];

private _spot = _center findEmptyPosition [0, _radius, typeOf _object];
if (_spot isEqualTo []) exitWith { [] };
_spot set [2, 0];

private _asl = AGLToASL _spot;
private _unsafe = surfaceIsWater _spot
    || {(surfaceNormal _spot) select 2 < 0.8}
    || {abs ((_asl select 2) - ((AGLToASL _center) select 2)) > 3}
    || {lineIntersectsSurfaces [_asl vectorAdd [0, 0, 1.5], _asl vectorAdd [0, 0, 20], _object] isNotEqualTo []}
    || {(_spot nearEntities [["CAManBase", "LandVehicle", "StaticWeapon"], 100]) findIf { alive _x && {[side group _x] call AUQOL_fnc_isHostileSide} } != -1};

[_spot, []] select _unsafe
