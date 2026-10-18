# Antistasi Ultimate QoL Extension (AUQOL)

A standalone Arma 3 addon that adds quality-of-life features to Antistasi Ultimate without editing any mission file. It needs CBA_A3. ACE3, RHS and CUP are optional, and the mod detects them at runtime.

A full description of each feature and its rules is in [FEATURES.md](FEATURES.md). [FILEMAP.md](FILEMAP.md) lists where everything is in the repo.

| Feature | What it does |
| --- | --- |
| Enemy crew ejection | When an enemy AI land vehicle can no longer move, its living enemy AI occupants are moved out and their group stops using the vehicle. |
| Infinite service stock | Recognized fuel, ammo and repair sources never run out of what they hand out. Services that are already unlimited are left alone. |
| No weapon sway | Removes weapon sway for your own character. |
| Unlimited stamina | Your own character never tires. AI is unchanged. |
| Weight-independent running | Carried weight no longer drains or reserves your stamina. |
| No total weight limit | You can keep picking things up however heavy your load is. Uniform, vest and backpack keep their normal size. |
| No recoil (optional) | Removes weapon recoil for your own character. Off by default. |
| Loot from any vehicle | Every vehicle gets the loot crate's "Gather Scattered Loot" action, and the vehicle and the crate share one radius you can set up to 2000 m. |
| Short Withstand cooldown | Antistasi's Withstand self-revive cooldown drops from 5 minutes to 1 second, adjustable. |

Every feature is on by default, has its own CBA setting, and can be switched on or off while the mission is running.

## Requirements

- Arma 3 2.12 or newer (stable branch). The vanilla `Service` event handler the service feature uses was added in 2.12.
- [CBA_A3](https://github.com/CBATeam/CBA_A3), as a hard dependency (`requiredAddons[] = {"cba_main"}`).
- Antistasi Ultimate is the target mission, but it isn't required to load the addon.

## Installation

1. Download the latest zip from [Releases](https://github.com/thomkr01/antistasi-ultimate-qol-extension/releases) (or build it, see [Building](#building)) and extract `@auqol`.
2. Load it alongside CBA_A3 and Antistasi Ultimate, for example `-mod=@CBA_A3;@AntistasiUltimate;@auqol`.
3. In multiplayer, run it on the server and on every client. Settings that change world state are forced by the server.

More detail is in [docs/installation.md](docs/installation.md).

## CBA settings

Open **Options → Addon Options → Antistasi Ultimate QoL by TchicX**. "Server" settings are synchronized from the server to everyone (`isGlobal = 1`). The only "Client" setting is `auqol_debug`, which each machine sets for itself. Player features (sway, stamina, weight) are still applied on each player's own machine, but the server decides whether they are on.

| Setting | Type | Default | Scope | Purpose |
| --- | --- | --- | --- | --- |
| `auqol_eject_enabled` | Checkbox | On | Server | Eject enemy crew from immobilized vehicles. |
| `auqol_eject_outOfFuel` | Checkbox | On | Server | Count an empty fuel tank as immobilized too. |
| `auqol_service_fuel` | Checkbox | On | Server | Infinite fuel-service stock. |
| `auqol_service_ammo` | Checkbox | On | Server | Infinite ammunition-service stock. |
| `auqol_service_repair` | Checkbox | On | Server | Infinite repair-service stock. |
| `auqol_service_garageFuel` | Checkbox | On | Server | Keep Antistasi garage fuel sources full. Also needs the fuel setting on. |
| `auqol_player_noSway` | Checkbox | On | Server | No weapon sway. |
| `auqol_player_unlimitedStamina` | Checkbox | On | Server | Unlimited stamina. |
| `auqol_player_weightless` | Checkbox | On | Server | Running unaffected by carried weight. |
| `auqol_player_noRecoil` | Checkbox | Off | Server | No weapon recoil. |
| `auqol_loot_enabled` | Checkbox | On | Server | Loot action on every vehicle, with the radius below for vehicles and the loot crate. |
| `auqol_loot_radius` | Slider 10–2000 | 2000 | Server | Loot gather radius in metres. |
| `auqol_loot_enemyRadius` | Slider 10–2000 | 500 | Server | Gathering is refused while an enemy in combat is this close. |
| `auqol_loot_caches` | Checkbox | On | Server | Also empty enemy item caches within 30 m into the vehicle or crate, then delete the empty box. |
| `auqol_withstand_enabled` | Checkbox | On | Server | Replace Antistasi's 5-minute Withstand cooldown. |
| `auqol_withstand_timeout` | Slider 1–300 | 1 | Server | Withstand cooldown in seconds. |
| `auqol_debug` | Checkbox | Off | Client | Write one RPT line per ejection, refill and loot run. |

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
| No total weight limit | `maxSoldierLoad` in config | Yes | n/a | n/a | Inventory only. ACE dragging limits are untouched. |
| No recoil | `setUnitRecoilCoefficient` | Yes | n/a | n/a | n/a (ACE has no recoil module) |

Details and reasoning are in [docs/compatibility.md](docs/compatibility.md).

## How it works

- **Ejection** listens to the global `Dammaged`, `Fuel` and `GetIn` events on land vehicles, excluding static weapons, and acts only on the machine where the vehicle is local. That can be the server, a headless client or a player. A vehicle counts as immobilized when `canMove` is false, or, if enabled, when its fuel is exactly 0. Parked or waiting vehicles never qualify. The mod waits until the vehicle is below 3 km/h, then moves each eligible unit out on the machine that owns it, with `unassignVehicle`, `moveOut` and `leaveVehicle`. Nothing is damaged and ownership is unchanged.
- **Service stock** refills only the service cargo (`setFuelCargo`, `setAmmoCargo`, `setRepairCargo`) of objects whose config declares that service. It refills from the vanilla `Service` event while a vehicle is being serviced, and once when the object appears. A fuel truck's own engine fuel is never touched. Under ACE it uses ACE's own APIs instead.
- **Player features** are applied on settings change, on respawn or unit change, and by a 5-second re-check, because Antistasi re-applies role traits without raising an event. They only restore values AUQOL itself changed.
- **Loot** adds a copy of the crate's hold action to vehicles and swaps it in on the crate. Completing it asks the server to run Antistasi's own `SCRT_fnc_loot_gatherLoot`, the crate's function, with the AUQOL radius. The 10-second cooldown, unlocked-item rule and money split are Antistasi's. Enemy item caches within 30 m (the supply crates at outposts, bases and airports) are emptied into a weapon holder first, so the same run picks their contents up, and the empty box is deleted. The enemies-nearby check is done by AUQOL with its own radius, using Antistasi's `A3A_fnc_enemyNearCheck`.
- **Withstand** sets `A3A_selfReviveTimeout`, the cooldown Antistasi's `A3A_fnc_selfRevive` reads, which defaults to 300 s.
- **No total weight limit** raises the engine's total soldier load cap (`maxSoldierLoad`, vanilla 1000) to 10,000,000 in config. That cap is what stops you adding items once you carry something heavy. Each container's own size is unchanged.

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
- The total weight limit is a config value, so it applies to every unit, AI included, and has no in-game switch. Script can't change it per unit. See [docs/configuration.md](docs/configuration.md#total-weight-limit).
- Loot and Withstand need Antistasi Ultimate. Withstand also needs the mission's Withstand self-revive parameter turned on.
- With infinite stock, selling a fuel or ammo utility item back to the Antistasi garage always refunds its full price, because Antistasi refunds based on the remaining stock.

Troubleshooting is in [docs/installation.md](docs/installation.md#troubleshooting).

## License

MIT, see [LICENSE](LICENSE). This project contains no code from Antistasi Ultimate, CBA_A3 or ACE3. It only calls their public functions at runtime.
