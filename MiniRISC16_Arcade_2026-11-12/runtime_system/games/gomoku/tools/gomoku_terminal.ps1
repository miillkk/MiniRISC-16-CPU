param([string]$PortName='COM3',[int]$BaudRate=115200,[switch]$NoColor)
$ErrorActionPreference='Stop'
$serial=[IO.Ports.SerialPort]::new($PortName,$BaudRate,[IO.Ports.Parity]::None,8,[IO.Ports.StopBits]::One)
$serial.ReadTimeout=30000
$serial.WriteTimeout=3000
function Exchange([byte]$command){
    $serial.Write([byte[]]@($command),0,1)
    do{$b=$serial.ReadByte()}while($b -ne 165)
    $frame=[byte[]]::new(231);$frame[0]=165
    for($i=1;$i -lt 231;$i++){$frame[$i]=$serial.ReadByte()}
    $sum=0;foreach($v in $frame){$sum=$sum -bxor $v}
    if($sum -ne 0){throw 'Frame checksum error. Reconnect to resynchronize.'}
    return ,$frame
}
try{
    $serial.Open()
    Write-Host 'Set SW7=0, then press Enter.'
    [void][Console]::ReadLine()
    $serial.DiscardInBuffer()
    $quit=$false
    while(-not $quit){
        Clear-Host
        Write-Host 'GOMOKU 15 x 15'
        Write-Host '1: Two players   2: CPU opponent (you play black)   Q: menu'
        $key=[Console]::ReadKey($true)
        if($key.Key -eq 'Q'){break}
        if($key.KeyChar -notin @('1','2')){continue}
        $command=if($key.KeyChar -eq '2'){241}else{240}
        $frame=Exchange $command
        $row=7;$col=7
        while($true){
            Clear-Host
            $mode=if($frame[1]){'CPU opponent'}else{'Two players'}
            $turn=if($frame[2] -eq 1){'Black X'}else{'White O'}
            Write-Host "GOMOKU | $mode | Turn: $turn | Stones: $($frame[4])"
            Write-Host 'Arrows/WASD: cursor | Space/Enter: place | R: restart | Esc: modes | Q: menu'
            Write-Host 'Black X, White O; five or more wins; no forbidden moves.'
            for($y=0;$y -lt 15;$y++){
                $line=''
                for($x=0;$x -lt 15;$x++){
                    $stone=switch($frame[5+$y*15+$x]){0{'.'} 1{'X'} 2{'O'} default{'?'}}
                    $line+=if($y -eq $row -and $x -eq $col){"[$stone]"}else{" $stone "}
                }
                Write-Host $line
            }
            switch($frame[3]){1{Write-Host 'BLACK WINS'} 2{Write-Host 'WHITE WINS'} 3{Write-Host 'DRAW'}}
            $key=[Console]::ReadKey($true)
            switch($key.Key){
                'Q'{$quit=$true}
                'R'{$frame=Exchange 242}
                {$_ -in 'UpArrow','W'}{$row=($row+14)%15}
                {$_ -in 'DownArrow','S'}{$row=($row+1)%15}
                {$_ -in 'LeftArrow','A'}{$col=($col+14)%15}
                {$_ -in 'RightArrow','D'}{$col=($col+1)%15}
                {$_ -in 'Spacebar','Enter'}{
                    if($frame[3] -eq 0){
                        Write-Host 'CPU processing move...'
                        $frame=Exchange ([byte]($row*15+$col))
                    }
                }
            }
            if($quit -or $key.Key -eq 'Escape'){break}
        }
    }
}finally{if($serial.IsOpen){$serial.Close()};$serial.Dispose()}
