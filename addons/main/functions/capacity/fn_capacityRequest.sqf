/*
    Author: AUQOL
    Client side of the carrying-capacity feature. setMaxLoad has to run on the server, so whenever the
    player's uniform, vest or backpack container objects change, the server is asked to re-apply the
    multiplier, and to restore containers the player no longer wears (a dropped backpack must not
    keep the boosted capacity for whoever picks it up). Loadout events fire on every inventory change;
    the container comparison keeps this to one request per actual container change.

    Arguments:
    0: Force a request even if nothing changed <BOOL> (default: false)

    Return Value: none
*/

params [["_force", false, [false]]];

if (!hasInterface || {!auqol_ready}) exitWith {};
private _unit = player;
if (isNull _unit) exitWith {};

private _containers = [uniformContainer _unit, vestContainer _unit, backpackContainer _unit];
private _previous = missionNamespace getVariable ["auqol_capacity_worn", []];
if (!_force && _containers isEqualTo _previous) exitWith {};
auqol_capacity_worn = _containers;

["auqol_capacity_apply", [_unit, (_previous - _containers) select { !isNull _x }]] call CBA_fnc_serverEvent;
