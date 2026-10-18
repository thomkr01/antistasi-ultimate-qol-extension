# Installation

## Players and servers

1. Install [CBA_A3](https://steamcommunity.com/workshop/filedetails/?id=450814997). It is required.
2. Get `@auqol`, either from a release zip or by building it (see below).
3. Load the mods together: `-mod=@CBA_A3;@AntistasiUltimate;@auqol`, plus ACE3, RHS or CUP if you use them. Load order doesn't matter, because `auqol_main` requires `cba_main` and detects everything else at runtime.
4. Multiplayer: load `@auqol` on the server, every client and every headless client. Copy `keys/auqol_<version>.bikey` into the server's `keys` folder if you verify signatures.
5. Start Antistasi Ultimate as usual. No mission file needs editing.

## Building from source

Install [HEMTT](https://github.com/BrettMayson/HEMTT) 1.22 or newer and Python 3, then run:

```sh
tools/build.sh            # Linux / macOS
pwsh tools/build.ps1      # Windows
```

The script runs the static checks, `hemtt check`, and then `hemtt release`. The output is `releases/auqol-latest.zip`, containing `@auqol`. Use `hemtt dev` for a quick unsigned build in `.hemttout/dev`.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| No "Antistasi Ultimate QoL" entry in Addon Options | Make sure the mod is loaded. Search the RPT for `[AUQOL] Version`. If that line is missing, the addon didn't load. Check that CBA is loaded. |
| A feature seems inactive | Run `call AUQOL_fnc_diagnostics` in the debug console on the machine in question. It prints which integration handles each feature there. In MP, server-scoped settings follow the server's value. |
| Crew is not ejected | Only land vehicles with eligible crew qualify: alive, AI, hostile to the rebels, not captive or surrendered. The vehicle must report `canMove` false, or have empty fuel with the fuel option on. Turn on `auqol_debug` to see an `Ejecting N unit(s)` line in the RPT of the machine that owns the vehicle. |
| A fuel truck still runs dry under ACE | Check that `ace_refuel_enabled` is on and the truck has `ace_refuel_fuelCargo` or `transportFuel` in config. Sources disabled by the mission (capacity -1) are left alone on purpose. |
| ACE ammo truck still runs dry | The top-up only applies in ACE's "limited ammo supply based on caliber" mode. The default "unlimited" mode is already infinite, and "magazine supply" mode is not handled. |
| Player setting won't stay off or on | Client settings can be forced by the server admin in CBA's server settings. The 5-second re-check re-applies your own choice after respawn. |
| RPT warning `ACE ... not found` | Your ACE version renamed an API AUQOL uses. That feature falls back to vanilla behaviour. Please open an issue with your ACE version. |
