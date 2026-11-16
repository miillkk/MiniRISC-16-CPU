param(
    [string]$IverilogBin = 'C:\iverilog\bin',
    [switch]$FocusedOnly
)

$ErrorActionPreference = 'Stop'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$designRoot = [IO.Path]::GetFullPath((Join-Path $scriptRoot '..'))
$iverilog = Join-Path $IverilogBin 'iverilog.exe'
$vvp = Join-Path $IverilogBin 'vvp.exe'

if (-not (Test-Path -LiteralPath $iverilog)) {
    throw "Icarus Verilog not found at $iverilog"
}
if (-not (Test-Path -LiteralPath $vvp)) {
    throw "Icarus runtime not found at $vvp"
}

$reportDir = Join-Path $designRoot 'reports\simulation\iverilog'
$waveDir = Join-Path $designRoot 'reports\waveforms\current_terminal'
$buildDir = Join-Path $designRoot 'sim_build\iverilog'
New-Item -ItemType Directory -Force -Path $reportDir,$waveDir,$buildDir | Out-Null

$rtl = Get-ChildItem (Join-Path $designRoot 'rtl') -Filter '*.v' -Recurse |
    Sort-Object FullName | ForEach-Object FullName

$tests = if ($FocusedOnly) {
    @('tb_runtime_running_light_wave','tb_runtime_extended_isa_wave')
} else {
    @(
        'tb_cpu_data_instructions',
        'tb_program_capacity',
        'tb_program_loader',
        'tb_uart_port',
        'tb_tick_timer',
        'tb_snake_system',
        'tb_runtime_running_light_wave',
        'tb_runtime_extended_isa_wave'
    )
}

$summary = [Collections.Generic.List[string]]::new()
$summary.Add('MiniRISC-16 Runtime Arcade RTL verification (Icarus fallback)')
$summary.Add("Simulator: $(& $iverilog -V 2>&1 | Select-Object -First 1)")
$failures = 0

Push-Location $designRoot
try {
    foreach ($test in $tests) {
        $testbench = if ($test -like 'tb_runtime_*_wave') {
            Join-Path $designRoot 'tb\tb_runtime_waveforms.v'
        } else {
            Join-Path $designRoot "tb\$test.v"
        }
        $outputFile = Join-Path $buildDir "$test.vvp"
        $logFile = Join-Path $reportDir "$test.log"

        Remove-Item -LiteralPath $outputFile -Force -ErrorAction SilentlyContinue
        $compileOutput = & $iverilog -g2012 -Wall -s $test -o $outputFile @rtl $testbench 2>&1 | Out-String
        $compileExit = $LASTEXITCODE
        $compiled = (Test-Path -LiteralPath $outputFile) -and
            ((Get-Item -LiteralPath $outputFile).Length -gt 0) -and
            ($compileOutput -notmatch '(?im)^.*error:')
        $compileNote = if ($compileExit -ne 0 -and $compiled) {
            "NOTE: iverilog returned $compileExit after writing a valid vvp image; vvp execution is used as the functional gate.`r`n"
        } else { '' }
        [IO.File]::WriteAllText($logFile,"--- iverilog ---`r`n$compileOutput$compileNote",[Text.UTF8Encoding]::new($false))
        if (-not $compiled) {
            $failures++
            $summary.Add("FAIL $test - compile")
            continue
        }

        $runOutput = & $vvp $outputFile 2>&1 | Out-String
        [IO.File]::AppendAllText($logFile,"`r`n--- vvp ---`r`n$runOutput",[Text.UTF8Encoding]::new($false))
        if ($LASTEXITCODE -ne 0 -or $runOutput -notmatch 'TEST PASS' -or
            $runOutput -match 'TEST FAIL|WATCHDOG TIMEOUT|FATAL') {
            $failures++
            $summary.Add("FAIL $test - runtime")
        } else {
            $summary.Add("PASS $test")
        }
    }
}
finally {
    Pop-Location
}

$summary.Insert(2,"Tests: $($tests.Count)")
$summary.Insert(3,"Failures: $failures")
$summaryName = if ($FocusedOnly) { 'focused-waveforms-summary.txt' } else { 'regression-summary.txt' }
$summaryPath = Join-Path $reportDir $summaryName
[IO.File]::WriteAllLines($summaryPath,$summary,[Text.UTF8Encoding]::new($false))
$summary
if ($failures) { throw "$failures Icarus verification test(s) failed." }
