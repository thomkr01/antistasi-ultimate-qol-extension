/*
    Author: AUQOL
    Whether a unit has a radio in its radio slot: an assigned item whose CfgWeapons simulation is "ItemRadio".
    That covers vanilla, Antistasi ("RADIO" gear gives ItemRadio), RHS, CUP and TFAR personal radios. The
    answer per item class is kept in auqol_radio_itemCache. Works on remote units.

    Arguments:
    0: Unit <OBJECT>

    Return Value: <BOOL>
*/

params ["_unit"];
(assignedItems _unit) findIf {
    private _item = _x;
    auqol_radio_itemCache getOrDefaultCall [_item, { getText (configFile >> "CfgWeapons" >> _item >> "simulation") == "ItemRadio" }, true]
} != -1
