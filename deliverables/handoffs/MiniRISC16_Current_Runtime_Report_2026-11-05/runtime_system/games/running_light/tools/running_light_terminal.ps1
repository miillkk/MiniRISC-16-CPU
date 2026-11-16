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
    if($NoColor){return $text}
    return "$esc[$code`m$text$esc[0m"
}
function Test-Frame([byte[]]$frame) {
    if($frame.Count -ne 12 -or $frame[0] -ne 0xA5 -or $frame[1] -ne 4 -or
       $frame[2] -ne 12 -or $frame[3] -ne 3){return $false}
    $checksum=0
    foreach($index in 0..10){$checksum=$checksum -bxor $frame[$index]}
    return (($checksum -band 0xFF) -eq $frame[11])
}
function Format-HexFrame([byte[]]$frame) {
    return (($frame | ForEach-Object { '{0:X2}' -f $_ }) -join ' ')
}
function Show-Waiting([string]$portLabel) {
    $lines=@(
        '',
        (Paint '  MiniRISC-16 ARCADE  /  RUNNING LIGHT' '1;38;5;51'),
        '',
        "  PORT: $portLabel @ $BaudRate",
        '  Waiting for a Running Light frame from the FPGA...',
        '',
        '  CONTROLS: Left/A    Right/D    R Restart    Q Quit',
        '  BOARD: SW1..0 Speed    SW2 Pause',
        '  If no frame appears, make sure SW7 is set back to 0.'
    )
    [Console]::Write("$esc[2J$esc[H"+($lines -join [Environment]::NewLine))
}
function Render-Frame([byte[]]$frame,[string]$portLabel,[int]$badFrames) {
    $pattern=[int]$frame[5]
    $position=[int]$frame[6]
    $direction=if($frame[7] -eq 0){'RIGHT / TOWARD LED7'}else{'LEFT / TOWARD LED0'}
    $speed=[int]$frame[8] -band 3
    $intervals=@('1.000 s','0.500 s','0.250 s','0.125 s')
    $paused=(([int]$frame[9] -band 4) -ne 0)
    $state=if($paused){'PAUSED'}else{'RUNNING'}
    $stateColor=if($paused){'1;38;5;220'}else{'1;38;5;84'}
    $lastKey=[int]$frame[10]
    $keyText=if($lastKey -ge 0x20 -and $lastKey -le 0x7E){"0x{0:X2} ('{1}')" -f $lastKey,[char]$lastKey}else{'NONE'}
    $labels='  '
    $lamps='  '
    foreach($index in 0..7){
        $labels += (' LED{0} ' -f $index)
        $on=(($pattern -band (1 -shl $index)) -ne 0)
        if($on){$lamps += (Paint '  ●   ' '1;38;5;51')}else{$lamps += (Paint '  ○   ' '38;5;240')}
    }
    $lines=[Collections.Generic.List[string]]::new()
    $lines.Add('')
    $lines.Add((Paint '  MiniRISC-16 ARCADE  /  RUNNING LIGHT' '1;38;5;51'))
    $lines.Add('')
    $lines.Add(('  STATUS  {0}    DIRECTION  {1}' -f (Paint $state $stateColor),$direction))
    $lines.Add(('  POSITION {0}    PATTERN 0x{1:X2}    SEQUENCE {2}' -f $position,$pattern,$frame[4]))
    $lines.Add(('  SPEED {0} / 3 ({1})    SWITCHES 0x{2:X2}' -f $speed,$intervals[$speed],$frame[9]))
    $lines.Add(('  LAST KEY {0}    BAD FRAMES {1}' -f $keyText,$badFrames))
    $lines.Add('')
    $lines.Add($labels)
    $lines.Add($lamps)
    $lines.Add('')
    $lines.Add((Paint '  FPGA RETURN FRAME' '1;38;5;220'))
    $lines.Add(('  RX  {0}' -f (Format-HexFrame $frame)))
    $lines.Add(('  CHECKSUM PASS: XOR[0..10] = 0x{0:X2}' -f $frame[11]))
    $lines.Add('')
    $lines.Add('  Left/A and Right/D change direction    R Restart    Q Menu')
    $lines.Add('  SW1..0 changes speed    SW2 pauses the hardware timer')
    [Console]::Write("$esc[2J$esc[H"+($lines -join [Environment]::NewLine))
}
function New-DemoFrame {
    $frame=New-Object 'byte[]' 12
    $frame[0]=0xA5; $frame[1]=4; $frame[2]=12; $frame[3]=3
    $frame[4]=37; $frame[5]=0x20; $frame[6]=5; $frame[7]=0
    $frame[8]=2; $frame[9]=2; $frame[10]=[byte][char]'D'
    $checksum=0
    foreach($index in 0..10){$checksum=$checksum -bxor $frame[$index]}
    $frame[11]=$checksum -band 0xFF
    return $frame
}
function Send-Key([IO.Ports.SerialPort]$serial,[byte]$value) {
    $payload=[byte[]]@($value)
    $serial.Write($payload,0,1)
}

if($Demo){
    Render-Frame (New-DemoFrame) 'DEMO' 0
    [Console]::WriteLine()
    exit 0
}

if(-not $PortName){
    $ports=@([IO.Ports.SerialPort]::GetPortNames() | Sort-Object)
    if($ports.Count -eq 0){throw 'No serial port found. Connect the board or specify -PortName COM3.'}
    if($ports.Count -gt 1){throw ('Multiple serial ports found: {0}. Use -PortName to choose one.' -f ($ports -join ', '))}
    $PortName=$ports[0]
}

$serial=[IO.Ports.SerialPort]::new($PortName,$BaudRate,[IO.Ports.Parity]::None,8,[IO.Ports.StopBits]::One)
$serial.ReadTimeout=50
$serial.WriteTimeout=1000
$buffer=[Collections.Generic.List[byte]]::new()
$badFrames=0
try{
    $serial.Open()
    $serial.DiscardInBuffer()
    Show-Waiting $PortName
    $quit=$false
    while(-not $quit){
        while($serial.BytesToRead -gt 0){$buffer.Add([byte]$serial.ReadByte())}
        while($buffer.Count -gt 0){
            $syncIndex=$buffer.IndexOf([byte]0xA5)
            if($syncIndex -lt 0){$buffer.Clear(); break}
            if($syncIndex -gt 0){$buffer.RemoveRange(0,$syncIndex); $badFrames++}
            if($buffer.Count -lt 3){break}
            if($buffer[2] -ne 12){$buffer.RemoveAt(0); $badFrames++; continue}
            if($buffer.Count -lt 12){break}
            $frame=New-Object 'byte[]' 12
            $buffer.CopyTo(0,$frame,0,12)
            if(Test-Frame $frame){
                $buffer.RemoveRange(0,12)
                Render-Frame $frame $PortName $badFrames
            }else{
                $buffer.RemoveAt(0)
                $badFrames++
            }
        }
        while([Console]::KeyAvailable){
            $key=[Console]::ReadKey($true)
            switch($key.Key){
                'LeftArrow'  {Send-Key $serial ([byte][char]'A')}
                'RightArrow' {Send-Key $serial ([byte][char]'D')}
                'A'          {Send-Key $serial ([byte][char]'A')}
                'D'          {Send-Key $serial ([byte][char]'D')}
                'R'          {Send-Key $serial ([byte][char]'R')}
                'Q'          {$quit=$true}
            }
        }
        Start-Sleep -Milliseconds 10
    }
}finally{
    if($serial.IsOpen){$serial.Close()}
    $serial.Dispose()
    if(-not $NoColor){[Console]::Write("$esc[0m")}
    [Console]::WriteLine()
}
