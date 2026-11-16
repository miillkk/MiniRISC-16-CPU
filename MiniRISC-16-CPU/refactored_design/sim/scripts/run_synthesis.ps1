param(
    [string]$VivadoBin = "",
    [string]$LicenseFile = "",
    [ValidateSet("Synthesis", "Project", "BoardSynthesis", "BoardProject", "BoardBitstream", "BoardIsaProject", "BoardIsaBitstream", "BoardLedProject", "BoardLedBitstream")]
    [string]$Task = "Synthesis"
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$designRoot = (Resolve-Path -LiteralPath (Join-Path $scriptDir "..\..")).Path

function Find-LicenseFile {
    param([string]$RequestedPath)

    $licenseCandidates = New-Object System.Collections.Generic.List[string]
    if ($RequestedPath) { $licenseCandidates.Add($RequestedPath) }
    if ($env:APPDATA) { $licenseCandidates.Add((Join-Path $env:APPDATA "XilinxLicense\Xilinx.lic")) }
    if ($env:USERPROFILE) { $licenseCandidates.Add((Join-Path $env:USERPROFILE ".Xilinx\Xilinx.lic")) }

    foreach ($licenseCandidate in $licenseCandidates) {
        if ($licenseCandidate -and (Test-Path -LiteralPath $licenseCandidate)) {
            return (Resolve-Path -LiteralPath $licenseCandidate).Path
        }
    }
    return ""
}

if (-not $env:XILINXD_LICENSE_FILE) {
    $detectedLicense = Find-LicenseFile -RequestedPath $LicenseFile
    if ($detectedLicense) { $env:XILINXD_LICENSE_FILE = $detectedLicense }
}

$candidates = New-Object System.Collections.Generic.List[string]
if ($VivadoBin) { $candidates.Add($VivadoBin) }
if ($env:VIVADO_BIN) { $candidates.Add($env:VIVADO_BIN) }
if ($env:XILINX_VIVADO) { $candidates.Add((Join-Path $env:XILINX_VIVADO "bin")) }
$pathCommand = Get-Command "vivado.bat" -ErrorAction SilentlyContinue
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

$vivado = ""
foreach ($candidate in $candidates) {
    $candidateExe = Join-Path $candidate "vivado.bat"
    if (Test-Path -LiteralPath $candidateExe) {
        $vivado = (Resolve-Path -LiteralPath $candidateExe).Path
        break
    }
}
if (-not $vivado) { throw "Vivado was not found. Pass -VivadoBin <Vivado/bin>." }

$previousTclAppRepo = $env:XILINX_TCLAPP_REPO
$previousTclLibPath = $env:TCLLIBPATH
$vivadoRoot = Split-Path -Parent (Split-Path -Parent $vivado)
$bundledTclStore = Join-Path $vivadoRoot "data\XilinxTclStore"
if (Test-Path -LiteralPath $bundledTclStore) {
    if (-not $env:XILINX_TCLAPP_REPO) {
        $env:XILINX_TCLAPP_REPO = $bundledTclStore.Replace('\', '/')
    }
    $packageDirectories = Get-ChildItem -LiteralPath $bundledTclStore -Filter "pkgIndex.tcl" -Recurse |
        ForEach-Object { $_.Directory.FullName.Replace('\', '/') } | Sort-Object -Unique
    $bundledTclLibPath = $packageDirectories -join ' '
    if ($env:TCLLIBPATH) {
        $env:TCLLIBPATH = "$($env:TCLLIBPATH) $bundledTclLibPath"
    } else {
        $env:TCLLIBPATH = $bundledTclLibPath
    }
}

$taskConfiguration = @{
    Synthesis     = @("run_synthesis.tcl", "vivado-synthesis", "SYNTHESIS PASS")
    Project       = @("create_vivado_project.tcl", "vivado-project-creation", "PROJECT CREATED")
    BoardSynthesis = @("run_board_synthesis.tcl", "board-synthesis", "BOARD SYNTHESIS PASS")
    BoardProject   = @("create_board_project.tcl", "board-project-creation", "BOARD PROJECT CREATED")
    BoardBitstream = @("build_board_bitstream.tcl", "board-bitstream", "BOARD BITSTREAM PASS")
    BoardIsaProject = @("create_board_isa_project.tcl", "board-isa-project-creation", "BOARD ISA PROJECT CREATED")
    BoardIsaBitstream = @("build_board_isa_bitstream.tcl", "board-isa-bitstream", "BOARD ISA BITSTREAM PASS")
    BoardLedProject = @("create_board_led_project.tcl", "board-led-project-creation", "BOARD LED PROJECT CREATED")
    BoardLedBitstream = @("build_board_led_bitstream.tcl", "board-led-bitstream", "BOARD LED BITSTREAM PASS")
}
$tclName = $taskConfiguration[$Task][0]
$outputBase = $taskConfiguration[$Task][1]
$successMarker = $taskConfiguration[$Task][2]
$tclPath = (Resolve-Path -LiteralPath (Join-Path $scriptDir $tclName)).Path.Replace('\', '/')
$reportSubdirectory = if ($Task -like "BoardIsa*") {
    "reports\board_isa"
} elseif ($Task -like "BoardLed*") {
    "reports\board_led"
} elseif ($Task -like "Board*") {
    "reports\board"
} else {
    "reports\synthesis"
}
$logPath = (Join-Path $designRoot "$reportSubdirectory\$outputBase.log").Replace('\', '/')
$journalPath = (Join-Path $designRoot "$reportSubdirectory\$outputBase.jou").Replace('\', '/')
$reportPath = Split-Path -Parent $logPath
New-Item -ItemType Directory -Path $reportPath -Force | Out-Null
$env:MINIRISC_REFACTORED_ROOT = $designRoot.Replace('\', '/')
& $vivado -mode batch -source $tclPath -log $logPath -journal $journalPath
$vivadoExitCode = $LASTEXITCODE
Remove-Item Env:MINIRISC_REFACTORED_ROOT -ErrorAction SilentlyContinue
if ($null -eq $previousTclAppRepo) {
    Remove-Item Env:XILINX_TCLAPP_REPO -ErrorAction SilentlyContinue
} else {
    $env:XILINX_TCLAPP_REPO = $previousTclAppRepo
}
if ($null -eq $previousTclLibPath) {
    Remove-Item Env:TCLLIBPATH -ErrorAction SilentlyContinue
} else {
    $env:TCLLIBPATH = $previousTclLibPath
}
if ($vivadoExitCode -ne 0) { exit $vivadoExitCode }

$log = Get-Content -LiteralPath $logPath -Raw
if ($log -notmatch [regex]::Escape($successMarker)) { throw "$Task completion marker was not found." }
Write-Output $successMarker
