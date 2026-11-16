param([Parameter(Mandatory=$true)][string]$PortName,[string]$Program='',[int]$BaudRate=115200)
$ErrorActionPreference='Stop'
if(-not $Program){$Program=Join-Path $PSScriptRoot '..\program\chess.mem'}
$words=@(Get-Content -LiteralPath $Program | Where-Object {$_ -match '^[0-9a-fA-F]{4}$'} | ForEach-Object {[Convert]::ToUInt16($_,16)})
if($words.Count -ne 4096){throw 'Expected the 4096-word chess image.'}
$serial=[IO.Ports.SerialPort]::new($PortName,$BaudRate,[IO.Ports.Parity]::None,8,[IO.Ports.StopBits]::One)
$serial.ReadTimeout=5000;$serial.WriteTimeout=5000
try{
    $serial.Open();$serial.DiscardInBuffer()
    $serial.Write([byte[]]@(0x55,0x49),0,2)
    $info=@(for($i=0;$i -lt 7;$i++){$serial.ReadByte()})
    if(($info[0..3] -join ',') -ne '77,82,49,54'){throw 'Invalid loader identity. Set SW7=1.'}
    $capacity=($info[4] -shl 8) -bor $info[5]
    if($capacity -lt 4096){throw "Board has $capacity words. Program MiniRISC16_Arcade4K.bit in Vivado first; chess was not uploaded."}
    $packet=[Collections.Generic.List[byte]]::new()
    foreach($v in @(0x55,0x4C,0x10,0)){$packet.Add([byte]$v)}
    $sum=0
    foreach($w in $words){$packet.Add([byte]($w -shr 8));$packet.Add([byte]($w -band 255));$sum=($sum+$w) -band 65535}
    $packet.Add([byte]($sum -shr 8));$packet.Add([byte]($sum -band 255))
    $serial.Write($packet.ToArray(),0,$packet.Count)
    if($serial.ReadByte() -ne 6){throw 'Loader rejected chess image.'}
    Write-Host 'UPLOAD PASS: 4096 words. Set SW7=0 when the terminal asks.'
}finally{if($serial.IsOpen){$serial.Close()};$serial.Dispose()}
