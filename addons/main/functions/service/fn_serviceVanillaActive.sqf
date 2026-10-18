/*
    Author: AUQOL
    Returns whether AUQOL should keep the vanilla cargo of a service type full. ACE's refuel, rearm and
    repair components zero the vanilla cargo on purpose when enabled, so vanilla refills stay off then.

    Arguments:
    0: Service kind, "fuel", "ammo" or "repair" <STRING>

    Return Value: <BOOL>
*/

params ["_kind"];

switch (_kind) do {
    case "fuel": { auqol_service_fuel && {!(missionNamespace getVariable ["ace_refuel_enabled", false])} };
    case "ammo": { auqol_service_ammo && {!(missionNamespace getVariable ["ace_rearm_enabled", false])} };
    case "repair": { auqol_service_repair && {!(missionNamespace getVariable ["ace_repair_enabled", false])} };
    default { false };
}
