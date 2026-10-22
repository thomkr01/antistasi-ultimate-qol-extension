/*
    Author: AUQOL
    Fast dismount. Vehicle GetOut handler, added on every machine (each handles the units local to it).
    When an AI that was told to leave (no vehicle assignment any more) gets out, every other AI of its
    group still in that vehicle and also told to leave gets the vanilla "GetOut" action at once, so the
    group climbs out together, the way it boards, instead of one after another. Crew that are still
    assigned (a driver or gunner who stays), players, captives and unconscious units are left alone.
    Nothing happens while the vehicle moves faster than 5 km/h or an aircraft is off the ground, so
    paradrops and Eject stay as they are. Orders, waypoints and assignments are never changed.

    Arguments:
    0: Vehicle <OBJECT>
    2: Unit that got out <OBJECT>

    Return Value: none
*/

params ["_vehicle", "", "_unit"];

if (!auqol_ready || {!auqol_anim_fastDismount} || {!alive _vehicle} || {isPlayer _unit} || {!local _unit}) exitWith {};
if (!isNull assignedVehicle _unit || {abs speed _vehicle > 5} || {_vehicle isKindOf "Air" && {!isTouchingGround _vehicle}}) exitWith {};

private _group = group _unit;
// Each forced exit fires this handler again; the time mark keeps a unit from being sent twice.
private _out = crew _vehicle select {
    local _x && {!isPlayer _x} && {alive _x} && {group _x isEqualTo _group} && {isNull assignedVehicle _x}
    && {!captive _x} && {lifeState _x != "INCAPACITATED"} && {time > (_x getVariable ["auqol_fastOut", -10]) + 5}
};
{
    _x setVariable ["auqol_fastOut", time];
    _x action ["GetOut", _vehicle];
} forEach _out;
if (_out isNotEqualTo []) then { [format ["Fast dismount: %1 units out of %2", count _out, typeOf _vehicle]] call AUQOL_fnc_log };
