param(
    [string]$PortName = '',
    [int]$BaudRate = 115200
)

$ErrorActionPreference = 'Stop'
if (-not $PortName) {
    $ports = [IO.Ports.SerialPort]::GetPortNames() | Sort-Object
    Write-Host 'Available serial ports:'
    if ($ports.Count) { $ports | ForEach-Object { Write-Host "  $_" } }
    else { Write-Host '  (none)' }
    Write-Host 'Run: .\tools\snake_terminal.ps1 -PortName COMx'
    exit 0
}

$serial = [IO.Ports.SerialPort]::new($PortName,$BaudRate,[IO.Ports.Parity]::None,8,[IO.Ports.StopBits]::One)
$serial.ReadTimeout = 20
$serial.WriteTimeout = 1000
$packet = New-Object byte[] 68
$packetIndex = 0
$directionNames = @('UP','RIGHT','DOWN','LEFT')

function Send-KeyByte([byte]$value) {
    $payload = [byte[]]@($value)
    $serial.Write($payload,0,1)
}
function Render-Frame([byte[]]$frame) {
    $status = $frame[1]
    $score = $frame[2]
    $food = $frame[3] -band 0x3F
    $gameOver = ($status -band 0x80) -ne 0
    $direction = $directionNames[$status -band 3]
    $maxAge = 0
    for($cell=0;$cell -lt 64;$cell++){ if($frame[4+$cell] -gt $maxAge){$maxAge=$frame[4+$cell]} }
    $lines = [Collections.Generic.List[string]]::new()
    $lines.Add('MiniRISC-16 Snake - CPU game program over PL UART')
    $lines.Add(('State: {0,-9}  Direction: {1,-5}  Score: {2,3}' -f $(if($gameOver){'GAME OVER'}else{'RUNNING'}),$direction,$score))
    $lines.Add('+----------------+')
    for($row=0;$row -lt 8;$row++){
        $line='|'
        for($column=0;$column -lt 8;$column++){
            $cell=$row*8+$column
            $age=$frame[4+$cell]
            if($age -eq $maxAge -and $age -ne 0){$glyph='@ '}
            elseif($age -ne 0){$glyph='# '}
            elseif($cell -eq $food){$glyph='* '}
            else{$glyph='. '}
            $line += $glyph
        }
        $lines.Add($line+'|')
    }
    $lines.Add('+----------------+')
    $lines.Add('W/A/S/D or arrow keys: move   R: restart   Q: quit')
    $lines.Add('SW1..0: speed   SW2: pause   S1: hardware reset')
    [Console]::SetCursorPosition(0,0)
    foreach($line in $lines){ Write-Host ($line.PadRight(78)) }
}

try {
    $serial.Open()
    [Console]::Clear()
    Write-Host "Waiting for frames from $PortName at $BaudRate baud..."
    $quit=$false
    while(-not $quit){
        if([Console]::KeyAvailable){
            $key=[Console]::ReadKey($true)
            $value=$null
            switch($key.Key){
                'UpArrow' {$value=[byte][char]'W'}
                'RightArrow' {$value=[byte][char]'D'}
                'DownArrow' {$value=[byte][char]'S'}
                'LeftArrow' {$value=[byte][char]'A'}
                'W' {$value=[byte][char]'W'}
                'A' {$value=[byte][char]'A'}
                'S' {$value=[byte][char]'S'}
                'D' {$value=[byte][char]'D'}
                'R' {$value=[byte][char]'R'}
                'Q' {$quit=$true}
            }
            if($null -ne $value){Send-KeyByte $value}
        }
        while($serial.BytesToRead -gt 0){
            $value=$serial.ReadByte()
            if($packetIndex -eq 0){
                if($value -ne 0xA5){continue}
                $packet[0]=[byte]$value
                $packetIndex=1
            } else {
                $packet[$packetIndex]=[byte]$value
                $packetIndex++
                if($packetIndex -eq 68){
                    Render-Frame $packet
                    $packetIndex=0
                }
            }
        }
        Start-Sleep -Milliseconds 2
    }
} finally {
    if($serial.IsOpen){$serial.Close()}
    $serial.Dispose()
}
