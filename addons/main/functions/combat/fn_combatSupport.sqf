/*
    Author: AUQOL
    Support inside an AI group in contact, run from its smart combat pass at most every 10 s:
    - auqol_combat_resupply: a member with fewer than two magazines left for its primary weapon gets
      one from a group mate within 15 m who carries at least four that fit (compatibleMagazines, so
      any weapon and mod). Antistasi's own rearming from bodies is left as it is.
    - auqol_squad_selfTreat: wounded members treat themselves with their own first aid kit
      (AUQOL_fnc_squadSelfTreat, the same rules as for your squad).
    - auqol_combat_medics: while no enemy is within 60 m, a medic of the group (medic trait) treats
      the most hurt mate within 30 m that is wounded but not down (damage over 0.3), with the vanilla
      HealSoldier action. Downed units are left to Antistasi's revive, units already being helped are
      skipped, and the whole step is off under ACE medical, whose own AI medical handles it.

    Arguments:
    0: Group <GROUP>
    1: Eligible members <ARRAY>
    2: Distance from the leader to the nearest known enemy <NUMBER>

    Return Value: none
*/

params ["_group", "_members", "_distEnemy"];
if (time < _group getVariable ["auqol_tacNextSupport", 0]) exitWith {};
_group setVariable ["auqol_tacNextSupport", time + 10];

if (auqol_combat_resupply) then {
    {
        private _unit = _x;
        private _weapon = primaryWeapon _unit;
        if (_weapon == "") then { continue };
        private _fits = (compatibleMagazines _weapon) apply { toLowerANSI _x };
        private _own = magazines _unit select { toLowerANSI _x in _fits };
        if (count _own >= 2) then { continue };
        {
            private _spare = magazines _x select { toLowerANSI _x in _fits };
            if (count _spare >= 4 && {local _x} && {_x distance _unit < 15}) exitWith {
                private _mag = _spare select 0;
                _x removeMagazine _mag;
                _unit addMagazine _mag;
            };
        } forEach (_members - [_unit]);
    } forEach _members;
};

{ [_x] call AUQOL_fnc_squadSelfTreat } forEach (_members select { damage _x > 0 });

if (auqol_combat_medics && _distEnemy > 60 && {!isClass (configFile >> "CfgPatches" >> "ace_medical_engine")}) then {
    {
        private _medic = _x;
        if (!(_medic getUnitTrait "Medic") || {time < _medic getVariable ["auqol_tacNextHeal", 0]}) then { continue };
        private _patients = (units _group select {
            _x isNotEqualTo _medic && {alive _x} && {damage _x > 0.3} && {lifeState _x in ["HEALTHY", "INJURED"]}
            && {!(_x getVariable ["incapacitated", false])} && {isNull (_x getVariable ["helped", objNull])}
            && {time >= _x getVariable ["auqol_treatUntil", 0]} && {_x distance _medic < 30}
        }) apply { [damage _x, _x] };
        if (_patients isEqualTo []) then { continue };
        _patients sort false;
        _medic setVariable ["auqol_tacNextHeal", time + 20];
        _medic setVariable ["auqol_tacDest", nil];
        private _patient = _patients select 0 select 1;
        // Keeps self-treat from starting on the same patient while the medic works.
        _patient setVariable ["auqol_treatUntil", time + 10];
        _medic action ["HealSoldier", _patient];
    } forEach _members;
};
