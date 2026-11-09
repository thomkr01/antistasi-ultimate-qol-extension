/*
    Author: AUQOL
    Radio net: whether a group can use the radio and whether it reaches twice as far.
    - Radio required (auqol_radio_requireRadio on): the group has a radio when a living member has one in the
      radio slot (AUQOL_fnc_radioItem). It reaches twice as far when a living member carries a radio backpack:
      a vanilla B_RadioBag_01_* or any backpack with tf_hasLRradio = 1 (TFAR long range radios).
    - Not required: every group has a radio and always reaches twice as far.
    The answer is kept on the group for 30 s (auqol_radioGear, this machine only), so a radio man who dies
    counts within 30 s and the gear of a group is read at most twice a minute.

    Arguments:
    0: Group <GROUP>

    Return Value: [has radio <BOOL>, twice the range <BOOL>]
*/

params ["_group"];
if (!auqol_radio_requireRadio) exitWith { [true, true] };
private _cache = _group getVariable ["auqol_radioGear", [-1e9, false, false]];
if (time < (_cache select 0) + 30) exitWith { [_cache select 1, _cache select 2] };

private _units = units _group select { alive _x };
private _radio = _units findIf { [_x] call AUQOL_fnc_radioItem } != -1;
private _bag = _units findIf {
    private _class = backpack _x;
    _class isNotEqualTo "" && {auqol_radio_bagCache getOrDefaultCall [_class, {
        (toLower _class) find "b_radiobag_01_" == 0 || {getNumber (configFile >> "CfgVehicles" >> _class >> "tf_hasLRradio") == 1}
    }, true]}
} != -1;
_group setVariable ["auqol_radioGear", [time, _radio, _bag]];
[_radio, _bag]
