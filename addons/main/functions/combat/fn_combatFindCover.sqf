/*
    Author: AUQOL
    Finds a covered spot for a unit near an anchor point: a position where something solid (terrain,
    a wall, a rock, a tree, a building) is between the enemy and the unit's chest when crouching.
    Candidates are building positions (indoor) and the spot just behind each nearby terrain object,
    wall or fortification as seen from the enemy (outdoor). The closest covered candidates to the
    anchor are tested first, at most 12 per call, one lineIntersectsSurfaces each. Any faction, map or
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
    private _size = (boundingBoxReal _x select 2) / 2;
    if (_size > 0.4 && _size < 25) then {
        // Just behind the object, on the side away from the enemy.
        private _spot = (getPosATL _x) getPos [(_size min 4) + 0.8, _ePos getDir _x];
        _spot set [2, 0];
        _candidates pushBack [_spot, false];
    };
} forEach (_outdoor select [0, 30]);

_candidates = _candidates select {
    _x params ["_spot"];
    _spot distance2D _ePos > 10 && {!surfaceIsWater _spot}
    && {_taken findIf { _x distance _spot < 2 } == -1}
};
_candidates = _candidates apply { [_x select 0 distance2D _anchor, _x] };
_candidates sort true;

private _result = [];
{
    (_x select 1) params ["_spot", "_indoor"];
    private _chest = AGLToASL _spot vectorAdd [0, 0, [0.9, 1.3] select _indoor];
    if (lineIntersectsSurfaces [_eyeEnemy, _chest, _unit, objNull, true, 1, "FIRE", "GEOM"] isNotEqualTo []) exitWith {
        _result = [_spot, _indoor];
    };
} forEach (_candidates select [0, 12]);

_result
