param(
    [ValidateSet('Assemble','Regression','CreateProject','Synthesis','Bitstream','All')]
    [string]$Task = 'All',
    [string]$VivadoBin = ''
)

$ErrorActionPreference = 'Stop'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$designRoot = [IO.Path]::GetFullPath((Join-Path $scriptRoot '..'))

function Find-VivadoBin {
    param([string]$Requested)
    $candidates = New-Object System.Collections.Generic.List[string]
    if ($Requested) { $candidates.Add($Requested) }
    if ($env:VIVADO_BIN) { $candidates.Add($env:VIVADO_BIN) }
    if ($env:XILINX_VIVADO) { $candidates.Add((Join-Path $env:XILINX_VIVADO 'bin')) }
    $pathTool = Get-Command 'vivado.bat' -ErrorAction SilentlyContinue
    if ($pathTool) { $candidates.Add((Split-Path -Parent $pathTool.Source)) }
    foreach ($drive in Get-PSDrive -PSProvider FileSystem) {
        foreach ($baseRelative in @('vivado','Xilinx\Vivado')) {
            $base = Join-Path $drive.Root $baseRelative
            if (Test-Path -LiteralPath $base) {
                foreach ($version in Get-ChildItem -LiteralPath $base -Directory -ErrorAction SilentlyContinue) {
                    $candidates.Add((Join-Path $version.FullName 'Vivado\bin'))
                    $candidates.Add((Join-Path $version.FullName 'bin'))
                }
            }
        }
    }
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path (Join-Path $candidate 'vivado.bat')) -and
            (Test-Path (Join-Path $candidate 'xvlog.bat'))) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }
    throw 'Vivado was not found. Pass -VivadoBin <Vivado/bin>.'
}

function Invoke-Assemble {
    & (Join-Path $designRoot 'tools\assemble.ps1')
}

function Invoke-ReferenceModel {
    & (Join-Path $designRoot 'tools\reference_model.ps1')
}

function Invoke-VivadoBatch {
    param([string]$TclName, [string]$LogName)
    $vivado = Join-Path $script:VivadoResolved 'vivado.bat'
    $tcl = Join-Path $scriptRoot $TclName
    $logDir = Join-Path $designRoot 'reports\implementation'
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    $env:CALCULATOR_SYSTEM_ROOT = $designRoot.Replace('\','/')
    try {
        & $vivado -mode batch -source $tcl -log (Join-Path $logDir "$LogName.log") -journal (Join-Path $logDir "$LogName.jou")
        if ($LASTEXITCODE -ne 0) { throw "Vivado task $TclName failed with exit code $LASTEXITCODE." }
    } finally {
        Remove-Item Env:CALCULATOR_SYSTEM_ROOT -ErrorAction SilentlyContinue
    }
}

function Invoke-Regression {
    $reportDir = Join-Path $designRoot 'reports\simulation'
    $buildRoot = Join-Path $designRoot 'sim_build'
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    New-Item -ItemType Directory -Path $buildRoot -Force | Out-Null
    $rtl = Get-ChildItem -LiteralPath (Join-Path $designRoot 'rtl') -Filter '*.v' -Recurse |
        Sort-Object FullName | ForEach-Object FullName
    $tests = @('tb_switch8_debounced','tb_button_s1_controller','tb_scratchpad_ram','tb_cpu_status_port',
               'tb_io_decoder','tb_cpu_flags_output','tb_peripheral_subsystem',
               'tb_calculator_system','tb_calculator_board_top')
    $xvlog = Join-Path $script:VivadoResolved 'xvlog.bat'
    $xelab = Join-Path $script:VivadoResolved 'xelab.bat'
    $xsim = Join-Path $script:VivadoResolved 'xsim.bat'
    $runTcl = (Join-Path $scriptRoot 'run_simulation.tcl').Replace('\','/')
    $summary = New-Object System.Collections.Generic.List[string]
    $failures = 0

    foreach ($test in $tests) {
        $testBuild = Join-Path $buildRoot $test
        New-Item -ItemType Directory -Path $testBuild -Force | Out-Null
        if ($test -in @('tb_calculator_system','tb_calculator_board_top')) {
            Copy-Item (Join-Path $designRoot 'program\calculator.mem') (Join-Path $testBuild 'calculator.mem') -Force
        }
        $log = Join-Path $reportDir "$test.log"
        Push-Location $testBuild
        try {
            $compileOutput = & $xvlog @rtl (Join-Path $designRoot "tb\$test.v") 2>&1 | Out-String
            [IO.File]::WriteAllText($log, "--- xvlog ---`r`n$compileOutput", [Text.UTF8Encoding]::new($false))
            if ($LASTEXITCODE -ne 0) { throw "xvlog exit $LASTEXITCODE" }
            $snapshot = "${test}_sim"
            $elabOutput = & $xelab $test -debug typical -mt off -s $snapshot 2>&1 | Out-String
            [IO.File]::AppendAllText($log, "`r`n--- xelab ---`r`n$elabOutput", [Text.UTF8Encoding]::new($false))
            if ($LASTEXITCODE -ne 0) { throw "xelab exit $LASTEXITCODE" }
            $env:CALCULATOR_VCD = (Join-Path $reportDir "$test.vcd").Replace('\','/')
            $simOutput = & $xsim $snapshot -wdb (Join-Path $reportDir "$test.wdb") -tclbatch $runTcl 2>&1 | Out-String
            [IO.File]::AppendAllText($log, "`r`n--- xsim ---`r`n$simOutput", [Text.UTF8Encoding]::new($false))
            if ($LASTEXITCODE -ne 0) { throw "xsim exit $LASTEXITCODE" }
            if ($simOutput -notmatch [regex]::Escape("${test}: TEST PASS")) { throw 'TEST PASS marker missing' }
            if ($simOutput -match 'TEST FAIL|Fatal:') { throw 'failure marker found' }
            $summary.Add("PASS $test")
        } catch {
            $failures++
            $summary.Add("FAIL $test - $($_.Exception.Message)")
        } finally {
            Remove-Item Env:CALCULATOR_VCD -ErrorAction SilentlyContinue
            Pop-Location
        }
    }
    $summary.Insert(0,"Failures: $failures")
    $summary.Insert(0,"Tests: $($tests.Count)")
    $summary.Insert(0,"MiniRISC-16 calculator RTL regression")
    [IO.File]::WriteAllLines((Join-Path $reportDir 'regression-summary.txt'),$summary,[Text.UTF8Encoding]::new($false))
    $summary | ForEach-Object { Write-Output $_ }
    if ($failures -ne 0) { throw "$failures RTL regression test(s) failed." }
}

if ($Task -in @('Assemble','Regression','CreateProject','Synthesis','Bitstream','All')) { Invoke-Assemble }
if ($Task -in @('Regression','All')) {
    Invoke-ReferenceModel
    $script:VivadoResolved = Find-VivadoBin $VivadoBin
    Invoke-Regression
}
if ($Task -in @('CreateProject','Synthesis','Bitstream','All')) {
    $script:VivadoResolved = Find-VivadoBin $VivadoBin
}
if ($Task -eq 'CreateProject') { Invoke-VivadoBatch 'create_project.tcl' 'create-project' }
if ($Task -eq 'Synthesis') { Invoke-VivadoBatch 'run_synthesis.tcl' 'synthesis' }
if ($Task -eq 'Bitstream') { Invoke-VivadoBatch 'build_bitstream.tcl' 'bitstream' }
if ($Task -eq 'All') {
    Invoke-VivadoBatch 'create_project.tcl' 'create-project'
    Invoke-VivadoBatch 'build_bitstream.tcl' 'bitstream'
}
