param([switch]$SkipVerify)
$ErrorActionPreference = 'Stop'
$gameRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$runtimeRoot = [IO.Path]::GetFullPath((Join-Path $gameRoot '..\..'))
& (Join-Path $runtimeRoot 'tools\assemble.ps1') `
    -Source (Join-Path $gameRoot 'program\running_light.asm') `
    -Output (Join-Path $gameRoot 'program\running_light.mem') `
    -SkipRom
if (-not $SkipVerify) {
    & (Join-Path $PSScriptRoot 'reference_model.ps1') `
        -Program (Join-Path $gameRoot 'program\running_light.mem')
}
