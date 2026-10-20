/*
    Author: AUQOL
    How well a unit's uniform blends in, as a multiplier (lower is better): the camouflage value of the
    soldier class the uniform belongs to (CfgVehicles camouflage, the value the engine itself uses for
    spotting), capped to 0.5 to 1, so camouflage patterns and ghillie suits from any mod count without
    a list. A uniform with "ghillie" in its class name gets at most 0.6 even if its mod left the value
    at the default. Each uniform is looked up once.

    Arguments:
    0: Unit <OBJECT>

    Return Value: <NUMBER>
*/

params ["_unit"];

private _uniform = uniform _unit;
private _camo = auqol_conceal_camoCache get _uniform;
if (isNil "_camo") then {
    private _class = getText (configFile >> "CfgWeapons" >> _uniform >> "ItemInfo" >> "uniformClass");
    private _cfg = configFile >> "CfgVehicles" >> _class >> "camouflage";
    _camo = [1, (getNumber _cfg) max 0.5 min 1] select isNumber _cfg;
    private _name = toLowerANSI _uniform;
    if ("ghillie" in _name || {"ghilie" in _name}) then { _camo = _camo min 0.6 };
    auqol_conceal_camoCache set [_uniform, _camo];
};
_camo
