param(
    [string]$VivadoBin = "",
    [string]$LicenseFile = "",
    [switch]$IncludeBoard
)

$ErrorActionPreference = "Stop"

function Find-VivadoBin {
    param([string]$RequestedPath)

    $candidates = New-Object System.Collections.Generic.List[string]
    if ($RequestedPath) { $candidates.Add($RequestedPath) }
    if ($env:VIVADO_BIN) { $candidates.Add($env:VIVADO_BIN) }
    if ($env:XILINX_VIVADO) { $candidates.Add((Join-Path $env:XILINX_VIVADO "bin")) }

    $pathCommand = Get-Command "xvlog.bat" -ErrorAction SilentlyContinue
    if ($pathCommand) { $candidates.Add((Split-Path -Parent $pathCommand.Source)) }

    foreach ($drive in Get-PSDrive -PSProvider FileSystem) {
        foreach ($baseRelative in @("vivado", "Xilinx\Vivado")) {
            $base = Join-Path $drive.Root $baseRelative
            if (Test-Path -LiteralPath $base) {
                foreach ($versionDir in Get-ChildItem -LiteralPath $base -Directory -ErrorAction SilentlyContinue) {
                    $candidates.Add((Join-Path $versionDir.FullName "Vivado\bin"))
                    $candidates.Add((Join-Path $versionDir.FullName "bin"))
                }
            }
        }
    }

    foreach ($candidate in $candidates) {
        if ($candidate -and
            (Test-Path -LiteralPath (Join-Path $candidate "xvlog.bat")) -and
            (Test-Path -LiteralPath (Join-Path $candidate "xelab.bat")) -and
            (Test-Path -LiteralPath (Join-Path $candidate "xsim.bat"))) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    throw "Vivado simulator tools were not found. Pass -VivadoBin <Vivado/bin>."
}

function Find-LicenseFile {
    param([string]$RequestedPath)

    $candidates = New-Object System.Collections.Generic.List[string]
    if ($RequestedPath) { $candidates.Add($RequestedPath) }
    if ($env:APPDATA) { $candidates.Add((Join-Path $env:APPDATA "XilinxLicense\Xilinx.lic")) }
    if ($env:USERPROFILE) { $candidates.Add((Join-Path $env:USERPROFILE ".Xilinx\Xilinx.lic")) }

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }
    return ""
}

function Invoke-LoggedTool {
    param(
        [string]$Executable,
        [string[]]$Arguments,
        [string]$LogPath,
        [string]$Stage
    )

    Add-Content -LiteralPath $LogPath -Value "`r`n--- $Stage ---"
    $previousPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = "Continue"
        $output = & $Executable @Arguments 2>&1 | Out-String
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousPreference
    }
    Add-Content -LiteralPath $LogPath -Value $output
    return [pscustomobject]@{ ExitCode = $exitCode; Output = $output }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$designRoot = (Resolve-Path -LiteralPath (Join-Path $scriptDir "..\..")).Path
$vivadoBinResolved = Find-VivadoBin -RequestedPath $VivadoBin

if (-not $env:XILINXD_LICENSE_FILE) {
    $detectedLicense = Find-LicenseFile -RequestedPath $LicenseFile
    if ($detectedLicense) { $env:XILINXD_LICENSE_FILE = $detectedLicense }
}

$xvlog = Join-Path $vivadoBinResolved "xvlog.bat"
$xelab = Join-Path $vivadoBinResolved "xelab.bat"
$xsim = Join-Path $vivadoBinResolved "xsim.bat"
$runTcl = (Resolve-Path -LiteralPath (Join-Path $scriptDir "run_test.tcl")).Path.Replace('\', '/')
$buildRoot = [IO.Path]::GetFullPath((Join-Path $designRoot "sim\build"))
$expectedPrefix = $designRoot.TrimEnd('\') + "\sim\build"

if (-not $buildRoot.StartsWith($expectedPrefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to clean unexpected build path: $buildRoot"
}
if (Test-Path -LiteralPath $buildRoot) {
    Remove-Item -LiteralPath $buildRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $buildRoot -Force | Out-Null

$reportDir = Join-Path $designRoot "reports\simulation"
New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
$rtlFiles = Get-ChildItem -LiteralPath (Join-Path $designRoot "rtl") -Filter "*.v" -Recurse |
    Sort-Object FullName | ForEach-Object { $_.FullName }
$tests = @(
    "tb_alu",
    "tb_controller",
    "tb_register_file",
    "tb_program_counter",
    "tb_next_pc_mux",
    "tb_status_register",
    "tb_zero_extender_8_to_16",
    "tb_alu_operand_mux",
    "tb_writeback_mux",
    "tb_datapath",
    "tb_cpu_core"
)

if ($IncludeBoard) {
    $tests += @(
        "tb_hex_to_7seg",
        "tb_io_interconnect",
        "tb_seven_segment8",
        "tb_board_top_smoke",
        "tb_board_isa_test",
        "tb_board_led_chaser"
    )
}

$statuses = New-Object System.Collections.Generic.List[string]
$failureCount = 0

foreach ($test in $tests) {
    $testBuild = Join-Path $buildRoot $test
    New-Item -ItemType Directory -Path $testBuild -Force | Out-Null
    if ($test -eq "tb_cpu_core") {
        Copy-Item -LiteralPath (Join-Path $designRoot "sim\programs\system_demo.mem") `
                  -Destination (Join-Path $testBuild "system_demo.mem") -Force
    }
    if ($test -eq "tb_board_top_smoke") {
        Copy-Item -LiteralPath (Join-Path $designRoot "sim\programs\board_demo.mem") `
                  -Destination (Join-Path $testBuild "board_demo.mem") -Force
    }
    if ($test -eq "tb_board_isa_test") {
        Copy-Item -LiteralPath (Join-Path $designRoot "sim\programs\board_isa_test.mem") `
                  -Destination (Join-Path $testBuild "board_isa_test.mem") -Force
    }
    if ($test -eq "tb_board_led_chaser") {
        Copy-Item -LiteralPath (Join-Path $designRoot "sim\programs\board_led_chaser.mem") `
                  -Destination (Join-Path $testBuild "board_led_chaser.mem") -Force
    }

    $logPath = Join-Path $reportDir "$test.log"
    Set-Content -LiteralPath $logPath -Encoding UTF8 -Value @(
        "MiniRISC-16 refactored CPU test: $test",
        "Timestamp: $([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss zzz'))",
        "Vivado bin: $vivadoBinResolved"
    )

    $testFailed = $false
    $reason = ""
    Push-Location $testBuild
    try {
        $testbenchFile = Join-Path $designRoot "sim\tb\$test.v"
        $compile = Invoke-LoggedTool -Executable $xvlog -Arguments (@($rtlFiles) + @($testbenchFile)) `
            -LogPath $logPath -Stage "xvlog"
        if ($compile.ExitCode -ne 0) { throw "xvlog returned $($compile.ExitCode)" }

        $snapshot = "${test}_sim"
        $elaborate = Invoke-LoggedTool -Executable $xelab `
            -Arguments @($test, "-debug", "typical", "-mt", "off", "-s", $snapshot) `
            -LogPath $logPath -Stage "xelab"
        if ($elaborate.ExitCode -ne 0) { throw "xelab returned $($elaborate.ExitCode)" }

        $vcdPath = (Join-Path $reportDir "$test.vcd").Replace('\', '/')
        $wdbPath = (Join-Path $reportDir "$test.wdb").Replace('\', '/')
        $env:MINIRISC_VCD = $vcdPath
        $simulate = Invoke-LoggedTool -Executable $xsim `
            -Arguments @($snapshot, "-wdb", $wdbPath, "-tclbatch", $runTcl) `
            -LogPath $logPath -Stage "xsim"
        if ($simulate.ExitCode -ne 0) { throw "xsim returned $($simulate.ExitCode)" }
        if ($simulate.Output -notmatch [regex]::Escape("${test}: TEST PASS")) {
            throw "unique TEST PASS marker was not found"
        }
        if ($simulate.Output -match "TEST FAIL|ERROR tb_") {
            throw "failure marker was found"
        }
    } catch {
        $testFailed = $true
        $reason = $_.Exception.Message
        $failureCount = $failureCount + 1
        Add-Content -LiteralPath $logPath -Value "`r`nRUNNER FAILURE: $reason"
    } finally {
        Remove-Item Env:MINIRISC_VCD -ErrorAction SilentlyContinue
        Pop-Location
    }

    if ($testFailed) {
        $statuses.Add("FAIL $test - $reason")
    } else {
        $statuses.Add("PASS $test")
    }
}

$summaryPath = Join-Path $reportDir "regression-summary.txt"
$summary = @(
    "MiniRISC-16 refactored regression",
    "Timestamp: $([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss zzz'))",
    "Tests: $($tests.Count)",
    "Failures: $failureCount",
    ""
) + $statuses
Set-Content -LiteralPath $summaryPath -Encoding UTF8 -Value $summary
$summary | ForEach-Object { Write-Output $_ }

if ($failureCount -ne 0) { exit 1 }
