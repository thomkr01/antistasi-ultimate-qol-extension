/*
    Author: AUQOL
    Fast dismount. Vehicle GetOut handler, added on every machine (each handles the units local to it).
    When an AI gets out of a stopped vehicle, every other AI of its group still inside that was also told
    to leave (a get-out order, or no vehicle assignment any more) is moved out at once with moveOut. The
    vanilla "GetOut" action and the get-out order are queued by the engine, one unit after another, so
    only moveOut is instant; the units skip the get-out animation. Crew who stay (a driver or gunner still
    assigned and not ordered out), players, captives and unconscious units are left alone. Nothing happens
    while the vehicle moves faster than 5 km/h or an aircraft is off the ground, so paradrops and Eject
    stay as they are. Orders, waypoints and assignments are never changed.

    Arguments:
    0: Vehicle <OBJECT>
    2: Unit that got out <OBJECT>

    Return Value: none
*/

params ["_vehicle", "", "_unit"];

if (!auqol_ready || {!auqol_anim_fastDismount} || {!alive _vehicle} || {isPlayer _unit} || {!local _unit}) exitWith {};
if (abs speed _vehicle > 5 || {_vehicle isKindOf "Air" && {!isTouchingGround _vehicle}}) exitWith {};

private _group = group _unit;
// Each forced exit fires this handler again; the time mark keeps a unit from being sent twice.
private _out = crew _vehicle select {
    local _x && {!isPlayer _x} && {alive _x} && {group _x isEqualTo _group} && {currentCommand _x == "GET OUT" || {isNull assignedVehicle _x}}
    && {!captive _x} && {lifeState _x != "INCAPACITATED"} && {!(_x getVariable ["incapacitated", false])} && {time > (_x getVariable ["auqol_fastOut", -10]) + 5}
};
{
    _x setVariable ["auqol_fastOut", time];
    moveOut _x;
} forEach _out;
if (_out isNotEqualTo []) then { [format ["Fast dismount: %1 units out of %2", count _out, typeOf _vehicle]] call AUQOL_fnc_log };
