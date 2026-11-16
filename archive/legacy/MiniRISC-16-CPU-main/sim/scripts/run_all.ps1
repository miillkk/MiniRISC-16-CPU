param(
    [string]$VivadoBin = "",
    [string]$LicenseFile = ""
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

function Invoke-LoggedTool {
    param(
        [string]$Executable,
        [string[]]$Arguments,
        [string]$LogPath,
        [string]$Stage
    )

    Add-Content -LiteralPath $LogPath -Value "`r`n--- $Stage ---"
    $previousErrorPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = "Continue"
        $output = & $Executable @Arguments 2>&1 | Out-String
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorPreference
    }
    Add-Content -LiteralPath $LogPath -Value $output
    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = $output
    }
}

function Convert-ToTclPath {
    param([string]$Path)

    return $Path.Replace('\', '/')
}

function Find-XilinxLicenseFile {
    param([string]$RequestedPath)

    $candidates = New-Object System.Collections.Generic.List[string]
    if ($RequestedPath) { $candidates.Add($RequestedPath) }
    if ($env:APPDATA) { $candidates.Add((Join-Path $env:APPDATA "XilinxLicense\Xilinx.lic")) }
    if ($env:USERPROFILE) {
        $candidates.Add((Join-Path $env:USERPROFILE ".Xilinx\Xilinx.lic"))
        $candidates.Add((Join-Path $env:USERPROFILE "Desktop\Xilinx.lic"))
        $candidates.Add((Join-Path $env:USERPROFILE "Downloads\Xilinx.lic"))
    }

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    return ""
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = (Resolve-Path -LiteralPath (Join-Path $scriptDir "..\..")).Path
$detectedLicenseFile = ""
if (-not $env:XILINXD_LICENSE_FILE) {
    $detectedLicenseFile = Find-XilinxLicenseFile -RequestedPath $LicenseFile
    if ($detectedLicenseFile) {
        $env:XILINXD_LICENSE_FILE = $detectedLicenseFile
    }
} elseif ($LicenseFile) {
    $detectedLicenseFile = (Resolve-Path -LiteralPath $LicenseFile).Path
    $env:XILINXD_LICENSE_FILE = $detectedLicenseFile
}
$vivadoBinResolved = Find-VivadoBin -RequestedPath $VivadoBin
$xvlog = Join-Path $vivadoBinResolved "xvlog.bat"
$xelab = Join-Path $vivadoBinResolved "xelab.bat"
$xsim = Join-Path $vivadoBinResolved "xsim.bat"
$xsimTcl = Join-Path $scriptDir "xsim_run.tcl"
$xsimTclArg = Convert-ToTclPath $xsimTcl
$buildRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot "sim\build"))
$expectedBuildPrefix = $projectRoot.TrimEnd('\') + "\sim\build"

if (-not $buildRoot.StartsWith($expectedBuildPrefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to clean unexpected build path: $buildRoot"
}
if (Test-Path -LiteralPath $buildRoot) {
    Remove-Item -LiteralPath $buildRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $buildRoot -Force | Out-Null

$reportDir = Join-Path $projectRoot "reports\simulation"
$waveDir = Join-Path $projectRoot "reports\waveforms"
New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
New-Item -ItemType Directory -Path $waveDir -Force | Out-Null
$waveArtifactNames = @(
    "system.vcd", "system.wcfg",
    "01_single_cycle_commit.svg", "01_single_cycle_commit.png",
    "02_cmp_jz_jump.svg", "02_cmp_jz_jump.png",
    "03_registers_alu.svg", "03_registers_alu.png",
    "04_gpio_io.svg", "04_gpio_io.png"
)
foreach ($artifactName in $waveArtifactNames) {
    $artifactPath = Join-Path $waveDir $artifactName
    if (Test-Path -LiteralPath $artifactPath) {
        Remove-Item -LiteralPath $artifactPath -Force
    }
}

$rtlFiles = Get-ChildItem -LiteralPath (Join-Path $projectRoot "rtl") -Filter "*.v" -Recurse |
    Sort-Object FullName | ForEach-Object { $_.FullName }
$tests = @("tb_alu", "tb_controller", "tb_datapath", "tb_reset_conditioner", "tb_gpio8", "tb_system")
$statuses = New-Object System.Collections.Generic.List[string]
$failureCount = 0

foreach ($test in $tests) {
    $testBuild = Join-Path $buildRoot $test
    New-Item -ItemType Directory -Path $testBuild -Force | Out-Null
    if ($test -eq "tb_system") {
        Copy-Item -LiteralPath (Join-Path $projectRoot "sim\programs\system_demo.mem") `
                  -Destination (Join-Path $testBuild "system_demo.mem") -Force
    }

    $logPath = Join-Path $reportDir "$test.txt"
    Set-Content -LiteralPath $logPath -Encoding UTF8 -Value @(
        "MiniRISC-16 regression test: $test",
        "Timestamp: $([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss zzz'))",
        "Vivado bin: $vivadoBinResolved",
        "XILINXD_LICENSE_FILE: $env:XILINXD_LICENSE_FILE"
    )

    $testFailed = $false
    $failureReason = ""
    Push-Location $testBuild
    try {
        $testbenchFile = Join-Path $projectRoot "sim\tb\$test.v"
        $compileArgs = @($rtlFiles) + @($testbenchFile)
        $compileResult = Invoke-LoggedTool -Executable $xvlog -Arguments $compileArgs `
            -LogPath $logPath -Stage "xvlog"
        if ($compileResult.ExitCode -ne 0) {
            throw "xvlog returned $($compileResult.ExitCode)"
        }

        $snapshot = "${test}_sim"
        $elaborateResult = Invoke-LoggedTool -Executable $xelab `
            -Arguments @($test, "-debug", "typical", "-s", $snapshot) `
            -LogPath $logPath -Stage "xelab"
        if ($elaborateResult.ExitCode -ne 0) {
            throw "xelab returned $($elaborateResult.ExitCode)"
        }

        $oldVcd = $env:MINIRISC_VCD
        $oldWcfg = $env:MINIRISC_WCFG
        if ($test -eq "tb_system") {
            $env:MINIRISC_VCD = Convert-ToTclPath (Join-Path $waveDir "system.vcd")
            $env:MINIRISC_WCFG = Convert-ToTclPath (Join-Path $waveDir "system.wcfg")
        } else {
            $env:MINIRISC_VCD = ""
            $env:MINIRISC_WCFG = ""
        }

        try {
            $simulateResult = Invoke-LoggedTool -Executable $xsim `
                -Arguments @($snapshot, "-tclbatch", $xsimTclArg) `
                -LogPath $logPath -Stage "xsim"
        } finally {
            $env:MINIRISC_VCD = $oldVcd
            $env:MINIRISC_WCFG = $oldWcfg
        }

        $passMarker = "${test}: TEST PASS"
        if ($simulateResult.ExitCode -ne 0) {
            throw "xsim returned $($simulateResult.ExitCode)"
        }
        if ($simulateResult.Output -match "Could not obtain the necessary license") {
            throw "XSim could not obtain a Simulator license"
        }
        if ($simulateResult.Output -notmatch [Regex]::Escape($passMarker)) {
            throw "the self-checking test did not emit '$passMarker'"
        }
        if ($simulateResult.Output -match "TEST FAIL|ERROR tb_") {
            throw "the simulation log contains a self-check failure"
        }

        if ($test -eq "tb_system") {
            if (-not (Test-Path -LiteralPath (Join-Path $waveDir "system.vcd"))) {
                throw "system VCD was not generated"
            }
            if (-not (Test-Path -LiteralPath (Join-Path $waveDir "system.wcfg"))) {
                throw "system WCFG was not generated"
            }
        }
    } catch {
        $testFailed = $true
        $failureReason = $_.Exception.Message
        Add-Content -LiteralPath $logPath -Value "`r`nRESULT: FAIL - $failureReason"
    } finally {
        Pop-Location
    }

    if ($testFailed) {
        $failureCount = $failureCount + 1
        $statuses.Add("$test : FAIL - $failureReason")
    } else {
        Add-Content -LiteralPath $logPath -Value "`r`nRESULT: PASS"
        $statuses.Add("$test : PASS")
    }
}

if ($failureCount -eq 0) {
    $renderLogPath = Join-Path $reportDir "waveform-render.txt"
    $renderScript = Join-Path $scriptDir "render_waveforms.ps1"
    $renderOutput = & powershell -ExecutionPolicy Bypass -File $renderScript 2>&1 | Out-String
    $renderExitCode = $LASTEXITCODE
    Set-Content -LiteralPath $renderLogPath -Encoding UTF8 -Value $renderOutput
    if ($renderExitCode -ne 0) {
        $failureCount = $failureCount + 1
        $statuses.Add("waveform-render : FAIL - renderer returned $renderExitCode")
    } else {
        $statuses.Add("waveform-render : PASS")
    }
}

$summaryPath = Join-Path $reportDir "regression-summary.txt"
$summary = @(
    "MiniRISC-16 Vivado XSim regression",
    "Timestamp: $([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss zzz'))",
    "Vivado bin: $vivadoBinResolved",
    "XILINXD_LICENSE_FILE: $env:XILINXD_LICENSE_FILE",
    ""
) + $statuses + @("", "Failures: $failureCount")
Set-Content -LiteralPath $summaryPath -Encoding UTF8 -Value $summary

$statuses | ForEach-Object { Write-Host $_ }
Write-Host "Summary: $summaryPath"
if ($failureCount -ne 0) {
    throw "Regression failed: $failureCount test(s) did not pass."
}
