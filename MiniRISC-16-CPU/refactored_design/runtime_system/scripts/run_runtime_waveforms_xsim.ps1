param(
    [string]$VivadoRoot = 'F:\vivado\2026.1\Vivado',
    [string]$GccBin = 'E:\mingw64\bin'
)

$ErrorActionPreference = 'Stop'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$designRoot = [IO.Path]::GetFullPath((Join-Path $scriptRoot '..'))
$vivado = Join-Path $VivadoRoot 'bin\vivado.bat'
$gcc = Join-Path $GccBin 'gcc.exe'
$tcl = Join-Path $scriptRoot 'run_runtime_waveforms_vivado.tcl'
$log = Join-Path $designRoot 'reports\waveforms\current_terminal\vivado-xsim-run.log'

if (-not (Test-Path -LiteralPath $vivado)) {
    throw "Vivado launcher not found: $vivado"
}
if (-not (Test-Path -LiteralPath $gcc)) {
    throw "Working GCC not found: $gcc"
}

$oldGccPath = $env:GCC_SIM_EXE_PATH
$env:GCC_SIM_EXE_PATH = $GccBin
Push-Location $designRoot
try {
    & $vivado -mode batch -nojournal -nolog -source $tcl 2>&1 |
        Tee-Object -FilePath $log
    if ($LASTEXITCODE -ne 0) {
        throw "Vivado/XSim failed with exit code $LASTEXITCODE. See $log"
    }
}
finally {
    Pop-Location
    $env:GCC_SIM_EXE_PATH = $oldGccPath
}

if ((Get-Content -Raw -LiteralPath $log) -notmatch 'RUNTIME_WAVEFORMS_COMPLETE') {
    throw "Vivado/XSim completion marker is missing. See $log"
}

Write-Output 'VIVADO_XSIM_REPAIR_PASS'
