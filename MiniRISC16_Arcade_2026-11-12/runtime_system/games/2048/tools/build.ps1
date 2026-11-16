param([switch]$SkipVerify)
$ErrorActionPreference='Stop'
$gameRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$runtimeRoot=[IO.Path]::GetFullPath((Join-Path $gameRoot '..\..'))
& (Join-Path $runtimeRoot 'tools\assemble.ps1') `
    -Source (Join-Path $gameRoot 'program\game_2048.asm') `
    -Output (Join-Path $gameRoot 'program\game_2048.mem') `
    -SkipRom
if (-not $SkipVerify) {
    & (Join-Path $PSScriptRoot 'reference_model.ps1') `
        -Program (Join-Path $gameRoot 'program\game_2048.mem')
}
