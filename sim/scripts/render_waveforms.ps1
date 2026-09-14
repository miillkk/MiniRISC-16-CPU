param(
    [string]$VcdPath = "",
    [string]$OutputDirectory = ""
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = (Resolve-Path -LiteralPath (Join-Path $scriptDir "..\..")).Path
if (-not $VcdPath) { $VcdPath = Join-Path $projectRoot "reports\waveforms\system.vcd" }
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $projectRoot "reports\waveforms" }
$VcdPath = (Resolve-Path -LiteralPath $VcdPath).Path
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

$definitions = New-Object System.Collections.Generic.List[object]
$scope = New-Object System.Collections.Generic.List[string]
$changes = @{}
$time = [long]0
$maxTime = [long]0
$inDefinitions = $true
$timeUnitNs = 0.001
$pendingTimescale = $false

foreach ($rawLine in [IO.File]::ReadLines($VcdPath)) {
    $line = $rawLine.Trim()
    if (-not $line) { continue }

    if ($inDefinitions) {
        if ($pendingTimescale) {
            if ($line -match '([0-9]+)\s*(s|ms|us|ns|ps|fs)') {
                $amount = [double]$matches[1]
                $unit = $matches[2]
                $factor = @{ s = 1.0e9; ms = 1.0e6; us = 1.0e3; ns = 1.0; ps = 1.0e-3; fs = 1.0e-6 }[$unit]
                $timeUnitNs = $amount * $factor
            }
            if ($line -match '\$end') { $pendingTimescale = $false }
            continue
        }
        if ($line -match '^\$timescale(?:\s+(.+?))?\s*\$end$') {
            $scaleText = $matches[1]
            if ($scaleText -match '([0-9]+)\s*(s|ms|us|ns|ps|fs)') {
                $amount = [double]$matches[1]
                $unit = $matches[2]
                $factor = @{ s = 1.0e9; ms = 1.0e6; us = 1.0e3; ns = 1.0; ps = 1.0e-3; fs = 1.0e-6 }[$unit]
                $timeUnitNs = $amount * $factor
            }
            continue
        }
        if ($line -eq '$timescale') {
            $pendingTimescale = $true
            continue
        }
        if ($line -match '^\$scope\s+\S+\s+(\S+)\s+\$end$') {
            $scope.Add($matches[1])
            continue
        }
        if ($line -match '^\$upscope\s+\$end$') {
            if ($scope.Count -gt 0) { $scope.RemoveAt($scope.Count - 1) }
            continue
        }
        if ($line -match '^\$var\s+\S+\s+(\d+)\s+(\S+)\s+(.+?)\s+\$end$') {
            $width = [int]$matches[1]
            $code = $matches[2]
            $reference = ($matches[3] -replace '\s+\[[^]]+\]$', '')
            $fullName = (($scope.ToArray() + @($reference)) -join '/')
            $definitions.Add([pscustomobject]@{ Code = $code; Width = $width; Name = $fullName })
            continue
        }
        if ($line -match '^\$enddefinitions') {
            $inDefinitions = $false
        }
        continue
    }

    if ($line -match '^#(\d+)$') {
        $time = [long]$matches[1]
        if ($time -gt $maxTime) { $maxTime = $time }
        continue
    }

    $code = $null
    $value = $null
    if ($line -match '^[bB]([01xXzZ]+)\s+(\S+)$') {
        $value = $matches[1].ToLowerInvariant()
        $code = $matches[2]
    } elseif ($line -match '^([01xXzZ])(.+)$') {
        $value = $matches[1].ToLowerInvariant()
        $code = $matches[2].Trim()
    }

    if ($code) {
        $codeKey = [string]$code
        if (-not $changes.ContainsKey($codeKey)) {
            $changes[$codeKey] = New-Object System.Collections.Generic.List[object]
        }
        $list = $changes[$codeKey]
        if ($list.Count -eq 0 -or $list[$list.Count - 1].Value -ne $value) {
            $list.Add([pscustomobject]@{ Time = $time; Value = $value })
        }
    }
}

if ($maxTime -le 0) { throw "VCD contains no timed signal activity: $VcdPath" }

function Find-TraceDefinition {
    param([string]$TraceName)
    $matchesFound = @($definitions | Where-Object { $_.Name -match "/$([Regex]::Escape($TraceName))$" })
    if ($matchesFound.Count -eq 0) {
        throw "Required trace signal '$TraceName' was not found in $VcdPath"
    }
    return $matchesFound[0]
}

function Get-Segments {
    param($Definition)
    $events = New-Object System.Collections.Generic.List[object]
    $codeKey = [string]$Definition.Code
    if ($changes.ContainsKey($codeKey)) {
        foreach ($event in $changes[$codeKey]) {
            $events.Add($event)
        }
    }
    $segments = New-Object System.Collections.Generic.List[object]
    $currentTime = [long]0
    $currentValue = if ($Definition.Width -eq 1) { "x" } else { "x" * $Definition.Width }

    foreach ($event in $events) {
        if ($event.Time -gt $currentTime) {
            $segments.Add([pscustomobject]@{ Start = $currentTime; End = $event.Time; Value = $currentValue })
        }
        $currentTime = $event.Time
        $currentValue = $event.Value
    }
    if ($currentTime -lt $maxTime) {
        $segments.Add([pscustomobject]@{ Start = $currentTime; End = $maxTime; Value = $currentValue })
    }
    foreach ($segment in $segments) {
        Write-Output $segment
    }
}

function Format-BusValue {
    param([string]$Bits, [int]$Width)
    if ($Bits -match '[xz]') { return $Bits.ToUpperInvariant() }
    $padded = $Bits.PadLeft($Width, '0')
    $number = [Convert]::ToUInt64($padded, 2)
    $digits = [Math]::Ceiling($Width / 4.0)
    return ("0x{0}" -f $number.ToString("X$digits"))
}

$groups = @(
    [pscustomobject]@{
        File = "01_single_cycle_commit"; Title = "Single-cycle commit";
        Signals = @("trace_clk", "trace_rst", "trace_pc", "trace_instruction", "trace_reg_write", "trace_io_we")
    },
    [pscustomobject]@{
        File = "02_cmp_jz_jump"; Title = "CMP, JZ and JUMP";
        Signals = @("trace_clk", "trace_pc", "trace_instruction", "trace_z", "trace_z_write", "trace_branch_z", "trace_jump", "trace_pc_next")
    },
    [pscustomobject]@{
        File = "03_registers_alu"; Title = "Registers and ALU";
        Signals = @("trace_clk", "trace_pc", "trace_rd_data", "trace_rs_data", "trace_alu_result", "trace_writeback_data", "trace_r0", "trace_r1", "trace_r2", "trace_r3")
    },
    [pscustomobject]@{
        File = "04_gpio_io"; Title = "GPIO INP, OUP and direction control";
        Signals = @("trace_clk", "trace_pc", "trace_io_addr", "trace_io_wdata", "trace_io_rdata", "trace_io_re", "trace_io_we", "trace_gpio_out", "trace_gpio_dir", "trace_gpio_in", "trace_gpio_pins")
    }
)

$canvasWidth = 1800
$leftMargin = 210
$rightMargin = 35
$topMargin = 78
$rowHeight = 38
$plotWidth = $canvasWidth - $leftMargin - $rightMargin
$durationNs = $maxTime * $timeUnitNs
$gridNs = if ($durationNs -le 100) { 10 } elseif ($durationNs -le 250) { 20 } else { 50 }

function Time-ToX {
    param([double]$RawTime)
    return $leftMargin + ($RawTime / $maxTime) * $plotWidth
}

function Scalar-LevelY {
    param([string]$Value, [double]$CenterY)
    if ($Value -eq "1") { return $CenterY - 9 }
    if ($Value -eq "0") { return $CenterY + 9 }
    return $CenterY
}

function New-SvgWaveform {
    param($Group, [object[]]$SignalDefinitions, [string]$Path)
    $height = $topMargin + ($SignalDefinitions.Count * $rowHeight) + 55
    $builder = New-Object Text.StringBuilder
    [void]$builder.AppendLine('<?xml version="1.0" encoding="UTF-8"?>')
    [void]$builder.AppendLine("<svg xmlns=`"http://www.w3.org/2000/svg`" width=`"$canvasWidth`" height=`"$height`" viewBox=`"0 0 $canvasWidth $height`">")
    [void]$builder.AppendLine('<rect width="100%" height="100%" fill="#ffffff"/>')
    [void]$builder.AppendLine("<text x=`"24`" y=`"34`" font-family=`"Segoe UI,Arial`" font-size=`"22`" font-weight=`"600`" fill=`"#172033`">$($Group.Title)</text>")
    [void]$builder.AppendLine("<text x=`"24`" y=`"57`" font-family=`"Segoe UI,Arial`" font-size=`"12`" fill=`"#596579`">MiniRISC-16 • source: system.vcd • duration $([Math]::Round($durationNs,3)) ns</text>")

    for ($gridTime = 0.0; $gridTime -le $durationNs + 0.0001; $gridTime += $gridNs) {
        $rawGrid = $gridTime / $timeUnitNs
        $x = Time-ToX $rawGrid
        [void]$builder.AppendLine("<line x1=`"$x`" y1=`"$topMargin`" x2=`"$x`" y2=`"$($height-30)`" stroke=`"#e4e8ef`" stroke-width=`"1`"/>")
        [void]$builder.AppendLine("<text x=`"$($x+3)`" y=`"$($height-10)`" font-family=`"Consolas,monospace`" font-size=`"11`" fill=`"#667085`">$gridTime ns</text>")
    }

    for ($row = 0; $row -lt $SignalDefinitions.Count; $row++) {
        $definition = $SignalDefinitions[$row]
        $centerY = $topMargin + ($row * $rowHeight) + 18
        $safeName = [Security.SecurityElement]::Escape(($definition.Name -replace '^.*/trace_', ''))
        [void]$builder.AppendLine("<text x=`"18`" y=`"$($centerY+5)`" font-family=`"Consolas,monospace`" font-size=`"13`" fill=`"#25324a`">$safeName</text>")
        [void]$builder.AppendLine("<line x1=`"$leftMargin`" y1=`"$centerY`" x2=`"$($canvasWidth-$rightMargin)`" y2=`"$centerY`" stroke=`"#edf0f5`" stroke-width=`"1`"/>")
        $segments = @(Get-Segments $definition)

        if ($definition.Width -eq 1) {
            $previousY = $null
            foreach ($segment in $segments) {
                $x1 = Time-ToX $segment.Start
                $x2 = Time-ToX $segment.End
                $levelY = Scalar-LevelY $segment.Value $centerY
                $color = if ($segment.Value -match '[xz]') { "#8b5cf6" } else { "#087ea4" }
                if ($null -ne $previousY -and $previousY -ne $levelY) {
                    [void]$builder.AppendLine("<line x1=`"$x1`" y1=`"$previousY`" x2=`"$x1`" y2=`"$levelY`" stroke=`"$color`" stroke-width=`"2`"/>")
                }
                [void]$builder.AppendLine("<line x1=`"$x1`" y1=`"$levelY`" x2=`"$x2`" y2=`"$levelY`" stroke=`"$color`" stroke-width=`"2`"/>")
                $previousY = $levelY
            }
        } else {
            $segmentIndex = 0
            foreach ($segment in $segments) {
                $x1 = Time-ToX $segment.Start
                $x2 = Time-ToX $segment.End
                $segmentWidth = [Math]::Max(0.5, $x2 - $x1)
                $unknown = $segment.Value -match '[xz]'
                $fill = if ($unknown) { "#f1eafe" } elseif (($segmentIndex % 2) -eq 0) { "#e6f4f8" } else { "#d9eef4" }
                [void]$builder.AppendLine("<rect x=`"$x1`" y=`"$($centerY-11)`" width=`"$segmentWidth`" height=`"22`" fill=`"$fill`" stroke=`"#087ea4`" stroke-width=`"1`"/>")
                if ($segmentWidth -gt 30) {
                    $label = [Security.SecurityElement]::Escape((Format-BusValue $segment.Value $definition.Width))
                    [void]$builder.AppendLine("<text x=`"$($x1+3)`" y=`"$($centerY+4)`" font-family=`"Consolas,monospace`" font-size=`"10`" fill=`"#172033`">$label</text>")
                }
                $segmentIndex++
            }
        }
    }

    [void]$builder.AppendLine('</svg>')
    [IO.File]::WriteAllText($Path, $builder.ToString(), [Text.UTF8Encoding]::new($false))
}

Add-Type -AssemblyName System.Drawing

function New-PngWaveform {
    param($Group, [object[]]$SignalDefinitions, [string]$Path)
    $height = $topMargin + ($SignalDefinitions.Count * $rowHeight) + 55
    $bitmap = New-Object Drawing.Bitmap($canvasWidth, $height)
    $graphics = [Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.Clear([Drawing.Color]::White)
    $titleFont = New-Object Drawing.Font("Segoe UI", 16, [Drawing.FontStyle]::Bold)
    $bodyFont = New-Object Drawing.Font("Consolas", 9)
    $smallFont = New-Object Drawing.Font("Consolas", 7)
    $titleBrush = New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(23,32,51))
    $textBrush = New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(37,50,74))
    $gridPen = New-Object Drawing.Pen([Drawing.Color]::FromArgb(228,232,239), 1)
    $signalPen = New-Object Drawing.Pen([Drawing.Color]::FromArgb(8,126,164), 2)
    $unknownPen = New-Object Drawing.Pen([Drawing.Color]::FromArgb(139,92,246), 2)
    $busPen = New-Object Drawing.Pen([Drawing.Color]::FromArgb(8,126,164), 1)

    try {
        $graphics.DrawString($Group.Title, $titleFont, $titleBrush, 20, 15)
        $graphics.DrawString("MiniRISC-16  |  duration $([Math]::Round($durationNs,3)) ns", $bodyFont, $textBrush, 22, 48)

        for ($gridTime = 0.0; $gridTime -le $durationNs + 0.0001; $gridTime += $gridNs) {
            $x = [single](Time-ToX ($gridTime / $timeUnitNs))
            $graphics.DrawLine($gridPen, $x, $topMargin, $x, $height - 30)
            $graphics.DrawString("$gridTime ns", $smallFont, $textBrush, $x + 2, $height - 24)
        }

        for ($row = 0; $row -lt $SignalDefinitions.Count; $row++) {
            $definition = $SignalDefinitions[$row]
            $centerY = [single]($topMargin + ($row * $rowHeight) + 18)
            $shortName = $definition.Name -replace '^.*/trace_', ''
            $graphics.DrawString($shortName, $bodyFont, $textBrush, 14, $centerY - 8)
            $segments = @(Get-Segments $definition)

            if ($definition.Width -eq 1) {
                $previousY = $null
                foreach ($segment in $segments) {
                    $x1 = [single](Time-ToX $segment.Start)
                    $x2 = [single](Time-ToX $segment.End)
                    $levelY = [single](Scalar-LevelY $segment.Value $centerY)
                    $pen = if ($segment.Value -match '[xz]') { $unknownPen } else { $signalPen }
                    if ($null -ne $previousY -and $previousY -ne $levelY) {
                        $graphics.DrawLine($pen, $x1, [single]$previousY, $x1, $levelY)
                    }
                    $graphics.DrawLine($pen, $x1, $levelY, $x2, $levelY)
                    $previousY = $levelY
                }
            } else {
                $segmentIndex = 0
                foreach ($segment in $segments) {
                    $x1 = [single](Time-ToX $segment.Start)
                    $x2 = [single](Time-ToX $segment.End)
                    $widthPixels = [single][Math]::Max(1, $x2 - $x1)
                    $fillColor = if ($segment.Value -match '[xz]') {
                        [Drawing.Color]::FromArgb(241,234,254)
                    } elseif (($segmentIndex % 2) -eq 0) {
                        [Drawing.Color]::FromArgb(230,244,248)
                    } else {
                        [Drawing.Color]::FromArgb(217,238,244)
                    }
                    $fillBrush = New-Object Drawing.SolidBrush($fillColor)
                    try {
                        $graphics.FillRectangle($fillBrush, $x1, $centerY - 11, $widthPixels, 22)
                    } finally {
                        $fillBrush.Dispose()
                    }
                    $graphics.DrawRectangle($busPen, $x1, $centerY - 11, $widthPixels, 22)
                    if ($widthPixels -gt 38) {
                        $graphics.DrawString((Format-BusValue $segment.Value $definition.Width), $smallFont, $textBrush, $x1 + 2, $centerY - 7)
                    }
                    $segmentIndex++
                }
            }
        }
        $bitmap.Save($Path, [Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $graphics.Dispose()
        $bitmap.Dispose()
        $titleFont.Dispose()
        $bodyFont.Dispose()
        $smallFont.Dispose()
        $titleBrush.Dispose()
        $textBrush.Dispose()
        $gridPen.Dispose()
        $signalPen.Dispose()
        $unknownPen.Dispose()
        $busPen.Dispose()
    }
}

foreach ($group in $groups) {
    $signalDefinitions = @($group.Signals | ForEach-Object { Find-TraceDefinition $_ })
    $svgPath = Join-Path $OutputDirectory "$($group.File).svg"
    $pngPath = Join-Path $OutputDirectory "$($group.File).png"
    New-SvgWaveform -Group $group -SignalDefinitions $signalDefinitions -Path $svgPath
    New-PngWaveform -Group $group -SignalDefinitions $signalDefinitions -Path $pngPath
    Write-Output "Generated $svgPath"
    Write-Output "Generated $pngPath"
}
