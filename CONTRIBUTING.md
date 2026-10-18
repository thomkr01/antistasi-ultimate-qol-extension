# Contributing

## Ground rules

- Use only commands, event handlers and functions you can point to in the Arma 3 wiki, CBA_A3, ACE3 or Antistasi Ultimate source. `tests/static_checks.py` enforces this for commands, event handlers, CBA and ACE functions, ACE variables and the Antistasi garage symbols.
- Keep features event-driven. A timer needs a comment saying why no event exists, and it must not run per frame.
- Respect locality. Do work where the object is local, or send a named CBA event to its owner. Don't add `remoteExec`.
- Optional mods are detected at runtime, through `isNil` on functions or their CBA settings. Never add them to `requiredAddons`.
- Don't modify or override Antistasi, CBA, ACE, RHS or CUP functions or configs.

## Layout

```
addons/main/
  config.cpp            CfgPatches, XEH registration, CfgFunctions (tag AUQOL)
  XEH_preInit.sqf       CBA settings
  XEH_postInit.sqf      event wiring
  functions/common      logging, diagnostics, side check, settings-ready entry point
  functions/eject       crew ejection
  functions/service     service stock (vanilla + Antistasi garage)
  functions/player      sway, stamina, weight
  compat/ace            ACE refuel, rearm, sway and fatigue integration
tests/static_checks.py  static validation
tools/build.sh|ps1      check + build
```

New functions go in a `functions/<area>/fn_<name>.sqf` file and get a `class <name> {};` line in `CfgFunctions`. The static checks fail if either is missing.

## Before opening a pull request

```sh
tools/build.sh --sources ../auqol-sources
```

The command must pass. Then describe what you tested in game, and in which environment (SP, hosted, dedicated, with or without ACE), because CI can't run Arma.

## Releasing

1. Bump the version in `addons/main/script_version.hpp` and add a section to `CHANGELOG.md`.
2. Push to `main`. When that version has no GitHub release yet, CI builds the mod, tags the commit `v<version>` and publishes a release with `auqol-<version>.zip`. Pushes that don't change the version publish nothing.
