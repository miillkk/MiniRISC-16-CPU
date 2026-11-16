param([switch]$Apply)

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')).TrimEnd('\')
$manifestDir = Join-Path $root 'maintenance'
$stamp = '2026-11-16'
$actions = [Collections.Generic.List[object]]::new()

function Assert-WorkspacePath([string]$path) {
    $full = [IO.Path]::GetFullPath($path)
    if (-not $full.StartsWith($root + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw "Path outside workspace: $full"
    }
    return $full
}

function Add-Action([string]$kind, [string]$source, [string]$destination, [string]$reason) {
    $actions.Add([pscustomobject]@{Kind=$kind; Source=$source; Destination=$destination; Reason=$reason})
}

function Move-Safe([string]$source, [string]$destination, [string]$reason) {
    $src = Assert-WorkspacePath (Join-Path $root $source)
    $dst = Assert-WorkspacePath (Join-Path $root $destination)
    if (-not (Test-Path -LiteralPath $src)) { throw "Missing source: $src" }
    if (Test-Path -LiteralPath $dst) { throw "Destination already exists: $dst" }
    Add-Action 'Move' $source $destination $reason
    if ($Apply) {
        $parent = Split-Path -Parent $dst
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
        Move-Item -LiteralPath $src -Destination $dst
    }
}

function Remove-Safe([string]$source, [string]$reason) {
    $src = Assert-WorkspacePath (Join-Path $root $source)
    if (-not (Test-Path -LiteralPath $src)) { return }
    Add-Action 'Delete' $source '' $reason
    if ($Apply) { Remove-Item -LiteralPath $src -Recurse -Force }
}

function Get-Inventory {
    Get-ChildItem -LiteralPath $root -Recurse -Force -File | Where-Object {
        $_.FullName -notlike (Join-Path $root 'maintenance\inventory_*') -and
        $_.FullName -notlike (Join-Path $root 'maintenance\actions_*')
    } | ForEach-Object {
        [pscustomobject]@{Path=$_.FullName.Substring($root.Length+1); Bytes=$_.Length; Modified=$_.LastWriteTimeUtc.ToString('o')}
    }
}

if ($Apply) {
    Get-Inventory | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath (Join-Path $manifestDir "inventory_before_$stamp.csv")
}

# Delete only recognized, reproducible work products. Every recursive target is
# resolved and constrained to this workspace before removal.
$cacheNames = @('.Xil','xsim.dir','sim_build','build','cycle_wave_build')
$cacheDirs = @(Get-ChildItem -LiteralPath $root -Recurse -Force -Directory | Where-Object {
    $_.Name -in $cacheNames -or $_.Name -like 'sim_build_cache_before_*'
})
$topCacheDirs = @($cacheDirs | Where-Object {
    $candidate = $_.FullName
    -not @($cacheDirs | Where-Object {
        $_.FullName -ne $candidate -and $candidate.StartsWith($_.FullName + '\', [StringComparison]::OrdinalIgnoreCase)
    }).Count
})
foreach ($dir in $topCacheDirs) {
    Remove-Safe $dir.FullName.Substring($root.Length+1) 'Regenerable Vivado or XSim work directory'
}

$looseNames = @('vivado.jou','vivado.log','xelab.pb','xlicdiag.rpt','xvlog.log','xvlog.pb')
foreach ($name in $looseNames) { Remove-Safe $name 'Top-level tool output' }
foreach ($file in @(Get-ChildItem -LiteralPath (Join-Path $root 'MiniRISC-16-CPU-main') -File -Force | Where-Object {
    $_.Name -match '^vivado.*\.(log|jou|str)$'
})) { Remove-Safe $file.FullName.Substring($root.Length+1) 'Historical Vivado log' }
foreach ($system in @('runtime_system','hdmi_snake_system')) {
    $systemRoot = Join-Path $root "MiniRISC-16-CPU\refactored_design\$system"
    foreach ($file in @(Get-ChildItem -LiteralPath $systemRoot -File -Force | Where-Object {
        $_.Name -match '^hs_err_pid\d+\.(log|dmp)$'
    })) { Remove-Safe $file.FullName.Substring($root.Length+1) 'JVM crash dump' }
}
Remove-Safe '-p' 'Empty accidental directory'
Remove-Safe 'MiniRISC-16-CPU\refactored_design\hdmi_snake_system\-p' 'Empty accidental directory'

# Preserve the main Git working tree and all application paths.
$moves = @(
    @('MiniRISC-16-CPU-main','archive\legacy\MiniRISC-16-CPU-main','Early extracted project snapshot'),
    @('MiniRISC-16-CPU-main.zip','archive\legacy\MiniRISC-16-CPU-main.zip','Distinct early snapshot'),
    @('MiniRISC-16-CPU-main (2).zip','archive\legacy\MiniRISC-16-CPU-main (2).zip','Distinct later snapshot'),
    @('MiniRISC-16-CPU\refactored_design.zip','archive\legacy\refactored_design.zip','Historical refactored snapshot'),
    @('MiniRISC-16-CPU\refactored_design (2).zip','archive\legacy\refactored_design (2).zip','Historical refactored snapshot'),
    @('HDMI_TEST_HANDOFF_2026-11-05','archive\legacy\HDMI_TEST_HANDOFF_2026-11-05','SHA-256-identical extracted handoff copy'),
    @('HDMI_TEST_HANDOFF_2026-11-05.zip','deliverables\handoffs\HDMI_TEST_HANDOFF_2026-11-05.zip','Portable HDMI handoff'),
    @('deliverables\MiniRISC16_Current_Runtime_Report_2026-11-05','deliverables\handoffs\MiniRISC16_Current_Runtime_Report_2026-11-05','Extracted Runtime handoff'),
    @('deliverables\MiniRISC16_Current_Runtime_Report_2026-11-05.zip','deliverables\handoffs\MiniRISC16_Current_Runtime_Report_2026-11-05.zip','Portable Runtime handoff'),
    @('deliverables\MiniRISC16_Current_Runtime_Report_2026-11-05.zip.sha256','deliverables\handoffs\MiniRISC16_Current_Runtime_Report_2026-11-05.zip.sha256','Handoff checksum'),
    @('deliverables\report_compare_2026-11-11','archive\authoring\report_compare_2026-11-11','Report comparison intermediates'),
    @('deliverables\report_template_work','archive\authoring\report_template_work','Report source scripts and renders'),
    @('.codex-ppt-build','archive\authoring\codex-ppt-build','Presentation source scripts and previews'),
    @('tmp','archive\authoring\tmp','Reference images and temporary material'),
    @('README.md','archive\README_workspace_2026-10-23.md','Historical workspace overview')
)
foreach ($move in $moves) { Move-Safe $move[0] $move[1] $move[2] }

$reportNames = @(
    'MiniRISC16_Current_Runtime_Design_Report_2026-11-05.docx',
    'MiniRISC16_PC8_Design_and_Verification_Report_2026-11-05.docx',
    'MiniRISC16_PC8_Design_and_Verification_Report_Board_Expanded_2026-11-11.docx',
    'MiniRISC16_PC8_Design_and_Verification_Report_Board_Expanded_2026-11-11.pdf',
    'MiniRISC16_PC8_Design_and_Verification_Report_Board_Results_2026-11-11.docx',
    'MiniRISC16_PC8_Design_and_Verification_Report_Board_Results_2026-11-11.pdf'
)
foreach ($name in $reportNames) { Move-Safe "deliverables\$name" "deliverables\reports\$name" 'Final report' }

$currentPresentationNames = @(
    '上板展示_三项目_9页图文版_v6.pptx',
    'MiniRISC16_设计与验证答辩稿_v2.pptx',
    'On_Board_Demo_English_6_Slides_v1.pptx',
    '上板展示_开场与UART_中英对照讲稿.md',
    '上板展示_详细讲稿_v1.md',
    'MiniRISC16_答辩详细讲解稿.md'
)
foreach ($name in $currentPresentationNames) { Move-Safe "deliverables\$name" "deliverables\presentations\$name" 'Presentation or speaking notes' }
$draftPresentationNames = @(
    '上板展示_三项目_10分钟版_v3.pptx',
    '上板展示_三项目_紧凑版_v4.pptx',
    '上板展示_三项目_图文合页_v5.pptx',
    'MiniRISC16_LED_Calculator_Demo_v1.pptx',
    'MiniRISC16_Runtime_三项目展示_简版_v1.pptx',
    'MiniRISC16_Runtime_三项目展示_详细版_v2.pptx'
)
foreach ($name in $draftPresentationNames) { Move-Safe "deliverables\$name" "archive\presentation_drafts\$name" 'Earlier presentation variant' }
Remove-Safe 'deliverables\~$niRISC16_PC8_Design_and_Verification_Report_2026-11-05.docx' 'Word owner lock file'

if ($Apply) {
    $actions | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath (Join-Path $manifestDir "actions_$stamp.csv")
    Get-Inventory | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath (Join-Path $manifestDir "inventory_after_$stamp.csv")
}
$actions | Group-Object Kind | Select-Object Name,Count | Format-Table -AutoSize
if (-not $Apply) { Write-Output 'Dry run only; pass -Apply to execute.' }
