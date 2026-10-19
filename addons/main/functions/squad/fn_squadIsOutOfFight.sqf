/*
    Author: AUQOL
    Whether an enemy is out of the fight, so it is not worth another launcher round or the squad's
    focus: dead, or a vehicle with no living crew, an aircraft that cannot fly (going down), or a
    ground vehicle that can neither move nor fire. An immobilized vehicle whose gun still works is
    still in the fight. Used by the launcher switch (AUQOL_fnc_squadLaunchers), the T key focus
    (AUQOL_fnc_squadRevealFocus) and smart combat's armor reaction (AUQOL_fnc_combatTick).

    Arguments:
    0: Target <OBJECT>

    Return Value: Out of the fight <BOOL>
*/

params ["_target"];

!alive _target || {!(_target isKindOf "Man") && {
    (crew _target) findIf { alive _x } == -1
    || {!canMove _target && {_target isKindOf "Air" || {!canFire _target}}}
}}
