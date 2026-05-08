<#
.SYNOPSIS
    Run a single Maestro flow file.
.PARAMETER Flow
    Path to the flow YAML (relative to project root or absolute).
.PARAMETER Platform
    Target platform: android or ios — sets which APP_ID env var to forward (default: android).
.PARAMETER Env
    Extra env vars, e.g. -Env @{EMAIL="user@test.com"}
.EXAMPLE
    .\run_flow.ps1 -Flow flows/android/TC-AND-001_login_valid.yaml
    .\run_flow.ps1 -Flow flows/ios/TC-IOS-001_login_valid.yaml -Platform ios
    .\run_flow.ps1 -Flow flows/android/TC-AND-001_login_valid.yaml -Env @{EMAIL="other@test.com"}
#>
param(
    [Parameter(Mandatory)]
    [string]$Flow,

    [ValidateSet("android", "ios")]
    [string]$Platform = "android",

    [hashtable]$Env = @{}
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Root    = Split-Path -Parent $PSScriptRoot
$EnvFile = Join-Path $Root ".env"

if (-not (Get-Command maestro -ErrorAction SilentlyContinue)) {
    Write-Error "Maestro CLI not found. See README.md § 3 for install instructions."
    exit 1
}

if (-not (Test-Path $EnvFile)) {
    Write-Warning ".env not found. Copying .env.example — edit it before running tests."
    Copy-Item (Join-Path $Root ".env.example") $EnvFile
}

if (-not [System.IO.Path]::IsPathRooted($Flow)) {
    $Flow = Join-Path $Root $Flow
}

if (-not (Test-Path $Flow)) {
    Write-Error "Flow file not found: $Flow"
    exit 1
}

# Load .env
$envVars = @{}
Get-Content $EnvFile | Where-Object { $_ -match '^\s*[^#]' -and $_ -match '=' } | ForEach-Object {
    $parts = $_ -split '=', 2
    $envVars[$parts[0].Trim()] = $parts[1].Trim()
}

$maestroArgs = @("test", $Flow)

# Forward platform-appropriate APP_ID
if ($Platform -eq "android" -and $envVars["ANDROID_APP_ID"]) {
    $maestroArgs += "--env", "ANDROID_APP_ID=$($envVars['ANDROID_APP_ID'])"
    $maestroArgs += "--env", "APP_ID=$($envVars['ANDROID_APP_ID'])"
} elseif ($Platform -eq "ios" -and $envVars["IOS_APP_ID"]) {
    $maestroArgs += "--env", "IOS_APP_ID=$($envVars['IOS_APP_ID'])"
    $maestroArgs += "--env", "APP_ID=$($envVars['IOS_APP_ID'])"
}

# Forward credentials
foreach ($key in @("ANDROID_EMAIL", "IOS_EMAIL", "PASSWORD")) {
    if ($envVars[$key]) {
        $maestroArgs += "--env", "$key=$($envVars[$key])"
    }
}

# Forward caller overrides
foreach ($key in $Env.Keys) {
    $maestroArgs += "--env", "$key=$($Env[$key])"
}

Write-Host "[info] Running  : maestro $($maestroArgs -join ' ')"
Write-Host ""

& maestro @maestroArgs

exit $LASTEXITCODE
