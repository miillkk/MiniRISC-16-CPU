$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')).TrimEnd('\')
$pairs = @(
    @('archive\legacy\MiniRISC-16-CPU-main.zip','archive\legacy\MiniRISC-16-CPU-main','MiniRISC-16-CPU-main/'),
    @('archive\legacy\MiniRISC-16-CPU-main (2).zip','archive\legacy\MiniRISC-16-CPU-main','MiniRISC-16-CPU-main/'),
    @('archive\legacy\refactored_design.zip','MiniRISC-16-CPU\refactored_design','refactored_design/'),
    @('archive\legacy\refactored_design (2).zip','MiniRISC-16-CPU\refactored_design','refactored_design/'),
    @('deliverables\handoffs\HDMI_TEST_HANDOFF_2026-11-05.zip','archive\legacy\HDMI_TEST_HANDOFF_2026-11-05','HDMI_TEST_HANDOFF_2026-11-05/'),
    @('deliverables\handoffs\MiniRISC16_Current_Runtime_Report_2026-11-05.zip','deliverables\handoffs\MiniRISC16_Current_Runtime_Report_2026-11-05','MiniRISC16_Current_Runtime_Report_2026-11-05/')
)
$results = foreach ($pair in $pairs) {
    $zipPath = Join-Path $root $pair[0]
    $folderPath = Join-Path $root $pair[1]
    $prefix = $pair[2]
    $archive = [IO.Compression.ZipFile]::OpenRead($zipPath)
    try {
        $total=0; $matched=0; $missing=0; $different=0
        $examples=[Collections.Generic.List[string]]::new()
        foreach ($entry in $archive.Entries) {
            if ($entry.Name -eq '') { continue }
            $total++
            if (-not $entry.FullName.StartsWith($prefix,[StringComparison]::Ordinal)) {
                $missing++; if ($examples.Count -lt 5) {$examples.Add("unexpected path: $($entry.FullName)")}; continue
            }
            $relative=$entry.FullName.Substring($prefix.Length).Replace('/','\')
            $filePath=Join-Path $folderPath $relative
            if (-not (Test-Path -LiteralPath $filePath -PathType Leaf)) {
                $missing++; if ($examples.Count -lt 5) {$examples.Add("missing: $relative")}; continue
            }
            if ((Get-Item -LiteralPath $filePath).Length -ne $entry.Length) {
                $different++; if ($examples.Count -lt 5) {$examples.Add("size differs: $relative")}; continue
            }
            $stream=$entry.Open()
            try {
                $sha=[Security.Cryptography.SHA256]::Create()
                $zipHash=[Convert]::ToHexString($sha.ComputeHash($stream))
            } finally { $stream.Dispose(); $sha.Dispose() }
            $fileHash=(Get-FileHash -LiteralPath $filePath -Algorithm SHA256).Hash
            if ($zipHash -eq $fileHash) { $matched++ }
            else { $different++; if ($examples.Count -lt 5) {$examples.Add("hash differs: $relative")} }
        }
        [pscustomobject]@{Zip=$pair[0]; Files=$total; Matched=$matched; Missing=$missing; Different=$different; Examples=($examples -join ' | ')}
    } finally { $archive.Dispose() }
}
$results | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'archive_comparison_2026-11-16.csv')
$results | Format-Table -Wrap -AutoSize
