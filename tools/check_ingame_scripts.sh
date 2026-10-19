#!/usr/bin/env bash
# Compiles tests/ingame/*.sqf with HEMTT in a throwaway project, since they are not part of the addon.
set -euo pipefail
cd "$(dirname "$0")/.."
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/.hemtt" "$TMP/addons/tests"
cp tests/ingame/*.sqf "$TMP/addons/tests/"
echo 'z\auqoltest\addons\tests' > "$TMP/addons/tests/\$PBOPREFIX\$"
echo 'class CfgPatches { class auqoltest_tests { units[] = {}; weapons[] = {}; requiredVersion = 2.12; requiredAddons[] = {}; }; };' > "$TMP/addons/tests/config.cpp"
printf 'name = "AUQOL in-game test scripts"\nprefix = "auqoltest"\nmainprefix = "z"\n\n[version]\nmajor = 1\nminor = 0\npatch = 0\nbuild = 0\ngit_hash = 0\n' > "$TMP/.hemtt/project.toml"
(cd "$TMP" && hemtt check --pedantic --error-on-all)
