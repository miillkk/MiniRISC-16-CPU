param(
    [string]$PortName = '',
    [int]$BaudRate = 115200,
    [switch]$NoColor,
    [switch]$Ascii,
    [switch]$Demo,
    [ValidateSet('Running', 'Paused', 'GameOver')]
    [string]$DemoState = 'Running',
    [ValidateSet('Open', 'Maze', 'Hard')]
    [string]$DemoMap = 'Open',
    [ValidateSet('Face', 'Arrow')]
    [string]$HeadStyle = 'Arrow'
)

$ErrorActionPreference = 'Stop'
$esc = [char]27
$resetStyle = "$esc[0m"
$supportsVirtualTerminal = $false
try { $supportsVirtualTerminal = [bool]$Host.UI.SupportsVirtualTerminal } catch {}
$useColor = -not $NoColor -and (
    $supportsVirtualTerminal -or
    -not [string]::IsNullOrWhiteSpace($env:WT_SESSION) -or
    $PSVersionTable.PSVersion.Major -ge 7
)
$boardWidth = 16
$boardHeight = 8
$cellCount = $boardWidth * $boardHeight
$frameSize = 140
$protocolVersion = 3
$cellOffset = 4
$metaOffset = $cellOffset + $cellCount
$outerWidth = 78
$directionNames = @('UP', 'RIGHT', 'DOWN', 'LEFT')
$directionMarks = if ($Ascii) { @('^', '>', 'v', '<') } else { @([char]0x2191, [char]0x2192, [char]0x2193, [char]0x2190) }
$headGlyphs = if ($HeadStyle -eq 'Face' -and $Ascii) {
    @('^O', 'O>', 'vO', '<O')
} elseif ($HeadStyle -eq 'Face') {
    @(
        (([string][char]0x25B2) + ([string][char]0x25C9))
        (([string][char]0x25C9) + ([string][char]0x25B6))
        (([string][char]0x25BC) + ([string][char]0x25C9))
        (([string][char]0x25C0) + ([string][char]0x25C9))
    )
} elseif ($Ascii) {
    @('^ ', '> ', 'v ', '<-')
} else {
    @(
        (([string][char]0x25B2) + ' ')
        (([string][char]0x25B6) + ' ')
        (([string][char]0x25BC) + ' ')
        (([string][char]0x25C0) + ([string][char]0x2501))
    )
}
$box = if ($Ascii) {
    @{ TL='+'; TR='+'; BL='+'; BR='+'; H='-'; V='|'; LM='+'; RM='+' }
} else {
    @{
        TL=[string][char]0x250C; TR=[string][char]0x2510
        BL=[string][char]0x2514; BR=[string][char]0x2518
        H=[string][char]0x2500; V=[string][char]0x2502
        LM=[string][char]0x251C; RM=[string][char]0x2524
    }
}

function Paint([string]$Text, [string]$AnsiCode) {
    if (-not $useColor) { return $Text }
    return "$esc[$AnsiCode`m$Text$resetStyle"
}

function Paint-Head([int]$DirectionIndex, [string]$HeadAnsiCode) {
    if ($HeadStyle -ne 'Face' -or $Ascii -or -not $useColor) {
        return Paint $headGlyphs[$DirectionIndex] $HeadAnsiCode
    }
    $eye = Paint ([string][char]0x25C9) '1;38;2;253;224;71'
    $arrowCodes = @(0x25B2, 0x25B6, 0x25BC, 0x25C0)
    $arrow = Paint ([string][char]$arrowCodes[$DirectionIndex]) $HeadAnsiCode
    if ($DirectionIndex -eq 1) { return $eye + $arrow }
    return $arrow + $eye
}

function Get-VisibleLength([string]$Text) {
    return ([regex]::Replace($Text, "${esc}\[[0-9;]*m", '')).Length
}

function Pad-Visible([string]$Text, [int]$Width) {
    $padding = [Math]::Max(0, $Width - (Get-VisibleLength $Text))
    return $Text + (' ' * $padding)
}

function Center-Text([string]$Text, [int]$Width) {
    $remaining = [Math]::Max(0, $Width - $Text.Length)
    $left = [Math]::Floor($remaining / 2)
    $right = $remaining - $left
    return (' ' * $left) + $Text + (' ' * $right)
}

function New-Border([string]$Left, [string]$Right) {
    return $Left + ($box.H * ($outerWidth - 2)) + $Right
}

function New-PanelLine([string]$Content = '') {
    return $box.V + ' ' + (Pad-Visible $Content ($outerWidth - 4)) + ' ' + $box.V
}

function Write-Screen([Collections.Generic.List[string]]$Lines) {
    try { [Console]::SetCursorPosition(0, 0) } catch {}
    foreach ($line in $Lines) {
        [Console]::WriteLine((Pad-Visible $line $outerWidth))
    }
}

function New-Header([string]$RightText) {
    $left = Paint ' MINIRISC-16 / SNAKE V2 ' '1;38;2;103;232;249'
    $right = Paint $RightText '38;2;148;163;184'
    $gap = [Math]::Max(1, ($outerWidth - 4) - (Get-VisibleLength $left) - (Get-VisibleLength $right))
    return $left + (' ' * $gap) + $right
}

function Show-Waiting {
    $lines = [Collections.Generic.List[string]]::new()
    $lines.Add((New-Border $box.TL $box.TR))
    $lines.Add((New-PanelLine (New-Header "$PortName @ $BaudRate")))
    $lines.Add((New-Border $box.LM $box.RM))
    $lines.Add((New-PanelLine ''))
    $lines.Add((New-PanelLine ('            ' + (Paint 'WAITING FOR FPGA FRAMES' '1;38;2;250;204;21'))))
    $lines.Add((New-PanelLine ''))
    $lines.Add((New-PanelLine '  Check: SW7=0 / J8 PL-UART connected / board running'))
    $lines.Add((New-PanelLine '  Press Q to quit. The game appears after the first frame.'))
    $lines.Add((New-PanelLine ''))
    $lines.Add((New-Border $box.BL $box.BR))
    Write-Screen $lines
}

function Show-ProtocolError([int]$Count) {
    $lines = [Collections.Generic.List[string]]::new()
    $lines.Add((New-Border $box.TL $box.TR))
    $lines.Add((New-PanelLine (New-Header "$PortName @ $BaudRate")))
    $lines.Add((New-Border $box.LM $box.RM))
    $lines.Add((New-PanelLine ''))
    $lines.Add((New-PanelLine ('          ' + (Paint 'FRAME VERSION / CHECKSUM ERROR' '1;38;2;248;113;113'))))
    $lines.Add((New-PanelLine ''))
    $lines.Add((New-PanelLine ("  Invalid frames: $Count   Expected protocol: v$protocolVersion / $frameSize bytes")))
    $lines.Add((New-PanelLine '  Upload the current program\snake.mem, then set SW7 back to 0.'))
    $lines.Add((New-PanelLine ''))
    $lines.Add((New-Border $box.BL $box.BR))
    Write-Screen $lines
}

function Send-KeyByte([IO.Ports.SerialPort]$SerialPort, [byte]$Value) {
    $payload = [byte[]]@($Value)
    $SerialPort.Write($payload, 0, 1)
}

function Get-WallGlyph([byte[]]$Frame, [int]$Cell) {
    if ($Ascii) { return '##' }
    $row = [Math]::Floor($Cell / $boardWidth)
    $column = $Cell % $boardWidth
    $connections = 0
    if ($row -gt 0 -and $Frame[$cellOffset + $Cell - $boardWidth] -eq 0xFF) { $connections += 1 }
    if ($column -lt ($boardWidth - 1) -and $Frame[$cellOffset + $Cell + 1] -eq 0xFF) { $connections += 2 }
    if ($row -lt ($boardHeight - 1) -and $Frame[$cellOffset + $Cell + $boardWidth] -eq 0xFF) { $connections += 4 }
    if ($column -gt 0 -and $Frame[$cellOffset + $Cell - 1] -eq 0xFF) { $connections += 8 }

    $wallCharacters = @(
        0x25C6, 0x2575, 0x2576, 0x2514,
        0x2577, 0x2502, 0x250C, 0x251C,
        0x2574, 0x2518, 0x2500, 0x2534,
        0x2510, 0x2524, 0x252C, 0x253C
    )
    $first = [string][char]$wallCharacters[$connections]
    $second = if (($connections -band 2) -ne 0) { [string][char]0x2500 } else { ' ' }
    return $first + $second
}

function Get-SnakeGlyph([byte[]]$Frame, [int]$Cell, [int]$Age) {
    if ($Ascii) {
        $horizontal = '-'
        $vertical = '|'
        $corner = '+'
    }
    $row = [Math]::Floor($Cell / $boardWidth)
    $column = $Cell % $boardWidth
    $connections = 0
    $neighbors = @(
        @{ Valid=($row -gt 0); Index=($Cell - $boardWidth); Bit=1 },
        @{ Valid=($column -lt ($boardWidth - 1)); Index=($Cell + 1); Bit=2 },
        @{ Valid=($row -lt ($boardHeight - 1)); Index=($Cell + $boardWidth); Bit=4 },
        @{ Valid=($column -gt 0); Index=($Cell - 1); Bit=8 }
    )
    foreach ($neighbor in $neighbors) {
        if (-not $neighbor.Valid) { continue }
        $neighborAge = [int]$Frame[$cellOffset + $neighbor.Index]
        if ($neighborAge -ne 0 -and $neighborAge -ne 0xFF -and [Math]::Abs($neighborAge - $Age) -eq 1) {
            $connections += $neighbor.Bit
        }
    }

    # A serial frame is normally age-contiguous. If a transient/corrupt frame
    # breaks that invariant, reconnect to any adjacent snake segment instead
    # of falling back to a round dot at the tail.
    if ($connections -eq 0) {
        foreach ($neighbor in $neighbors) {
            if (-not $neighbor.Valid) { continue }
            $neighborAge = [int]$Frame[$cellOffset + $neighbor.Index]
            if ($neighborAge -ne 0 -and $neighborAge -ne 0xFF) {
                $connections += $neighbor.Bit
            }
        }
    }

    if ($Ascii) {
        if (($connections -band 10) -ne 0 -and ($connections -band 5) -eq 0) { return '--' }
        if (($connections -band 5) -ne 0 -and ($connections -band 10) -eq 0) { return '| ' }
        if ($connections -eq 0) { return '- ' }
        return '+-'
    }

    $snakeCharacters = @(
        0x257A, 0x2579, 0x257A, 0x2517,
        0x257B, 0x2503, 0x250F, 0x2523,
        0x2578, 0x251B, 0x2501, 0x253B,
        0x2513, 0x252B, 0x2533, 0x254B
    )
    $first = [string][char]$snakeCharacters[$connections]
    $second = if (($connections -band 2) -ne 0) { [string][char]0x2501 } else { ' ' }
    return $first + $second
}

function Get-FrameChecksum([byte[]]$Frame) {
    $checksum = 0
    for ($index = 0; $index -lt ($frameSize - 1); $index++) {
        $checksum = $checksum -bxor $Frame[$index]
    }
    return [byte]($checksum -band 0xFF)
}

function Test-Frame([byte[]]$Frame) {
    if ($Frame.Length -ne $frameSize) { return $false }
    if ($Frame[0] -ne 0xA5) { return $false }
    if ($Frame[$metaOffset + 4] -ne $protocolVersion) { return $false }
    if ($Frame[$metaOffset + 5] -ne $frameSize) { return $false }
    return (Get-FrameChecksum $Frame) -eq $Frame[$frameSize - 1]
}

function Render-Frame([byte[]]$Frame) {
    $status = $Frame[1]
    $score = $Frame[2]
    $food = $Frame[3] -band 0x7F
    $highScore = $Frame[$metaOffset]
    $level = $Frame[$metaOffset + 1] -band 3
    $switchState = $Frame[$metaOffset + 2]
    $flags = $Frame[$metaOffset + 3]
    $sequence = $Frame[$metaOffset + 6]
    $mapBits = ($switchState -shr 3) -band 3
    $mapName = if ($mapBits -eq 0) { 'OPEN' } elseif ($mapBits -eq 1) { 'MAZE' } else { 'HARD' }
    $gameOver = ($status -band 0x80) -ne 0
    $paused = ($switchState -band 0x04) -ne 0
    $directionIndex = $status -band 3
    $direction = $directionNames[$directionIndex]
    $effectiveLevel = [Math]::Min(3, (($switchState -band 3) + $level))
    $intervalNames = @('1.00 s', '0.50 s', '0.25 s', '0.125 s')
    $maxAge = 0

    for ($cell = 0; $cell -lt $cellCount; $cell++) {
        if ($Frame[$cellOffset + $cell] -ne 0xFF -and $Frame[$cellOffset + $cell] -gt $maxAge) {
            $maxAge = $Frame[$cellOffset + $cell]
        }
    }

    if ($gameOver) {
        $stateText = Paint 'GAME OVER' '1;38;2;248;113;113'
    } elseif ($paused) {
        $stateText = Paint 'PAUSED' '1;38;2;250;204;21'
    } else {
        $stateText = Paint 'RUNNING' '1;38;2;74;222;128'
    }

    $stats = @(
        ('STATUS     {0}' -f $stateText),
        ('SCORE      {0:D3}' -f $score),
        ('HIGH       {0:D3}' -f $highScore),
        ('MAP        {0,-4}  SW 0x{1:X2}' -f $mapName, $switchState),
        ('LEVEL      {0} / 3' -f $level),
        ('HEADING    {0,-5} {1}' -f $direction, $directionMarks[$directionIndex]),
        ('STEP       {0}' -f $intervalNames[$effectiveLevel]),
        ('FLAGS  0x{0:X2}   SEQ {1:D3}' -f $flags, $sequence)
    )

    $dimBoard = $paused -or $gameOver
    $emptyColor = if ($dimBoard) { '38;2;51;65;85' } else { '38;2;71;85;105' }
    $wallColor = if ($dimBoard) { '38;2;75;85;99' } else { '38;2;148;163;184' }
    $snakeColor = if ($dimBoard) { '38;2;45;110;75' } else { '38;2;74;222;128' }
    $headColor = if ($dimBoard) { '1;38;2;40;125;75' } else { '1;38;2;34;197;94' }
    $foodColor = if ($dimBoard) { '38;2;120;65;75' } else { '1;38;2;251;113;133' }

    $boardRows = [Collections.Generic.List[string]]::new()
    $boardRows.Add($box.TL + ($box.H * ($boardWidth * 2)) + $box.TR)
    for ($row = 0; $row -lt $boardHeight; $row++) {
        if (($gameOver -or $paused) -and $row -eq 3) {
            $message = Center-Text $(if ($gameOver) { 'GAME OVER' } else { 'PAUSED' }) ($boardWidth * 2)
            $messageColor = if ($gameOver) { '1;38;2;248;113;113' } else { '1;38;2;250;204;21' }
            $boardRows.Add($box.V + (Paint $message $messageColor) + $box.V)
            continue
        }
        if (($gameOver -or $paused) -and $row -eq 4) {
            $message = Center-Text $(if ($gameOver) { 'PRESS R TO RESTART' } else { 'SWITCH SW2 TO RESUME' }) ($boardWidth * 2)
            $boardRows.Add($box.V + (Paint $message '38;2;148;163;184') + $box.V)
            continue
        }
        $line = $box.V
        for ($column = 0; $column -lt $boardWidth; $column++) {
            $cell = $row * $boardWidth + $column
            $age = $Frame[$cellOffset + $cell]
            if ($age -eq 0xFF) {
                $glyph = Get-WallGlyph $Frame $cell
                $line += Paint $glyph $wallColor
            } elseif ($age -eq $maxAge -and $age -ne 0) {
                $line += Paint-Head $directionIndex $headColor
            } elseif ($age -ne 0) {
                $glyph = Get-SnakeGlyph $Frame $cell $age
                $line += Paint $glyph $snakeColor
            } elseif ($cell -eq $food) {
                $glyph = if ($Ascii) { '**' } else { ([string][char]0x25C6) + ' ' }
                $line += Paint $glyph $foodColor
            } else {
                $glyph = if ($Ascii) { '. ' } else { ([string][char]0x00B7) + ' ' }
                $line += Paint $glyph $emptyColor
            }
        }
        $boardRows.Add($line + $box.V)
    }
    $boardRows.Add($box.BL + ($box.H * ($boardWidth * 2)) + $box.BR)

    $lines = [Collections.Generic.List[string]]::new()
    $lines.Add((New-Border $box.TL $box.TR))
    $lines.Add((New-PanelLine (New-Header "$PortName @ $BaudRate")))
    $lines.Add((New-Border $box.LM $box.RM))
    $lines.Add((New-PanelLine (('  {0}   {1}' -f $boardRows[0], (Paint 'LIVE CPU STATE' '1;38;2;192;132;252')))))
    for ($row = 0; $row -lt $boardHeight; $row++) {
        $lines.Add((New-PanelLine (('  {0}   {1}' -f $boardRows[$row + 1], $stats[$row]))))
    }
    $lines.Add((New-PanelLine (('  {0}' -f $boardRows[$boardHeight + 1]))))
    $lines.Add((New-Border $box.LM $box.RM))
    $lines.Add((New-PanelLine '  MOVE  W/A/S/D or arrows    RESTART  R    QUIT  Q'))
    $lines.Add((New-PanelLine '  BOARD SW1..0 speed   SW2 pause   SW4..3 map at restart'))
    $lines.Add((New-Border $box.BL $box.BR))
    Write-Screen $lines
}

function Show-Demo {
    $sample = New-Object byte[] $frameSize
    $sample[0] = 0xA5
    $sample[1] = 0x01
    $sample[2] = 7
    $sample[3] = 111
    $demoObstacles = switch ($DemoMap) {
        'Open' { @(19,20,21,26,27,28,83,84,91,92,103,104) }
        'Maze' { @(19,35,51,83,99,40,41,42,43,44,60,76,87,88,89,90) }
        'Hard' { @(18,34,66,82,98,29,45,61,93,109,22,23,24,25,40,68,69,70,88,89,90,91,101,102,103) }
    }
    foreach ($cell in $demoObstacles) {
        $sample[$cellOffset + $cell] = 0xFF
    }
    # L-shaped sample exercises vertical, corner and horizontal rendering.
    $sample[$cellOffset + 37] = 1
    $sample[$cellOffset + 38] = 2
    $sample[$cellOffset + 54] = 3
    $sample[$cellOffset + 55] = 4
    $sample[$metaOffset] = 12
    $sample[$metaOffset + 1] = 3
    $mapSwitchBits = switch ($DemoMap) { 'Open' { 0x00 } 'Maze' { 0x08 } 'Hard' { 0x10 } }
    $sample[$metaOffset + 2] = 0x01 -bor $mapSwitchBits
    $sample[$metaOffset + 3] = 0x02
    if ($DemoState -eq 'Paused') {
        $sample[$metaOffset + 2] = 0x05 -bor $mapSwitchBits
    } elseif ($DemoState -eq 'GameOver') {
        $sample[1] = 0x81
    }
    $sample[$metaOffset + 4] = $protocolVersion
    $sample[$metaOffset + 5] = $frameSize
    $sample[$metaOffset + 6] = 7
    $sample[$frameSize - 1] = Get-FrameChecksum $sample
    $script:PortName = 'DEMO'
    Render-Frame $sample
}

if ($Demo) {
    Show-Demo
    exit 0
}

if (-not $PortName) {
    $ports = [IO.Ports.SerialPort]::GetPortNames() | Sort-Object
    Write-Host 'Available serial ports:'
    if ($ports.Count) { $ports | ForEach-Object { Write-Host "  $_" } }
    else { Write-Host '  (none)' }
    Write-Host ''
    Write-Host 'Preview: .\tools\snake_terminal.ps1 -Demo'
    Write-Host 'Connect: .\tools\snake_terminal.ps1 -PortName COMx'
    exit 0
}

$serial = [IO.Ports.SerialPort]::new($PortName, $BaudRate, [IO.Ports.Parity]::None, 8, [IO.Ports.StopBits]::One)
$serial.ReadTimeout = 20
$serial.WriteTimeout = 1000
$packet = New-Object byte[] $frameSize
$packetIndex = 0
$invalidFrameCount = 0
$originalCursorVisible = $true
$originalTitle = ''

try {
    try { $originalCursorVisible = [Console]::CursorVisible } catch {}
    try { $originalTitle = [Console]::Title } catch {}
    try { [Console]::CursorVisible = $false } catch {}
    try { [Console]::Title = "MiniRISC-16 Snake V2 - $PortName" } catch {}
    try { [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false) } catch {}

    $serial.Open()
    try { [Console]::Clear() } catch {}
    Show-Waiting
    $quit = $false

    while (-not $quit) {
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            $value = $null
            switch ($key.Key) {
                'UpArrow'    { $value = [byte][char]'W' }
                'RightArrow' { $value = [byte][char]'D' }
                'DownArrow'  { $value = [byte][char]'S' }
                'LeftArrow'  { $value = [byte][char]'A' }
                'W'          { $value = [byte][char]'W' }
                'A'          { $value = [byte][char]'A' }
                'S'          { $value = [byte][char]'S' }
                'D'          { $value = [byte][char]'D' }
                'R'          { $value = [byte][char]'R' }
                'Q'          { $quit = $true }
            }
            if ($null -ne $value) { Send-KeyByte $serial $value }
        }

        while ($serial.BytesToRead -gt 0) {
            $value = $serial.ReadByte()
            if ($packetIndex -eq 0) {
                if ($value -ne 0xA5) { continue }
                $packet[0] = [byte]$value
                $packetIndex = 1
            } else {
                $packet[$packetIndex] = [byte]$value
                $packetIndex++
                if ($packetIndex -eq $frameSize) {
                    if (Test-Frame $packet) {
                        $invalidFrameCount = 0
                        Render-Frame $packet
                    } else {
                        $invalidFrameCount++
                        Show-ProtocolError $invalidFrameCount
                    }
                    $packetIndex = 0
                }
            }
        }
        Start-Sleep -Milliseconds 2
    }
} finally {
    if ($serial.IsOpen) { $serial.Close() }
    $serial.Dispose()
    if ($useColor) { [Console]::Write($resetStyle) }
    try { [Console]::CursorVisible = $originalCursorVisible } catch {}
    if ($originalTitle) { try { [Console]::Title = $originalTitle } catch {} }
    [Console]::WriteLine()
}
