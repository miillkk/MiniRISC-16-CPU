param(
    [string]$VivadoBin = "",
    [string]$LicenseFile = ""
)

$scriptPath = Join-Path $PSScriptRoot "run_synthesis.ps1"
& $scriptPath -VivadoBin $VivadoBin -LicenseFile $LicenseFile -Task Project
exit $LASTEXITCODE
