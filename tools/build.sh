#!/usr/bin/env bash
# Static checks + HEMTT check + HEMTT release. Usage: tools/build.sh [--sources DIR]
# With --sources DIR, CBA_A3, ACE3, Antistasi Ultimate and the parsed Arma 3 wiki are cloned into
# DIR (once) and the source-backed checks in tests/static_checks.py run as well.
set -euo pipefail
cd "$(dirname "$0")/.."

SOURCES=""
if [[ "${1:-}" == "--sources" ]]; then SOURCES="${2:?--sources needs a directory}"; fi

if ! command -v hemtt >/dev/null 2>&1; then
    echo "hemtt not found. Install HEMTT 1.22+ from https://github.com/BrettMayson/HEMTT/releases and put it on PATH." >&2
    exit 1
fi

ARGS=()
if [[ -n "$SOURCES" ]]; then
    mkdir -p "$SOURCES"
    clone() { [[ -d "$SOURCES/$1" ]] || git clone --depth 1 ${3:+-b "$3"} "$2" "$SOURCES/$1"; }
    clone cba https://github.com/CBATeam/CBA_A3.git
    clone ace https://github.com/acemod/ACE3.git
    clone antistasi https://github.com/SilenceIsFatto/A3-Antistasi-Ultimate.git
    clone wiki https://github.com/acemod/arma3-wiki.git dist
    ARGS=(--cba "$SOURCES/cba" --ace "$SOURCES/ace" --antistasi "$SOURCES/antistasi" --wiki "$SOURCES/wiki")
fi

python3 tests/static_checks.py ${ARGS[@]+"${ARGS[@]}"}
hemtt check --pedantic --error-on-all
tools/check_ingame_scripts.sh
hemtt release
echo "Release zip: $(ls -1 releases/*.zip | head -n 1)"
