/*
    Author: AUQOL
    Lets the engine stop simulating parked empty vehicles and settled wrecks while no player is near
    (server, every 30 s). It uses Arma's own dynamic simulation: AUQOL only marks which vehicles may
    sleep, and the engine wakes each one as soon as a player comes within 500 m, so nobody sees a
    vehicle freeze or wake. Enemy and friendly AI keep their normal simulation.

    A vehicle is marked when it has no living crew, is not moving, rests on the ground or water, and
    is not attached, towed or carrying a rope. Anything that already has simulation turned off, or is
    hidden, is never marked: that is ACE cargo, Antistasi logistics or another mod managing it. A
    marked vehicle that gets living crew, moves, or is picked up is unmarked on the next pass. Turning
    a setting off unmarks everything AUQOL marked.

    The engine's dynamic simulation is switched on only if it is off, and then the empty-vehicle
    wake distance is set to 500 m. A mission or mod that already runs it keeps its own distances.

    Arguments: none
    Return Value: none
*/

if (!isServer || {!auqol_ready}) exitWith {};

private _parked = auqol_freeze_parked;
private _wrecks = auqol_freeze_wrecks;

if (!_parked && !_wrecks) exitWith {
    { if (!isNull _x) then { _x enableDynamicSimulation false } } forEach auqol_freeze_marked;
    auqol_freeze_marked = [];
    if (auqol_freeze_ownsSystem) then { enableDynamicSimulationSystem false; auqol_freeze_ownsSystem = false };
};

if (!dynamicSimulationSystemEnabled) then {
    enableDynamicSimulationSystem true;
    "EmptyVehicle" setDynamicSimulationDistance 500;
    auqol_freeze_ownsSystem = true;
};

private _canSleep = {
    params ["_veh"];
    ([_parked, _wrecks] select !alive _veh)
    && {(crew _veh) findIf { alive _x } == -1}
    && {speed _veh < 1}
    && {(getPos _veh select 2) < 1}
    && {isNull attachedTo _veh}
    && {isNull ropeAttachedTo _veh}
    && {(ropes _veh) isEqualTo []}
};

private _marked = [];
{
    if (isNull _x) then { continue };
    if ([_x] call _canSleep) then { _marked pushBack _x } else { _x enableDynamicSimulation false };
} forEach auqol_freeze_marked;

{
    if (!(_x in _marked) && {simulationEnabled _x} && {!isObjectHidden _x} && {[_x] call _canSleep}) then {
        _x enableDynamicSimulation true;
        _marked pushBack _x;
    };
} forEach (vehicles select { !(_x isKindOf "StaticWeapon") && {_x isKindOf "LandVehicle" || {_x isKindOf "Air"} || {_x isKindOf "Ship"}} });

auqol_freeze_marked = _marked;
