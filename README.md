# Antistasi Ultimate QoL Extension (AUQOL)

A standalone Arma 3 addon that adds quality-of-life features to Antistasi Ultimate without editing any mission file. It needs CBA_A3. ACE3, RHS and CUP are optional, and the mod detects them at runtime.

| Feature | What it does |
| --- | --- |
| Enemy crew ejection | When an enemy AI land vehicle can no longer move, its living enemy AI occupants are moved out and their group stops using the vehicle. |
| Infinite service stock | Recognized fuel, ammo and repair sources never run out of what they hand out. Services that are already unlimited are left alone. |
| No weapon sway | Removes weapon sway for your own character. |
| Unlimited stamina | Your own character never tires. AI is unchanged. |
| Weight-independent running | Carried weight no longer drains or reserves your stamina. |
| Carrying capacity | Multiplies your uniform, vest and backpack capacity, 1000x by default. |

Each feature has its own CBA setting and can be switched on or off while the mission is running.

## Requirements

- Arma 3 2.12 or newer (stable branch). The vanilla `Service` event handler the service feature uses was added in 2.12.
- [CBA_A3](https://github.com/CBATeam/CBA_A3), as a hard dependency (`requiredAddons[] = {"cba_main"}`).
- Antistasi Ultimate is the target mission, but it isn't required to load the addon.

## Installation

1. Build the mod (see [Building](#building)) or take a release zip, and extract `@auqol`.
2. Load it alongside CBA_A3 and Antistasi Ultimate, for example `-mod=@CBA_A3;@AntistasiUltimate;@auqol`.
3. In multiplayer, run it on the server and on every client. Settings that change world state are forced by the server.

More detail is in [docs/installation.md](docs/installation.md).

## CBA settings

Open **Options → Addon Options → Antistasi Ultimate QoL**. "Server" settings are synchronized from the server to everyone (`isGlobal = 1`). "Client" settings belong to each player unless the server forces them.

| Setting | Type | Default | Scope | Purpose |
| --- | --- | --- | --- | --- |
| `auqol_eject_enabled` | Checkbox | On | Server | Eject enemy crew from immobilized vehicles. |
| `auqol_eject_outOfFuel` | Checkbox | On | Server | Count an empty fuel tank as immobilized too. |
| `auqol_service_fuel` | Checkbox | On | Server | Infinite fuel-service stock. |
| `auqol_service_ammo` | Checkbox | On | Server | Infinite ammunition-service stock. |
| `auqol_service_repair` | Checkbox | On | Server | Infinite repair-service stock. |
| `auqol_service_garageFuel` | Checkbox | On | Server | Keep Antistasi garage fuel sources full. Also needs the fuel setting on. |
| `auqol_player_noSway` | Checkbox | On | Client | No weapon sway. |
| `auqol_player_unlimitedStamina` | Checkbox | On | Client | Unlimited stamina. |
| `auqol_player_weightless` | Checkbox | On | Client | Running unaffected by carried weight. |
| `auqol_capacity_enabled` | Checkbox | On | Server | Increase carrying capacity. |
| `auqol_capacity_multiplier` | Slider 1–1000 | 1000 | Server | Container capacity multiplier. |
| `auqol_debug` | Checkbox | Off | Client | Write one RPT line per ejection, refill and capacity change. |

There is no medical or logistics stock setting because the audit found no depleting medical or logistics service stock to change. See [docs/service-audit.md](docs/service-audit.md). The full reference is in [docs/configuration.md](docs/configuration.md).

## Compatibility

| | Vanilla | Antistasi Ultimate | RHS | CUP | ACE3 |
| --- | --- | --- | --- | --- | --- |
| Crew ejection | Yes | Yes. Respects its surrendered and captive units, and overrides its `allowCrewInImmobile` on immobilized enemy vehicles. | Yes (config-agnostic) | Yes (config-agnostic) | Yes. Respects ACE captives. |
| Fuel service | `transportFuel` cargo | Yes, including garage fuel sources | Yes (vanilla/ACE config) | Yes (vanilla/ACE config) | ACE refuel infinite-source mode |
| Ammo service | `transportAmmo` cargo | Garage sources are already non-depleting | Yes | Yes | Limited mode is topped up. Unlimited and magazine modes are untouched. |
| Repair service | `transportRepair` cargo | Garage sources are already non-depleting | Yes | Yes | ACE repair has no stock, so it is untouched. |
| No sway | `setCustomAimCoef` | Yes | n/a | n/a | ACE sway factor |
| Unlimited stamina | `enableStamina` | Yes | n/a | n/a | ACE Advanced Fatigue duty factor |
| Weightless running | `loadCoef` trait | Yes. Re-applied after Antistasi role traits. | n/a | n/a | ACE movement base `loadCoef` and fatigue carried mass |
| Carrying capacity | `setMaxLoad` on worn containers | Yes | n/a | n/a | Inventory only. ACE dragging limits are untouched. |

Details and reasoning are in [docs/compatibility.md](docs/compatibility.md).

## How it works

- **Ejection** listens to the global `Dammaged`, `Fuel` and `GetIn` events on land vehicles, excluding static weapons, and acts only on the machine where the vehicle is local. That can be the server, a headless client or a player. A vehicle counts as immobilized when `canMove` is false, or, if enabled, when its fuel is exactly 0. Parked or waiting vehicles never qualify. The mod waits until the vehicle is below 3 km/h, then moves each eligible unit out on the machine that owns it, with `unassignVehicle`, `moveOut` and `leaveVehicle`. Nothing is damaged and ownership is unchanged.
- **Service stock** refills only the service cargo (`setFuelCargo`, `setAmmoCargo`, `setRepairCargo`) of objects whose config declares that service. It refills from the vanilla `Service` event while a vehicle is being serviced, and once when the object appears. A fuel truck's own engine fuel is never touched. Under ACE it uses ACE's own APIs instead.
- **Player features** are applied on settings change, on respawn or unit change, and by a 5-second re-check, because Antistasi re-applies role traits without raising an event. They only restore values AUQOL itself changed.
- **Capacity** is applied by the server, because `setMaxLoad` must run there. It is re-applied when your worn containers change, and containers you drop go back to normal capacity.

There are no per-frame handlers. The only timers are the 5-second player re-check, a 10-second garage-fuel check, and a 30-second ACE rearm top-up, which runs only in ACE limited-supply mode.

## Diagnostics

`call AUQOL_fnc_diagnostics` (debug console) prints which integrations are active on that machine. The same report is written to the RPT once at mission start. Turn on `auqol_debug` for per-action lines.

## Building

Builds use [HEMTT](https://github.com/BrettMayson/HEMTT):

```sh
tools/build.sh          # Linux/macOS: static checks + hemtt check + hemtt release
pwsh tools/build.ps1    # Windows
```

The release zip ends up in `releases/`. Without Arma 3 Tools, HEMTT signs the PBOs with its own key and prints a warning about Arma 3 Tools. That warning is harmless. See [docs/testing.md](docs/testing.md) for what is validated statically and what has to be tested in game.

## Known limitations

- Static weapons, aircraft and boats are never ejected. Ejecting from aircraft in flight would kill the crew.
- An overturned vehicle with no damage is left to the engine, which ejects crews from upside-down vehicles on its own.
- ACE rearm's "magazine supply" mode is a stockpile of specific magazines and is not made infinite.
- ACE limited rearm supply is set to 1,000,000 points and topped up every 30 seconds. ACE raises no event when supply is used, so this is effectively infinite rather than literally infinite.
- The engine caps a soldier's total load at `maxSoldierLoad` (1000 by default). Script can't change that per unit. The optional `@auqol_maxload` addon raises it for every unit, AI included. See [docs/configuration.md](docs/configuration.md#carrying-capacity).
- Antistasi's loadout screen draws its capacity bars from config values, so with the multiplier on it can show more than 100%.
- With infinite stock, selling a fuel or ammo utility item back to the Antistasi garage always refunds its full price, because Antistasi refunds based on the remaining stock.

Troubleshooting is in [docs/installation.md](docs/installation.md#troubleshooting).

## License

MIT, see [LICENSE](LICENSE). This project contains no code from Antistasi Ultimate, CBA_A3 or ACE3. It only calls their public functions at runtime.
