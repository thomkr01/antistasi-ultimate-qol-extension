/*
    Author: AUQOL
    Night spotting: enemy AI without night vision (AUQOL_fnc_nightHasVision) spot worse in the dark.
    Their spotDistance and spotTime skills are scaled down by how dark it is, down to
    auqol_night_strength percent on a moonless, overcast night. Darkness comes from the sun and moon
    height, the moon phase and the cloud cover, not the clock. Everything else (accuracy, courage,
    hearing gunfire, contacts reported by other units) is left alone, so a firefight works as before.
    With auqol_night_noise (off by default), noise and movement still give a target away: a soldier with an enemy close enough gets his normal
    skills back until it is gone. How close depends on how much noise the enemy makes, as a multiple of
    auqol_night_closeRange (an enemy walking upright): prone 0.4, crouched 0.7, walking 1, running
    (over 9 km/h) 2, sprinting (over 17 km/h) 3, a vehicle with its engine on 4. The noisier of stance
    and speed counts, so a crouched run is a run. With auqol_night_lights, a lit target is seen from 6: its own weapon light or
    headlights on, a burning street lamp within 15 m, or a flare in the air or on the ground within 120 m.

    Runs on every machine for its own AI. The original values are a public unit variable
    [spotDistance, spotTime, both values read back after the write, factor], so they survive a change
    of owner. When someone else changes the skills (Antistasi, another mod), their value becomes the
    new baseline, and on restore their value is kept.

    Arguments:
    0: Units to check <ARRAY> (optional, default: this second's fifth of the units on this machine)

    Return Value: none
*/

if (!auqol_ready) exitWith {};

params [["_units", nil, [[]]]];
private _full = isNil "_units";
if (_full) then {
    // Each unit gets a fixed fifth on first sight; a pass runs every second, so each unit is checked every 5 s.
    auqol_night_slice = (auqol_night_slice + 1) % 5;
    _units = allUnits select {
        private _slot = _x getVariable "auqol_nightSlot";
        if (isNil "_slot") then { _slot = floor random 5; _x setVariable ["auqol_nightSlot", _slot] };
        _slot == auqol_night_slice
    };
};

// A clear full moon takes 60 % of the darkness away; clouds hide the moon.
private _dark = (1 - sunOrMoon) * (1 - 0.6 * moonIntensity * (1 - overcast));
private _factor = [1, 1 - _dark * (1 - auqol_night_strength / 100)] select auqol_night_enabled;
_factor = (round (_factor * 20)) / 20; // steps of 0.05, so slow light changes don't rewrite every pass
private _range = auqol_night_closeRange;
private _reach = _range * (([0, 4] select auqol_night_noise) max ([0, 6] select auqol_night_lights)); // farthest a target can give itself away
private _pass = diag_tickTime; // a target's light is worked out once per pass, kept on the target
private _isLit = {
    private _known = _this getVariable ["auqol_nightLit", [-1, false]];
    if ((_known select 0) == _pass) exitWith { _known select 1 };
    private _lit = [isLightOn _this, _this isFlashlightOn currentWeapon _this] select (_this isKindOf "CAManBase");
    _lit = _lit
        || {(nearestObjects [_this, ["Lamps_base_F"], 15]) findIf { alive _x && {lightIsOn _x != "OFF"} } != -1}
        || {(_this nearObjects ["FlareCore", 120]) isNotEqualTo []}; // FlareCore: every hand, grenade-launcher and mortar flare
    _this setVariable ["auqol_nightLit", [_pass, _lit]];
    _lit
};
// Enemies of a side that could give themselves away (crew left out, as nearEntities does). A full pass
// lists every entity once (when the first soldier needs it) and splits it per side, so each soldier
// only filters that short list; a check of a single unit (spawn, change of owner) asks nearEntities.
private _hostileOf = createHashMap;
private _enemiesOf = createHashMap;
private ["_entities"];
private _nearbyEnemies = if (_full) then {
    { (_enemiesOf getOrDefaultCall [_side, {
        if (isNil "_entities") then { _entities = entities [["CAManBase", "LandVehicle", "Air", "Ship"], [], false, true] };
        _entities select { (_side getFriend side _x) < 0.6 }
    }, true]) inAreaArray [getPosATL _unit, _reach, _reach] }
} else {
    { (_unit nearEntities [["CAManBase", "LandVehicle", "Air", "Ship"], _reach]) select { (_side getFriend side _x) < 0.6 } }
};

{
    private _unit = _x;
    private _saved = _unit getVariable "auqol_nightSkills";
    private _now = [_unit skill "spotDistance", _unit skill "spotTime"];
    // Our last write is no longer there: someone else set the skills, and their value is the baseline.
    private _changed = !isNil "_saved" && {abs ((_now select 0) - (_saved select 2)) > 0.01 || {abs ((_now select 1) - (_saved select 3)) > 0.01}};

    private _side = side group _unit;
    if (_factor < 1 && {_hostileOf getOrDefaultCall [_side, { [_side] call AUQOL_fnc_isHostileSide }, true]} && {!([_unit] call AUQOL_fnc_nightHasVision)}
        && {_reach == 0 || {(call _nearbyEnemies) findIf {
            alive _x && {
                private _noise = [1, 4] select isEngineOn _x;
                if (auqol_night_noise) then {
                    if (_x isKindOf "CAManBase") then {
                        private _speed = abs speed _x;
                        _noise = switch (stance _x) do { case "PRONE": {0.4}; case "CROUCH": {0.7}; default {1} };
                        if (_speed > 17) then { _noise = 3 } else { if (_speed > 9) then { _noise = 2 } };
                    };
                } else { _noise = 0 };
                private _d = _unit distance _x;
                _d < _range * _noise || {auqol_night_lights && {_d < _range * 6} && {_x call _isLit}}
            }
        } == -1}}) then {
        private _base = if (isNil "_saved" || _changed) then { _now } else { _saved select [0, 2] };
        private _want = _base apply { _x * _factor };
        if (isNil "_saved" || _changed || {(_saved select 4) != _factor}) then {
            _unit setSkill ["spotDistance", _want select 0];
            _unit setSkill ["spotTime", _want select 1];
            _unit setVariable ["auqol_nightSkills", _base + [_unit skill "spotDistance", _unit skill "spotTime", _factor]];
        };
    } else {
        if (isNil "_saved") exitWith {};
        if (!_changed) then {
            _unit setSkill ["spotDistance", _saved select 0];
            _unit setSkill ["spotTime", _saved select 1];
        };
        _unit setVariable ["auqol_nightSkills", nil];
    };
} forEach (_units select {
    local _x && {!isPlayer _x} && {alive _x} && {_factor < 1 || {!isNil {_x getVariable "auqol_nightSkills"}}}
});
