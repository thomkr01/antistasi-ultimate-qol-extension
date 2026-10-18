# Static checks + HEMTT check + HEMTT release. Usage: pwsh tools/build.ps1 [-Sources DIR]
# With -Sources DIR, CBA_A3, ACE3, Antistasi Ultimate and the parsed Arma 3 wiki are cloned into
# DIR (once) and the source-backed checks in tests/static_checks.py run as well.
param([string]$Sources = "")
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

if (-not (Get-Command hemtt -ErrorAction SilentlyContinue)) {
    Write-Error "hemtt not found. Install HEMTT 1.22+ from https://github.com/BrettMayson/HEMTT/releases and make sure it is on PATH."
}

$python = if (Get-Command python3 -ErrorAction SilentlyContinue) { "python3" } else { "python" }
$checkArgs = @()
if ($Sources -ne "") {
    New-Item -ItemType Directory -Force -Path $Sources | Out-Null
    $repos = @(
        @("cba", "https://github.com/CBATeam/CBA_A3.git", ""),
        @("ace", "https://github.com/acemod/ACE3.git", ""),
        @("antistasi", "https://github.com/SilenceIsFatto/A3-Antistasi-Ultimate.git", ""),
        @("wiki", "https://github.com/acemod/arma3-wiki.git", "dist")
    )
    foreach ($r in $repos) {
        $dest = Join-Path $Sources $r[0]
        if (-not (Test-Path $dest)) {
            if ($r[2] -ne "") { git clone --depth 1 -b $r[2] $r[1] $dest } else { git clone --depth 1 $r[1] $dest }
            if ($LASTEXITCODE -ne 0) { throw "git clone $($r[1]) failed" }
        }
    }
    $checkArgs = @("--cba", (Join-Path $Sources "cba"), "--ace", (Join-Path $Sources "ace"),
                   "--antistasi", (Join-Path $Sources "antistasi"), "--wiki", (Join-Path $Sources "wiki"))
}

& $python tests/static_checks.py @checkArgs
if ($LASTEXITCODE -ne 0) { throw "static checks failed" }
hemtt check --pedantic --error-on-all
if ($LASTEXITCODE -ne 0) { throw "hemtt check failed" }

# Compile tests/ingame/*.sqf with HEMTT in a throwaway project, since they are not part of the addon.
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("auqol-ingame-" + [guid]::NewGuid())
New-Item -ItemType Directory -Force -Path (Join-Path $tmp ".hemtt"), (Join-Path $tmp "addons/tests") | Out-Null
Copy-Item tests/ingame/*.sqf (Join-Path $tmp "addons/tests")
Set-Content -LiteralPath (Join-Path $tmp 'addons/tests/$PBOPREFIX$') -Value 'z\auqoltest\addons\tests'
Set-Content -LiteralPath (Join-Path $tmp "addons/tests/config.cpp") -Value 'class CfgPatches { class auqoltest_tests { units[] = {}; weapons[] = {}; requiredAddons[] = {}; }; };'
Set-Content -LiteralPath (Join-Path $tmp ".hemtt/project.toml") -Value "name = `"AUQOL in-game test scripts`"`nprefix = `"auqoltest`"`nmainprefix = `"z`"`n`n[version]`nmajor = 1`nminor = 0`npatch = 0`nbuild = 0`ngit_hash = 0"
Push-Location $tmp
try { hemtt check --pedantic --error-on-all; if ($LASTEXITCODE -ne 0) { throw "in-game test scripts failed to compile" } }
finally { Pop-Location; Remove-Item -Recurse -Force $tmp }
hemtt release
if ($LASTEXITCODE -ne 0) { throw "hemtt release failed" }
Get-ChildItem releases/*.zip | Select-Object -First 1 | ForEach-Object { "Release zip: $($_.FullName)" }
