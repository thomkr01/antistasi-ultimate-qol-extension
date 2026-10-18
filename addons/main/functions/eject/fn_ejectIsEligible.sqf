/*
    Author: AUQOL
    Returns whether an occupant may be ejected: a living, hostile, non-player AI that is not a captive,
    prisoner or surrendered unit (vanilla captive, Antistasi "surrendered", ACE captives), and not
    opted out with the auqol_noEject variable.

    Arguments:
    0: Unit <OBJECT>

    Return Value: <BOOL>
*/

params ["_unit"];

alive _unit
&& {!isPlayer _unit}
&& {!captive _unit}
&& {!(_unit getVariable ["surrendered", false])}
&& {!(_unit getVariable ["ace_captives_isHandcuffed", false])}
&& {!(_unit getVariable ["ace_captives_isSurrendering", false])}
&& {!(_unit getVariable ["auqol_noEject", false])}
&& {[side group _unit] call AUQOL_fnc_isHostileSide}
