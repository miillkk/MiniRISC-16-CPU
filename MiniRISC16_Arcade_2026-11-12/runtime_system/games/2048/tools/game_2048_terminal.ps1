param(
    [string]$PortName = '',
    [int]$BaudRate = 115200,
    [switch]$Demo,
    [switch]$NoColor
)

$ErrorActionPreference = 'Stop'
$esc = [char]27
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)

function Paint([string]$text,[string]$code) {
    if ($NoColor) { return $text }
    return "$esc[$code`m$text$esc[0m"
}
function Center([string]$text,[int]$width) {
    if ($text.Length -ge $width) { return $text.Substring(0,$width) }
    $left = [Math]::Floor(($width-$text.Length)/2)
    return (' ' * $left) + $text + (' ' * ($width-$text.Length-$left))
}
function Get-TileStyle([int]$exponent) {
    switch ($exponent) {
        0  { return '38;5;245;48;5;236' }
        1  { return '38;5;238;48;5;230' }
        2  { return '38;5;238;48;5;223' }
        3  { return '38;5;255;48;5;215' }
        4  { return '38;5;255;48;5;209' }
        5  { return '38;5;255;48;5;203' }
        6  { return '38;5;255;48;5;167' }
        7  { return '38;5;255;48;5;221' }
        8  { return '38;5;255;48;5;220' }
        9  { return '38;5;255;48;5;214' }
        10 { return '38;5;255;48;5;208' }
        11 { return '38;5;255;48;5;196' }
        default { return '38;5;255;48;5;90' }
    }
}
function Get-TileValue([int]$exponent) {
    if ($exponent -le 0) { return '' }
    if ($exponent -lt 16) { return ([int](1 -shl $exponent)).ToString() }
    return "2^$exponent"
}
function Test-Frame([byte[]]$frame) {
    if ($frame.Count -ne 27 -or $frame[0] -ne 0xA5 -or $frame[1] -ne 4 -or
        $frame[2] -ne 27 -or $frame[3] -ne 2 -or $frame[8] -ne 4 -or $frame[9] -ne 4) { return $false }
    $checksum = 0
    foreach ($index in 0..25) { $checksum = $checksum -bxor $frame[$index] }
    return (($checksum -band 0xFF) -eq $frame[26])
}
function Show-Waiting([string]$portLabel) {
    $lines = @(
        '',
        (Paint '  MiniRISC-16 ARCADE  /  2048' '1;38;5;220'),
        '',
        "  PORT: $portLabel @ $BaudRate",
        '  Waiting for a 2048 frame from the FPGA...',
        '',
        '  CONTROLS: Arrow keys or W A S D    R Restart    Q Quit',
        '  If no frame appears, make sure SW7 is set back to 0.'
    )
    [Console]::Write("$esc[2J$esc[H" + ($lines -join [Environment]::NewLine))
}
function Render-Frame([byte[]]$frame,[string]$portLabel,[int]$badFrames) {
    $score = [int]$frame[6] + 256*[int]$frame[7]
    $state = [int]$frame[4]
    $won = (($state -band 1) -ne 0)
    $gameOver = (($state -band 0x80) -ne 0)
    $status = if ($gameOver) { 'GAME OVER' } elseif ($won) { '2048 REACHED - KEEP PLAYING' } else { 'RUNNING' }
    $statusCode = if ($gameOver) { '1;38;5;203' } elseif ($won) { '1;38;5;220' } else { '1;38;5;84' }
    $lines = [Collections.Generic.List[string]]::new()
    $lines.Add('')
    $lines.Add((Paint '  MiniRISC-16 ARCADE  /  2048' '1;38;5;220'))
    $lines.Add('')
    $lines.Add(('  SCORE  {0,-7}  STATUS  {1}  FRAME  {2}' -f $score,(Paint $status $statusCode),$frame[5]))
    $lines.Add(('  PORT   {0} @ {1}  LOST/BAD  {2}' -f $portLabel,$BaudRate,$badFrames))
    $lines.Add('')
    $lines.Add('  ┌────────┬────────┬────────┬────────┐')
    foreach ($row in 0..3) {
        $blank = '  │'
        $number = '  │'
        foreach ($column in 0..3) {
            $exponent = [int]$frame[10+$row*4+$column]
            $style = Get-TileStyle $exponent
            $blank += (Paint '        ' $style) + '│'
            $number += (Paint (Center (Get-TileValue $exponent) 8) $style) + '│'
        }
        $lines.Add($blank)
        $lines.Add($number)
        $lines.Add($blank)
        if ($row -lt 3) { $lines.Add('  ├────────┼────────┼────────┼────────┤') }
    }
    $lines.Add('  └────────┴────────┴────────┴────────┘')
    $lines.Add('')
    if ($gameOver) {
        $lines.Add((Paint '  No moves remain. Press R to start a new game.' '1;38;5;203'))
    } elseif ($won) {
        $lines.Add((Paint '  You reached 2048! Keep playing, or press R to restart.' '1;38;5;220'))
    } else {
        $lines.Add('  Arrow keys / W A S D move    R Restart    Q Quit')
    }
    [Console]::Write("$esc[2J$esc[H" + ($lines -join [Environment]::NewLine))
}
function New-DemoFrame {
    $frame = New-Object 'byte[]' 27
    $frame[0]=0xA5; $frame[1]=4; $frame[2]=27; $frame[3]=2
    $frame[4]=0; $frame[5]=42; $frame[6]=0x34; $frame[7]=0x12
    $frame[8]=4; $frame[9]=4
    $tiles = @(1,2,3,4, 5,6,7,8, 9,10,11,0, 2,4,6,8)
    foreach ($index in 0..15) { $frame[10+$index] = $tiles[$index] }
    $checksum = 0
    foreach ($index in 0..25) { $checksum = $checksum -bxor $frame[$index] }
    $frame[26] = $checksum -band 0xFF
    return $frame
}
function Send-Key([IO.Ports.SerialPort]$serial,[byte]$value) {
    $payload = [byte[]]@($value)
    $serial.Write($payload,0,1)
}

if ($Demo) {
    Render-Frame (New-DemoFrame) 'DEMO' 0
    [Console]::WriteLine()
    exit 0
}

if (-not $PortName) {
    $ports = @([IO.Ports.SerialPort]::GetPortNames() | Sort-Object)
    if ($ports.Count -eq 0) { throw 'No serial port found. Connect the board or specify -PortName COM3.' }
    if ($ports.Count -gt 1) { throw ('Multiple serial ports found: {0}. Use -PortName to choose one.' -f ($ports -join ', ')) }
    $PortName = $ports[0]
}

$serial = [IO.Ports.SerialPort]::new($PortName,$BaudRate,[IO.Ports.Parity]::None,8,[IO.Ports.StopBits]::One)
$serial.ReadTimeout = 50
$serial.WriteTimeout = 1000
$buffer = [Collections.Generic.List[byte]]::new()
$badFrames = 0
try {
    $serial.Open()
    $serial.DiscardInBuffer()
    Show-Waiting $PortName
    $quit = $false
    while (-not $quit) {
        while ($serial.BytesToRead -gt 0) { $buffer.Add([byte]$serial.ReadByte()) }
        while ($buffer.Count -gt 0) {
            $syncIndex = $buffer.IndexOf([byte]0xA5)
            if ($syncIndex -lt 0) { $buffer.Clear(); break }
            if ($syncIndex -gt 0) { $buffer.RemoveRange(0,$syncIndex); $badFrames++ }
            if ($buffer.Count -lt 3) { break }
            $length = [int]$buffer[2]
            if ($length -ne 27) { $buffer.RemoveAt(0); $badFrames++; continue }
            if ($buffer.Count -lt $length) { break }
            $frame = New-Object 'byte[]' $length
            $buffer.CopyTo(0,$frame,0,$length)
            if (Test-Frame $frame) {
                $buffer.RemoveRange(0,$length)
                Render-Frame $frame $PortName $badFrames
            } else {
                $buffer.RemoveAt(0)
                $badFrames++
            }
        }
        while ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            switch ($key.Key) {
                'LeftArrow'  { Send-Key $serial ([byte][char]'A') }
                'RightArrow' { Send-Key $serial ([byte][char]'D') }
                'UpArrow'    { Send-Key $serial ([byte][char]'W') }
                'DownArrow'  { Send-Key $serial ([byte][char]'S') }
                'A'          { Send-Key $serial ([byte][char]'A') }
                'D'          { Send-Key $serial ([byte][char]'D') }
                'W'          { Send-Key $serial ([byte][char]'W') }
                'S'          { Send-Key $serial ([byte][char]'S') }
                'R'          { Send-Key $serial ([byte][char]'R') }
                'Q'          { $quit = $true }
            }
        }
        Start-Sleep -Milliseconds 10
    }
} finally {
    if ($serial.IsOpen) { $serial.Close() }
    $serial.Dispose()
    if (-not $NoColor) { [Console]::Write("$esc[0m") }
    [Console]::WriteLine()
}
