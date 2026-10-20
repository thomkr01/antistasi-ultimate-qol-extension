/*
    Author: AUQOL
    How visible a unit is right now, as a multiplier for its camouflageCoef (AUQOL_fnc_concealTick).

    Hidden (0.01): the Hide Among The Grass rules, written anew:
    - on foot, on the ground (below 2 m, unless under a roof), not on a road, not on cooldown;
    - prone, crouched at no more than auqol_conceal_crouchSpeed (with auqol_conceal_crouch), or standing
      only under a roof;
    - with auqol_conceal_surfaces: on ground with grass or field clutter, next to a bush or under a roof;
    - no living enemy within the detection distance: auqol_conceal_distance prone, twice that crouched,
      four times standing, halved for each of night, rain, fog, being under a roof and a ghillie suit
      (at least 5 m).

    Otherwise, with auqol_conceal_partial, harder to see but not invisible: prone 0.5, crouched 0.75,
    times 0.7 in grass, field clutter or next to a bush (not while running), times 0.6 in a ghillie
    suit. 1 on cooldown (just hit, shot near or fired too much), on a road or in a vehicle.

    Arguments:
    0: Unit <OBJECT>

    Return Value: <NUMBER>
*/

params ["_unit"];

if (!alive _unit || {!isNull objectParent _unit} || {time < _unit getVariable ["auqol_concealUntil", 0]} || {isOnRoad _unit}) exitWith { 1 };

// Under a roof: a building straight above the eyes.
private _eye = eyePos _unit;
private _roofed = (lineIntersectsWith [_eye, _eye vectorAdd [0, 0, 25], _unit, objNull, true]) findIf { _x isKindOf "Building" } != -1;
private _stance = stance _unit;
private _speed = abs speed _unit;

private _surface = (surfaceType getPosASL _unit) select [1];
private _clutter = auqol_conceal_surfaceCache get _surface;
if (isNil "_clutter") then {
    // A surface with ground clutter (grass, field, forest floor) has a clutter "character" in config.
    _clutter = !((toLowerANSI getText (configFile >> "CfgSurfaces" >> _surface >> "character")) in ["", "empty"]);
    auqol_conceal_surfaceCache set [_surface, _clutter];
};
private _vegetation = _clutter || {nearestTerrainObjects [_unit, ["BUSH"], 3, false, true] isNotEqualTo []};

private _uniform = uniform _unit;
private _ghillie = auqol_conceal_ghillieCache get _uniform;
if (isNil "_ghillie") then {
    private _name = toLowerANSI _uniform;
    _ghillie = "ghillie" in _name || {"ghilie" in _name};
    auqol_conceal_ghillieCache set [_uniform, _ghillie];
};

private _canHide = ((getPosATL _unit select 2) < 2 || _roofed) && {switch (_stance) do {
    case "PRONE": { true };
    case "CROUCH": { auqol_conceal_crouch && _speed <= auqol_conceal_crouchSpeed };
    case "STAND": { _roofed };
    default { false };
}} && {!auqol_conceal_surfaces || _roofed || _vegetation};

if (_canHide) then {
    private _distance = auqol_conceal_distance * (switch (_stance) do { case "PRONE": {1}; case "CROUCH": {2}; default {4} });
    { if (_x) then { _distance = _distance / 2 } } forEach [sunOrMoon <= 0.8, rain >= 0.3, fog >= 0.3, _roofed, _ghillie];
    _distance = _distance max 5;
    private _side = side group _unit;
    _canHide = (_unit nearEntities ["CAManBase", _distance]) findIf {
        alive _x && _x != _unit && {(_side getFriend side group _x) < 0.6} && {lifeState _x != "INCAPACITATED"}
    } == -1;
};
if (_canHide) exitWith { 0.01 };
if (!auqol_conceal_partial) exitWith { 1 };

private _factor = switch (_stance) do { case "PRONE": {0.5}; case "CROUCH": {0.75}; default {1} };
if (_vegetation && _speed <= 9) then { _factor = _factor * 0.7 };
if (_ghillie) then { _factor = _factor * 0.6 };
_factor
