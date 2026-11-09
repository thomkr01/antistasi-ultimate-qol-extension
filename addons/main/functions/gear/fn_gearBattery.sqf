/*
    Author: AUQOL
    Built-in battery: anything in the binoculars slot that takes a magazine (laser designators from vanilla,
    RHS, CUP or any mod) gets the first magazine it accepts loaded at once, so nobody has to find a battery.
    The magazine comes from the item's own config (compatibleMagazines, kept per class in
    auqol_gear_batteryCache), so no list of mods or items is needed. Plain binoculars, rangefinders and the
    ACE Vector take no magazine and are left alone. Arma has batteries only in this slot; night vision and
    other items need none. Called for the player on every loadout change, and for AI where they are local:
    5 s after they spawn (after Antistasi gave them their gear), when they change owner and when they join
    your group. addBinocularItem needs a local unit.

    Arguments:
    0: Unit <OBJECT>

    Return Value: none
*/

params ["_unit"];
if (!auqol_ready || {!auqol_gear_builtInBattery} || {!local _unit} || {!alive _unit}) exitWith {};
private _item = binocular _unit;
if (_item isEqualTo "" || {binocularMagazine _unit isNotEqualTo []}) exitWith {};
private _battery = auqol_gear_batteryCache getOrDefaultCall [_item, { compatibleMagazines _item param [0, ""] }, true];
if (_battery isEqualTo "") exitWith {};
_unit addBinocularItem _battery;
[format ["Built-in battery: %1 loaded into the %2 of %3", _battery, _item, name _unit], true] call AUQOL_fnc_log;
