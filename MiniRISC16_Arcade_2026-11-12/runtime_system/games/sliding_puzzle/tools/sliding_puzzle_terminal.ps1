param([string]$PortName='COM3',[int]$BaudRate=115200,[switch]$NoColor)
$ErrorActionPreference='Stop'
$serial=[IO.Ports.SerialPort]::new($PortName,$BaudRate,[IO.Ports.Parity]::None,8,[IO.Ports.StopBits]::One)
$serial.ReadTimeout=3000
$serial.WriteTimeout=3000
function Exchange([string]$command) {
    $serial.Write($command)
    do { $b=$serial.ReadByte() } while($b -ne 165)
    $size=$serial.ReadByte()
    if($size -lt 3 -or $size -gt 6){throw 'Invalid frame size'}
    $tiles=@(for($i=0;$i -lt $size*$size;$i++){$serial.ReadByte()})
    if(@($tiles | Sort-Object -Unique).Count -ne $size*$size -or ($tiles | Measure-Object -Maximum).Maximum -ne $size*$size-1){throw 'Invalid board frame'}
    return ,$tiles
}
function Solved($tiles) {
    for($i=0;$i -lt $tiles.Count-1;$i++){if($tiles[$i] -ne $i+1){return $false}}
    return $tiles[-1] -eq 0
}
try {
    $serial.Open()
    $serial.DiscardInBuffer()
    Write-Host 'Set SW7=0, then press Enter.'
    [void][Console]::ReadLine()
    $serial.DiscardInBuffer()
    $quit=$false
    while(-not $quit){
        Clear-Host
        Write-Host 'SLIDING PUZZLE - choose size: 3 / 4 / 5 / 6 (Enter = 4), Q = menu'
        $key=[Console]::ReadKey($true)
        if($key.Key -eq 'Q'){break}
        $n=4
        if([string]$key.KeyChar -match '^[3-6]$'){$n=[int]::Parse([string]$key.KeyChar)}
        $restart=$true
        while($restart){
            $restart=$false
            $tiles=Exchange ([string]$n)
            $last=''
            Write-Host 'Shuffling on FPGA...'
            for($step=0;$step -lt $n*$n*20;$step++){
                $blank=[Array]::IndexOf($tiles,0)
                $row=[int][Math]::Floor($blank/$n); $col=$blank % $n
                $choices=@()
                if($row -gt 0 -and $last -ne 's'){$choices+='w'}
                if($row -lt $n-1 -and $last -ne 'w'){$choices+='s'}
                if($col -gt 0 -and $last -ne 'd'){$choices+='a'}
                if($col -lt $n-1 -and $last -ne 'a'){$choices+='d'}
                $last=$choices | Get-Random
                $tiles=Exchange $last
            }
            if(Solved $tiles){$tiles=Exchange 'w'}
            $moves=0
            while($true){
                Clear-Host
                Write-Host "SLIDING PUZZLE  $n x $n    Moves: $moves"
                Write-Host 'Arrows/WASD: move blank | R: shuffle | Esc: sizes | Q: menu'
                for($row=0;$row -lt $n;$row++){
                    $line=''
                    for($col=0;$col -lt $n;$col++){
                        $v=$tiles[$row*$n+$col]
                        $line+=if($v -eq 0){' [  ]'}else{' {0,3} '-f $v}
                    }
                    Write-Host $line
                }
                $won=Solved $tiles
                if($won){Write-Host 'SOLVED! R: new puzzle | Esc: sizes'}
                $key=[Console]::ReadKey($true)
                if($key.Key -eq 'Q'){$quit=$true;break}
                if($key.Key -eq 'Escape'){break}
                if($key.Key -eq 'R'){$restart=$true;break}
                if($won){continue}
                $command=switch($key.Key){'UpArrow'{'w'} 'W'{'w'} 'DownArrow'{'s'} 'S'{'s'} 'LeftArrow'{'a'} 'A'{'a'} 'RightArrow'{'d'} 'D'{'d'} default{''}}
                if($command){
                    $before=$tiles -join ','
                    $tiles=Exchange $command
                    if(($tiles -join ',') -ne $before){$moves++}
                }
            }
        }
    }
} finally {if($serial.IsOpen){$serial.Close()};$serial.Dispose()}
