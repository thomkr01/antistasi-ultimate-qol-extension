/*
    Author: AUQOL
    Where an enemy is, as the radio says it, in the system chosen with auqol_front_system, always seen from the
    local player: 0 the exact compass bearing to 1 degree ("bearing 313"), 1 clock position from where you face,
    2 clock position from the formation's front (the "front" the game's own contact reports use), 3 the eight
    compass points ("north-east").

    Arguments:
    0: Enemy <OBJECT>

    Return Value: <STRING>
*/
params ["_target"];
if (!hasInterface) exitWith { "" };
private _bearing = (round (player getDir _target)) % 360;
switch (auqol_front_system) do {
    case 1: {
        private _clock = (round ((player getRelDir _target) / 30)) % 12;
        format ["%1 o'clock", [_clock, 12] select (_clock == 0)]
    };
    case 2: {
        private _clock = (round (((_bearing - formationDirection leader group player) + 360) % 360 / 30)) % 12;
        format ["%1 o'clock from front", [_clock, 12] select (_clock == 0)]
    };
    case 3: { ["north", "north-east", "east", "south-east", "south", "south-west", "west", "north-west"] select ((round (_bearing / 45)) % 8) };
    default { format ["bearing %1", [_bearing, 3] call CBA_fnc_formatNumber] };
}
