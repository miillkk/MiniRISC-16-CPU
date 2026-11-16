param([string]$Program = '')

$ErrorActionPreference = 'Stop'
$gameRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if (-not $Program) { $Program = Join-Path $gameRoot 'program\running_light.mem' }

$rom = New-Object 'UInt16[]' 1024
$address = 0
foreach ($sourceLine in Get-Content -LiteralPath $Program) {
    $line = ($sourceLine -replace '//.*$','').Trim()
    if (-not $line) { continue }
    if ($line -match '^@([0-9A-Fa-f]+)$') {
        $address = [Convert]::ToInt32($Matches[1],16)
        continue
    }
    $rom[$address++] = [Convert]::ToUInt16($line,16)
}

$script:pc = 0
$script:regs = New-Object 'UInt16[]' 4
$script:data = New-Object 'UInt16[]' 256
$script:z = $false
$script:n = $false
$script:c = $false
$script:v = $false
$script:rxQueue = [Collections.Generic.Queue[byte]]::new()
$script:txBytes = [Collections.Generic.List[byte]]::new()
$script:tickPending = $false
$script:switches = 0
$script:led = 0
$script:displayControl = 0
$script:steps = 0
$script:frameCount = 0

function Set-AddFlags([int]$a,[int]$b,[int]$sum) {
    $result = $sum -band 0xFFFF
    $script:z = ($result -eq 0)
    $script:n = (($result -band 0x8000) -ne 0)
    $script:c = ($sum -gt 0xFFFF)
    $script:v = (((-bnot($a -bxor $b)) -band ($result -bxor $a) -band 0x8000) -ne 0)
}
function Set-SubFlags([int]$a,[int]$b,[int]$result) {
    $result = $result -band 0xFFFF
    $script:z = ($result -eq 0)
    $script:n = (($result -band 0x8000) -ne 0)
    $script:c = ($a -ge $b)
    $script:v = ((($a -bxor $b) -band ($result -bxor $a) -band 0x8000) -ne 0)
}
function Read-Io([int]$port) {
    switch ($port) {
        0x10 { if ($script:rxQueue.Count) { return [int]$script:rxQueue.Dequeue() }; return 0 }
        0x11 { return 2 -bor $(if ($script:rxQueue.Count) { 1 } else { 0 }) }
        0x12 { $value=$(if($script:tickPending){1}else{0}); $script:tickPending=$false; return $value }
        0x30 { return $script:led }
        0x31 { return $script:switches }
        0x32 { return (([int]$script:v -shl 6) -bor ([int]$script:c -shl 5) -bor ([int]$script:n -shl 4) -bor ([int]$script:z -shl 3)) }
        default { return 0 }
    }
}
function Write-Io([int]$port,[int]$value) {
    switch ($port) {
        0x10 { $script:txBytes.Add([byte]($value -band 0xFF)); break }
        0x22 { $script:displayControl = $value -band 0xFFFF; break }
        0x30 { $script:led = $value -band 0xFF; break }
    }
}
function Step-Cpu {
    if (++$script:steps -gt 1000000) { throw 'Running-light reference-model instruction limit exceeded.' }
    $currentPc = $script:pc
    $ins = [int]$rom[$currentPc]
    $script:pc = ($script:pc + 1) -band 0x3FF
    $op = ($ins -shr 12) -band 0xF
    $rd = ($ins -shr 10) -band 3
    $rs = ($ins -shr 8) -band 3
    $imm = $ins -band 0xFF
    $a = [int]$script:regs[$rd]
    $b = [int]$script:regs[$rs]
    switch ($op) {
        0x0 { $script:regs[$rd]=[UInt16]$imm }
        0x1 { $script:regs[$rd]=[UInt16]$b }
        0x2 { $sum=$a+$imm; Set-AddFlags $a $imm $sum; $script:regs[$rd]=[UInt16]($sum -band 0xFFFF) }
        0x3 { $sum=$a+$b; Set-AddFlags $a $b $sum; $script:regs[$rd]=[UInt16]($sum -band 0xFFFF) }
        0x4 { $script:regs[$rd]=[UInt16](($a -bxor $b) -band 0xFFFF) }
        0x5 { $result=($a-$b) -band 0xFFFF; Set-SubFlags $a $b $result; $script:regs[$rd]=[UInt16]$result }
        0x6 { $result=($a-$b) -band 0xFFFF; Set-SubFlags $a $b $result }
        0x7 { $script:regs[$rd]=[UInt16](($a -band $b) -band 0xFFFF) }
        0x8 { if($script:z){$script:pc=($currentPc -band 0x300) -bor $imm} }
        0x9 { $script:regs[$rd]=[UInt16](($a -bor $b) -band 0xFFFF) }
        0xA { $script:pc=($currentPc -band 0x300) -bor $imm }
        0xB { $script:regs[$rd]=[UInt16](Read-Io $imm) }
        0xC { Write-Io $imm $b }
        0xD { $script:regs[$rd]=$script:data[$b -band 0xFF] }
        0xE { $script:data[$a -band 0xFF]=[UInt16]$b }
        0xF { $script:pc=$ins -band 0x3FF }
    }
}
function Run-ToNextFrame {
    $script:frameCount++
    $target = $script:frameCount * 12
    while($script:txBytes.Count -lt $target){Step-Cpu}
    return @($script:txBytes[($target-12)..($target-1)])
}
function Assert-Equal($actual,$expected,[string]$message) {
    if($actual -ne $expected){throw "$message expected=$expected actual=$actual"}
}
function Assert-Frame($frame,[int]$sequence,[int]$pattern,[int]$position,[int]$direction,[int]$lastKey) {
    Assert-Equal $frame.Count 12 'frame length'
    Assert-Equal $frame[0] 0xA5 'frame sync'
    Assert-Equal $frame[1] 4 'protocol version'
    Assert-Equal $frame[2] 12 'declared length'
    Assert-Equal $frame[3] 3 'game identifier'
    Assert-Equal $frame[4] ($sequence -band 0xFF) 'sequence'
    Assert-Equal $frame[5] $pattern 'LED pattern'
    Assert-Equal $frame[6] $position 'LED position'
    Assert-Equal $frame[7] $direction 'direction'
    Assert-Equal $frame[10] $lastKey 'last key'
    $checksum=0
    foreach($index in 0..10){$checksum=$checksum -bxor $frame[$index]}
    Assert-Equal $frame[11] ($checksum -band 0xFF) 'XOR checksum'
}

$frame=Run-ToNextFrame
Assert-Frame $frame 0 0x01 0 0 0
Assert-Equal $script:led 0x01 'initial board LED'
Assert-Equal $script:displayControl 1 'display enabled'

$script:tickPending=$true
$frame=Run-ToNextFrame
Assert-Frame $frame 1 0x02 1 0 0
Assert-Equal $script:led 0x02 'first right step'

$script:rxQueue.Enqueue([byte][char]'A')
$frame=Run-ToNextFrame
Assert-Frame $frame 2 0x02 1 1 0x41

$script:tickPending=$true
$frame=Run-ToNextFrame
Assert-Frame $frame 3 0x01 0 1 0x41

$script:tickPending=$true
$frame=Run-ToNextFrame
Assert-Frame $frame 4 0x80 7 1 0x41
Assert-Equal $script:led 0x80 'left wrap'

$script:switches=0x03
$script:rxQueue.Enqueue([byte][char]'D')
$frame=Run-ToNextFrame
Assert-Frame $frame 5 0x80 7 0 0x44
Assert-Equal $frame[8] 3 'speed switch metadata'
Assert-Equal $frame[9] 3 'full switch metadata'

$script:tickPending=$true
$frame=Run-ToNextFrame
Assert-Frame $frame 6 0x01 0 0 0x44
Assert-Equal $script:led 0x01 'right wrap'

$script:switches=0x04
$frame=Run-ToNextFrame
Assert-Frame $frame 7 0x01 0 0 0x44
Assert-Equal $frame[9] 4 'pause switch metadata'

$script:switches=0x00
$frame=Run-ToNextFrame
Assert-Frame $frame 8 0x01 0 0 0x44

$script:rxQueue.Enqueue([byte][char]'R')
$frame=Run-ToNextFrame
Assert-Frame $frame 0 0x01 0 0 0

$reportDir=Join-Path $gameRoot 'reports'
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
$summary=@(
    'MiniRISC-16 Running Light independent reference model',
    'PASS protocol v4 game-id, sequence and XOR checksum',
    'PASS one-hot LED pattern and right movement',
    'PASS A/D direction control',
    'PASS left and right edge wrap',
    'PASS speed/pause switch metadata and R restart',
    "Instructions executed: $($script:steps)",
    'REFERENCE MODEL PASS'
)
[IO.File]::WriteAllLines((Join-Path $reportDir 'reference-model.log'),$summary,[Text.UTF8Encoding]::new($false))
$summary
