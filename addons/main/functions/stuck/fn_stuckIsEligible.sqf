/*
    Author: AUQOL
    Whether a local AI unit may be watched for being stuck, and with _moving, whether it may be moved
    (short hop or teleport) right now. AUQOL_fnc_stuckEvaluate calls it on every check and
    AUQOL_fnc_stuckRecover calls it again with _moving immediately before it moves a unit.

    A unit is only watched while it has somewhere to go and nothing else to do:
    - alive, AI, local, not incapacitated (Antistasi "incapacitated"), surrendered or captive, healing
      someone (Antistasi "helping"), rearming from bodies (Antistasi "rearming"), attached to an object,
      remote controlled (Zeus), or playing an action or scripted animation (inventory, healing and
      "Acts_" animations, which missions use for hostages and cutscenes);
    - movement and pathfinding AI enabled, not stopped (Stop / Hold, garrison doStop), and no command
      other than a move (currentCommand "" or "MOVE": attack, heal, get in, rearm and so on are left alone);
    - a destination from expectedDestination other than "DoNotPlan" (not moving) or "LEADER DIRECT"
      (get in, supply);
    - on foot: on the ground, not swimming, not on a ladder. In a vehicle: the AI driver of a land
      vehicle that can move, with no player on board. Passengers and static weapons are skipped;
    - not being moved by smart combat AI (a cover spot or a grenade dodge, AUQOL_fnc_combatTick and
      AUQOL_fnc_combatDodge), which handles its own movers that get stuck;
    - not fighting: no attack target, not suppressed, no known enemy within 300 m;
    - for AI-led groups (patrols, garrisons, HC squads): not on a HOLD, GUARD, SENTRY, LOITER, DISMISS
      or SCRIPTED waypoint and not on a CYCLE patrol route.
    With _moving, the unit must also not be in COMBAT behaviour.

    Arguments:
    0: Unit <OBJECT>
    1: About to move the unit <BOOL> (default: false)

    Return Value: Eligible <BOOL>
*/

params ["_unit", ["_moving", false]];

private _veh = vehicle _unit;
private _group = group _unit;
(expectedDestination _unit) params [["_dest", []], ["_mode", "DoNotPlan"]];
private _anim = toLower animationState _unit;

alive _unit && {local _unit} && {!isPlayer _unit} && {!captive _unit}
    && {!(_unit getVariable ["incapacitated", false])} && {!(_unit getVariable ["surrendered", false])}
    && {!(_unit getVariable ["helping", false])} && {!(_unit getVariable ["rearming", false])}
    && {lifeState _unit in ["HEALTHY", "INJURED"]}
    && {isNull attachedTo _unit} && {isNull remoteControlled _unit}
    && {!("ainv" in _anim)} && {!("medic" in _anim)} && {_anim select [0, 5] != "acts_"}
    && {isNil {_unit getVariable "auqol_tacDest"}} && {isNil {_unit getVariable "auqol_tacDodge"}}
    && {_unit checkAIFeature "MOVE"} && {_unit checkAIFeature "PATH"}
    && {!stopped _unit} && {currentCommand _unit in ["", "MOVE"]}
    && {!(_mode in ["DoNotPlan", "LEADER DIRECT"])} && {_dest isNotEqualTo []}
    && {if (_veh isEqualTo _unit) then {
            isTouchingGround _unit && {!surfaceIsWater getPosASL _unit} && {!("ladder" in _anim)}
        } else {
            driver _veh isEqualTo _unit && {_veh isKindOf "LandVehicle"} && {!(_veh isKindOf "StaticWeapon")}
            && {canMove _veh} && {fuel _veh > 0} && {(crew _veh) findIf { isPlayer _x } == -1}
        }}
    && {isNull getAttackTarget _unit} && {getSuppression _unit == 0} && {_unit distance (_unit findNearestEnemy _unit) > 300}
    && {!_moving || {behaviour _unit != "COMBAT"}}
    && {isPlayer leader _group || {
            waypoints _group findIf { waypointType _x == "CYCLE" } == -1
            && {!(waypointType [_group, currentWaypoint _group] in ["HOLD", "GUARD", "SENTRY", "LOITER", "DISMISS", "SCRIPTED"])}
        }}
