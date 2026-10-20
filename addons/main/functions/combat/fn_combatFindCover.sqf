/*
    Author: AUQOL
    Finds a covered spot for a unit near an anchor point: a position where something solid (terrain,
    a wall, a rock, a tree, a building) is between the enemy and the unit's chest when crouching.
    Candidates are building positions (indoor) and the spot 0.7 m behind the back face of each nearby
    terrain object, wall or fortification as seen from the enemy (outdoor; the face is found with one
    ray). The candidates closest to the anchor are tested first, at most 12 per call, one
    lineIntersectsSurfaces each. Any faction, map or
    addon object works: only the object kinds and shapes are used, never class names.

    Arguments:
    0: Unit <OBJECT>
    1: Enemy position as the group believes it <ARRAY> (AGL)
    2: Anchor <ARRAY> (AGL)
    3: Search radius <NUMBER>
    4: Spots already taken by the group <ARRAY>

    Return Value: [spot <ARRAY> (AGL), indoor <BOOL>], or [] when nothing near gives cover
*/

params ["_unit", "_ePos", "_anchor", "_radius", "_taken"];

private _eyeEnemy = AGLToASL _ePos vectorAdd [0, 0, 1.5];
private _candidates = [];

{
    { _candidates pushBack [_x, true] } forEach (_x buildingPos -1);
} forEach (nearestObjects [_anchor, ["House", "Building"], _radius] select [0, 4]);

private _outdoor = nearestTerrainObjects [_anchor, ["TREE", "ROCK", "ROCKS", "WALL", "FENCE", "HIDE", "BUNKER", "FORTRESS", "RUIN", "HOUSE", "BUILDING"], _radius, false, true];
_outdoor append (nearestObjects [_anchor, ["Wall", "BagFence_base_F", "HBarrier_base_F"], _radius]);
{
    private _size = boundingBoxReal _x select 2;
    if (_size > 0.4 && _size < 50) then { _candidates pushBack [getPosATL _x, false, _x, _size] };
} forEach (_outdoor select [0, 30]);

_candidates = _candidates select {
    _x params ["_spot"];
    _spot distance2D _ePos > 10 && {!surfaceIsWater _spot}
};
_candidates = _candidates apply { [_x select 0 distance2D _anchor, _x] };
_candidates sort true;

private _result = [];
private _tested = 0;
{
    (_x select 1) params ["_spot", "_indoor", ["_object", objNull], ["_size", 0]];
    if (!isNull _object) then {
        // Find the object's real back face: a ray from beyond it toward the enemy, knee high, hits it there.
        // The bounding sphere alone puts the spot metres off for trees and long walls.
        private _dir = _ePos getDir _object;
        private _center = getPosASL _object;
        _center set [2, getTerrainHeightASL _center + 0.6];
        private _far = _center getPos [_size + 1, _dir];
        _far set [2, _center select 2];
        private _hit = lineIntersectsSurfaces [_far, _center, _unit, objNull, true, 1, "GEOM", "FIRE"];
        _spot = if (_hit isEqualTo []) then { [] } else {
            private _back = ASLToAGL ((_hit select 0 select 0) getPos [0.7, _dir]);
            _back set [2, 0];
            _back
        };
    };
    if (_spot isEqualTo [] || {_taken findIf { _x distance2D _spot < 2 } != -1}) then { continue };
    _tested = _tested + 1;
    if (_tested > 12) exitWith {};
    private _chest = AGLToASL _spot vectorAdd [0, 0, [0.9, 1.3] select _indoor];
    if (lineIntersectsSurfaces [_eyeEnemy, _chest, _unit, objNull, true, 1, "FIRE", "GEOM"] isNotEqualTo []) exitWith {
        _result = [_spot, _indoor];
    };
} forEach _candidates;

_result
