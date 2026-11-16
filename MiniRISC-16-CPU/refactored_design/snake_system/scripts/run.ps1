param(
    [ValidateSet('Assemble','Regression','CreateProject','Synthesis','Bitstream','All')]
    [string]$Task='All',
    [string]$VivadoBin=''
)
$ErrorActionPreference='Stop'
$scriptRoot=Split-Path -Parent $MyInvocation.MyCommand.Path
$designRoot=[IO.Path]::GetFullPath((Join-Path $scriptRoot '..'))

function Find-VivadoBin([string]$requested) {
    $candidates=@($requested,$env:VIVADO_BIN,'F:\vivado\2026.1\Vivado\bin') | Where-Object { $_ }
    $tool=Get-Command vivado.bat -ErrorAction SilentlyContinue
    if($tool){$candidates += Split-Path -Parent $tool.Source}
    foreach($candidate in $candidates){
        if((Test-Path (Join-Path $candidate 'vivado.bat')) -and (Test-Path (Join-Path $candidate 'xvlog.bat'))){
            return (Resolve-Path $candidate).Path
        }
    }
    throw 'Vivado was not found. Pass -VivadoBin <Vivado/bin>.'
}
function Invoke-VivadoBatch([string]$tclName,[string]$logName) {
    $logDir=Join-Path $designRoot 'reports\implementation'
    New-Item -ItemType Directory -Force -Path $logDir | Out-Null
    $env:SNAKE_SYSTEM_ROOT=$designRoot.Replace('\','/')
    try {
        & (Join-Path $script:VivadoResolved 'vivado.bat') -mode batch -source (Join-Path $scriptRoot $tclName) -log (Join-Path $logDir "$logName.log") -journal (Join-Path $logDir "$logName.jou")
        if($LASTEXITCODE -ne 0){throw "Vivado task $tclName failed with exit code $LASTEXITCODE."}
    } finally { Remove-Item Env:SNAKE_SYSTEM_ROOT -ErrorAction SilentlyContinue }
}
function Invoke-Regression {
    $reportDir=Join-Path $designRoot 'reports\simulation'
    $buildRoot=Join-Path $designRoot 'sim_build'
    New-Item -ItemType Directory -Force -Path $reportDir,$buildRoot | Out-Null
    $rtl=Get-ChildItem (Join-Path $designRoot 'rtl') -Filter '*.v' -Recurse | Sort-Object FullName | ForEach-Object FullName
    $tests=@('tb_cpu_data_instructions','tb_uart_port','tb_tick_timer','tb_snake_system')
    $runTcl=(Join-Path $scriptRoot 'run_simulation.tcl').Replace('\','/')
    $summary=[Collections.Generic.List[string]]::new(); $failures=0; $licenseBlocks=0
    foreach($test in $tests){
        $testBuild=Join-Path $buildRoot $test
        New-Item -ItemType Directory -Force -Path $testBuild | Out-Null
        $log=Join-Path $reportDir "$test.log"
        Push-Location $testBuild
        try {
            $output=& (Join-Path $script:VivadoResolved 'xvlog.bat') @rtl (Join-Path $designRoot "tb\$test.v") 2>&1 | Out-String
            [IO.File]::WriteAllText($log,"--- xvlog ---`r`n$output",[Text.UTF8Encoding]::new($false))
            if($LASTEXITCODE -ne 0){throw "xvlog exit $LASTEXITCODE"}
            $snapshot="${test}_sim"
            $output=& (Join-Path $script:VivadoResolved 'xelab.bat') $test -debug typical -mt off -s $snapshot 2>&1 | Out-String
            [IO.File]::AppendAllText($log,"`r`n--- xelab ---`r`n$output",[Text.UTF8Encoding]::new($false))
            if($LASTEXITCODE -ne 0){throw "xelab exit $LASTEXITCODE"}
            $env:SNAKE_VCD=(Join-Path $reportDir "$test.vcd").Replace('\','/')
            $output=& (Join-Path $script:VivadoResolved 'xsim.bat') $snapshot -wdb (Join-Path $reportDir "$test.wdb") -tclbatch $runTcl 2>&1 | Out-String
            [IO.File]::AppendAllText($log,"`r`n--- xsim ---`r`n$output",[Text.UTF8Encoding]::new($false))
            if($LASTEXITCODE -ne 0 -or $output -notmatch "${test}: TEST PASS" -or $output -match 'TEST FAIL|Fatal:'){throw 'simulation failed'}
            $summary.Add("PASS $test")
        } catch {
            $logText = if (Test-Path $log) { Get-Content -Raw $log } else { '' }
            if ($logText -match 'Could not obtain the necessary license') {
                $licenseBlocks++
                $summary.Add("BLOCKED $test - XSim license unavailable after successful compile/elaboration")
            } else {
                $failures++
                $summary.Add("FAIL $test - $($_.Exception.Message)")
            }
        }
        finally { Remove-Item Env:SNAKE_VCD -ErrorAction SilentlyContinue; Pop-Location }
    }
    $summary.Insert(0,"License-blocked: $licenseBlocks"); $summary.Insert(0,"Failures: $failures"); $summary.Insert(0,"Tests: $($tests.Count)"); $summary.Insert(0,'MiniRISC-16 Snake RTL regression')
    [IO.File]::WriteAllLines((Join-Path $reportDir 'regression-last-attempt.txt'),$summary,[Text.UTF8Encoding]::new($false))
    $summary
    if($failures){throw "$failures regression test(s) failed."}
    if($licenseBlocks){throw "$licenseBlocks regression test(s) blocked by the XSim license service."}
    [IO.File]::WriteAllLines((Join-Path $reportDir 'regression-summary.txt'),$summary,[Text.UTF8Encoding]::new($false))
}

& (Join-Path $designRoot 'tools\assemble.ps1')
if($Task -in @('Regression','All')){& (Join-Path $designRoot 'tools\reference_model.ps1')}
if($Task -ne 'Assemble'){$script:VivadoResolved=Find-VivadoBin $VivadoBin}
if($Task -in @('Regression','All')){Invoke-Regression}
if($Task -eq 'CreateProject'){Invoke-VivadoBatch 'create_project.tcl' 'create-project'}
if($Task -eq 'Synthesis'){Invoke-VivadoBatch 'run_synthesis.tcl' 'synthesis'}
if($Task -eq 'Bitstream'){Invoke-VivadoBatch 'build_bitstream.tcl' 'bitstream'}
if($Task -eq 'All'){Invoke-VivadoBatch 'create_project.tcl' 'create-project'; Invoke-VivadoBatch 'build_bitstream.tcl' 'bitstream'}
