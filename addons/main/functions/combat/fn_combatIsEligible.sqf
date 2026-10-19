/*
    Author: AUQOL
    Whether smart combat tactics may move a group member right now. Leaves alone every unit that
    Antistasi Ultimate or another script has busy: not local, a player, in a vehicle or on a static,
    incapacitated (engine or Antistasi), surrendered, captive, fleeing, healing or being healed
    (Antistasi "helping"/"helped"), rearming, attached, remote controlled, with pathing or movement
    off (Antistasi garrisons and its smoke charge), stopped (Stop / Hold, garrison doStop), or with a
    command other than none, attack or fire. A move order counts only when AUQOL gave it. A unit
    treating itself or being treated by a group medic (AUQOL_fnc_squadSelfTreat, AUQOL_fnc_combatSupport)
    is left alone until that is done, so a move order or a grenade dodge does not cut the treatment short. A unit
    that failed to reach three spots in a row rests for 30 s (AUQOL_fnc_combatTick).

    Arguments:
    0: Unit <OBJECT>

    Return Value: Eligible <BOOL>
*/

params ["_unit"];

alive _unit && {local _unit} && {!isPlayer _unit} && {isNull objectParent _unit}
    && {lifeState _unit in ["HEALTHY", "INJURED"]} && {!captive _unit} && {!fleeing _unit}
    && {!(_unit getVariable ["incapacitated", false])} && {!(_unit getVariable ["surrendered", false])}
    && {!(_unit getVariable ["helping", false])} && {isNull (_unit getVariable ["helped", objNull])} && {!(_unit getVariable ["rearming", false])}
    && {isNull attachedTo _unit} && {isNull remoteControlled _unit}
    && {_unit checkAIFeature "MOVE"} && {_unit checkAIFeature "PATH"} && {!stopped _unit}
    && {time >= _unit getVariable ["auqol_tacRestUntil", 0]} && {time >= _unit getVariable ["auqol_treatUntil", 0]}
    && {currentCommand _unit in ["", "ATTACK", "ATTACKFIRE", "FIRE"] || {currentCommand _unit == "MOVE" && {!isNil {_unit getVariable "auqol_tacDest"}}}}
