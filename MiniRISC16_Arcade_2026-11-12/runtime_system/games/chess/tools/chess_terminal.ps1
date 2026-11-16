param([string]$PortName='COM3',[int]$BaudRate=115200,[switch]$NoColor)
$ErrorActionPreference='Stop'
$serial=[IO.Ports.SerialPort]::new($PortName,$BaudRate,[IO.Ports.Parity]::None,8,[IO.Ports.StopBits]::One)
$serial.ReadTimeout=30000;$serial.WriteTimeout=3000
function Exchange([byte[]]$command){
    $serial.Write($command,0,$command.Length)
    do{$b=$serial.ReadByte()}while($b -ne 165)
    $frame=[byte[]]::new(70);$frame[0]=165
    for($i=1;$i -lt 70;$i++){$frame[$i]=$serial.ReadByte()}
    $sum=0;foreach($v in $frame){$sum=$sum -bxor $v}
    if($sum -ne 0 -or $frame[1] -ne 7){throw 'Expected chess protocol v7. Upload the current chess.mem through menu 6, then reconnect.'}
    return ,$frame
}
function Choose-Mode {
    Clear-Host
    Write-Host 'CHESS - SELECT MODE'
    Write-Host '1: Two players | 2: CPU opponent (you play white) | Q: return to arcade'
    while($true){
        $choice=[Console]::ReadKey($true)
        if($choice.Key -eq 'Q'){return $null}
        if($choice.KeyChar -eq '1'){return [byte]245}
        if($choice.KeyChar -eq '2'){return [byte]244}
    }
}
try{
    $serial.Open()
    Write-Host 'Set SW7=0, then press Enter.'
    [void][Console]::ReadLine();$serial.DiscardInBuffer()
    $command=Choose-Mode
    if($null -eq $command){return}
    $frame=Exchange ([byte[]]@($command))
    $x=4;$y=1;$selected=-1
    while($true){
        Clear-Host
        $turn=if(($frame[2] -band 8) -eq 0){'WHITE (uppercase)'}else{'BLACK (lowercase)'}
        $mode=if($frame[2] -band 64){'CPU opponent'}else{'Two players'}
        Write-Host "CHESS | $mode | Turn: $turn"
        Write-Host 'Arrows/WASD: cursor | Space/Enter: move | Esc: cancel | R: restart | M: modes | Q: menu'
        Write-Host 'P pawn  N knight  B bishop  R rook  Q queen  K king'
        Write-Host '    a  b  c  d  e  f  g  h'
        for($rank=7;$rank -ge 0;$rank--){
            $line=" $($rank+1) "
            for($file=0;$file -lt 8;$file++){
                $v=$frame[5+$rank*8+$file]
                $symbol=' PNBRQK'[$v -band 7]
                if($v -eq 0){$symbol='.'}elseif($v -band 8){$symbol=([string]$symbol).ToLowerInvariant()}
                $line+=if($rank -eq $y -and $file -eq $x){"[$symbol]"}elseif($selected -eq $rank*16+$file){"<$symbol>"}else{" $symbol "}
            }
            Write-Host $line
        }
        switch($frame[3]){1{Write-Host 'CHECK'} 2{Write-Host 'CHECKMATE - WHITE WINS'} 3{Write-Host 'CHECKMATE - BLACK WINS'} 4{Write-Host 'STALEMATE - DRAW'}}
        if($frame[4]){Write-Host 'Illegal move. Select a piece and try again.'}
        Write-Host 'First version: no repetition / move-count / dead-position draw adjudication.'
        $key=[Console]::ReadKey($true)
        if($key.Key -eq 'Q'){break}
        if($key.Key -eq 'M'){
            $command=Choose-Mode
            if($null -eq $command){break}
            $frame=Exchange ([byte[]]@($command));$selected=-1
            continue
        }
        switch($key.Key){
            'Escape'{$selected=-1}
            'R'{$frame=Exchange ([byte[]]@(240));$selected=-1}
            {$_ -in 'UpArrow','W'}{$y=($y+1)%8}
            {$_ -in 'DownArrow','S'}{$y=($y+7)%8}
            {$_ -in 'LeftArrow','A'}{$x=($x+7)%8}
            {$_ -in 'RightArrow','D'}{$x=($x+1)%8}
            {$_ -in 'Spacebar','Enter'}{
                if($frame[3] -ge 2){continue}
                if($selected -lt 0){$selected=$y*16+$x}else{
                    $promote=0
                    $sourceRank=[int][Math]::Floor($selected/16)
                    $piece=$frame[5+$sourceRank*8+($selected%16)]
                    if(($piece -band 7) -eq 1 -and $y -in @(0,7)){
                        Write-Host 'Promote: Q queen / R rook / B bishop / N knight (Enter queen)'
                        do{$choice=[Console]::ReadKey($true).Key}while($choice -notin @('Q','R','B','N','Enter'))
                        $promote=switch($choice){'R'{4} 'B'{3} 'N'{2} default{5}}
                    }
                    Write-Host 'CPU processing move / reply...'
                    $frame=Exchange ([byte[]]@(242,$selected,($y*16+$x),$promote))
                    $selected=-1
                }
            }
        }
    }
}finally{if($serial.IsOpen){$serial.Close()};$serial.Dispose()}
