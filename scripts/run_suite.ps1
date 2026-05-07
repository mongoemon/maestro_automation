<#
.SYNOPSIS
    Run a named test suite on a specific platform.
.PARAMETER Platform
    Target platform: android or ios (default: android)
.PARAMETER Suite
    Suite name: smoke | auth | validation | regression
.EXAMPLE
    .\run_suite.ps1 -Platform android -Suite smoke
    .\run_suite.ps1 -Platform ios -Suite auth
    .\run_suite.ps1 -Platform android -Suite regression
#>
param(
    [ValidateSet("android", "ios")]
    [string]$Platform = "android",

    [ValidateSet("smoke", "auth", "validation", "regression")]
    [Parameter(Mandatory)]
    [string]$Suite
)

Set-StrictMode -Version Latest

$TagMap = @{
    smoke      = "smoke"
    auth       = "auth"
    validation = "validation"
    regression = "smoke,auth,validation"
}

$Tag = $TagMap[$Suite]

Write-Host "[info] Suite    : $Suite"
Write-Host "[info] Platform : $Platform"
Write-Host "[info] Tags     : $Tag"
Write-Host ""

& "$PSScriptRoot\run_all.ps1" -Platform $Platform -Tag $Tag -Report

exit $LASTEXITCODE
