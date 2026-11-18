param([switch]$Apply)

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')).TrimEnd('\')
$targets = [Collections.Generic.List[object]]::new()

function Add-Target([string]$path, [string]$reason) {
    $full = [IO.Path]::GetFullPath($path)
    if (-not $full.StartsWith($root + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw "Outside workspace: $full"
    }
    if ($full -match '(?i)\\\.git(_local_backup)?\\') {
        throw "Git metadata target: $full"
    }
    if (-not (Test-Path -LiteralPath $full)) { return }
    $item = Get-Item -LiteralPath $full -Force
    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw "Reparse point target: $full"
    }
    if ($item.PSIsContainer) {
        $nestedLinks = @(Get-ChildItem -LiteralPath $full -Recurse -Force -Attributes ReparsePoint -ErrorAction SilentlyContinue)
        if ($nestedLinks.Count) { throw "Reparse point inside target: $full" }
        $files = @(Get-ChildItem -LiteralPath $full -Recurse -Force -File)
    } else {
        $files = @($item)
    }
    $bytes = ($files | Measure-Object Length -Sum).Sum
    $targets.Add([pscustomobject]@{
        Path = $full.Substring($root.Length + 1)
        Type = if ($item.PSIsContainer) { 'Directory' } else { 'File' }
        Files = $files.Count
        Bytes = [long]$bytes
        Reason = $reason
    })
}

# These Vivado project folders contain only generated cache, hardware-manager,
# and simulation state. XPR, .srcs, checkpoints, reports, and bitstreams remain.
foreach ($parent in @(
    (Join-Path $root 'MiniRISC-16-CPU\refactored_design'),
    (Join-Path $root 'archive\legacy\MiniRISC-16-CPU-main')
)) {
    Get-ChildItem -LiteralPath $parent -Recurse -Force -Directory |
        Where-Object { $_.Name -match '\.(cache|hw|sim)$' } |
        ForEach-Object { Add-Target $_.FullName 'Regenerable Vivado project state' }
}

$reportWork = Join-Path $root 'archive\authoring\report_template_work'
Get-ChildItem -LiteralPath $reportWork -Force -Directory |
    Where-Object { $_.Name -match 'render|preview' } |
    ForEach-Object { Add-Target $_.FullName 'Report rendering preview' }

$compareWork = Join-Path $root 'archive\authoring\report_compare_2026-11-11'
Get-ChildItem -LiteralPath $compareWork -Force -Directory |
    Where-Object { $_.Name -in @('a_render','restructured_render','user_render') } |
    ForEach-Object { Add-Target $_.FullName 'Report comparison rendering preview' }

$pptWork = Join-Path $root 'archive\authoring\codex-ppt-build'
Get-ChildItem -LiteralPath $pptWork -Force -Directory | ForEach-Object {
    $preview = Join-Path $_.FullName 'preview'
    if (Test-Path -LiteralPath $preview -PathType Container) {
        Add-Target $preview 'Presentation rendering preview'
    }
}

$bugRoot = Join-Path $root 'MiniRISC-16-CPU\refactored_design'
Get-ChildItem -LiteralPath $bugRoot -Recurse -Force -File -Filter '*.dmp' |
    Where-Object { $_.Name -match '^hs_err_pid\d+\.dmp$' -or $_.Name -match '-hs_err_pid\d+\.dmp$' } |
    ForEach-Object { Add-Target $_.FullName 'JVM crash dump; text bug logs retained' }

if ($targets.Count -eq 0) {
    Write-Output 'No matching artifacts; existing audit manifest retained.'
    return
}

$manifest = Join-Path $PSScriptRoot 'process_artifacts_2026-11-18.csv'
$targets | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath $manifest
$totals = [pscustomobject]@{
    Targets = $targets.Count
    Files = ($targets | Measure-Object Files -Sum).Sum
    MB = [math]::Round((($targets | Measure-Object Bytes -Sum).Sum / 1MB), 2)
    Mode = if ($Apply) { 'Apply' } else { 'Dry run' }
}
$totals | Format-List

if ($Apply) {
    foreach ($target in $targets) {
        $full = [IO.Path]::GetFullPath((Join-Path $root $target.Path))
        if (-not $full.StartsWith($root + '\', [StringComparison]::OrdinalIgnoreCase)) {
            throw "Outside workspace at delete time: $full"
        }
        Remove-Item -LiteralPath $full -Recurse -Force
    }
}
