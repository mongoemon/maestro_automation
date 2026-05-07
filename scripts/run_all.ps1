<#
.SYNOPSIS
    Run all Maestro flows for a given platform.
.PARAMETER Platform
    Target platform: android or ios (default: android)
.PARAMETER Tag
    Run only flows with this tag (e.g. smoke, auth, validation)
.PARAMETER Report
    Generate JUnit XML report in reports/
.EXAMPLE
    .\run_all.ps1 -Platform android
    .\run_all.ps1 -Platform ios -Tag smoke
    .\run_all.ps1 -Platform android -Tag auth -Report
#>
param(
    [ValidateSet("android", "ios")]
    [string]$Platform = "android",
    [string]$Tag = "",
    [switch]$Report
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Root      = Split-Path -Parent $PSScriptRoot
$EnvFile   = Join-Path $Root ".env"
$FlowDir   = Join-Path $Root "flows\$Platform"
$ReportDir = Join-Path $Root "reports"

if (-not (Get-Command maestro -ErrorAction SilentlyContinue)) {
    Write-Error "Maestro CLI not found. See README.md § 3 for install instructions."
    exit 1
}

if (-not (Test-Path $EnvFile)) {
    Write-Warning ".env not found. Copying .env.example — edit it before running tests."
    Copy-Item (Join-Path $Root ".env.example") $EnvFile
}

if (-not (Test-Path $FlowDir)) {
    Write-Error "Flow directory not found: $FlowDir"
    exit 1
}

if ($Report) {
    New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null
}

# Load .env into environment
Get-Content $EnvFile | Where-Object { $_ -match '^\s*[^#]' -and $_ -match '=' } | ForEach-Object {
    $parts = $_ -split '=', 2
    [System.Environment]::SetEnvironmentVariable($parts[0].Trim(), $parts[1].Trim())
}

$maestroArgs = @("test", $FlowDir)

if ($Tag) {
    $maestroArgs += "--include-tags", $Tag
}

if ($Report) {
    $maestroArgs += "--format", "junit", "--output", (Join-Path $ReportDir "report-$Platform.xml")
}

Write-Host "[info] Platform : $Platform"
Write-Host "[info] Flow dir : $FlowDir"
if ($Tag) { Write-Host "[info] Tags     : $Tag" }
Write-Host "[info] Running  : maestro $($maestroArgs -join ' ')"
Write-Host ""

& maestro @maestroArgs

if ($LASTEXITCODE -ne 0) {
    Write-Error "One or more flows failed. Check output and reports/screenshots/."
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "[done] All $Platform flows passed."
