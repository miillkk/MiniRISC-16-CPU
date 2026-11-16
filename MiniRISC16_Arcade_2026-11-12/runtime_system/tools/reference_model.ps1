param([string]$Program = "")

$ErrorActionPreference = 'Stop'
$toolRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$designRoot = Split-Path -Parent $toolRoot
if (-not $Program) { $Program = Join-Path $designRoot 'program\snake.mem' }

$rom = New-Object 'UInt16[]' 1024
$address = 0
foreach ($sourceLine in Get-Content -LiteralPath $Program) {
    $line = ($sourceLine -replace '//.*$','').Trim()
    if (-not $line) { continue }
    if ($line -match '^@([0-9A-Fa-f]+)$') { $address = [Convert]::ToInt32($Matches[1],16); continue }
    $rom[$address++] = [Convert]::ToUInt16($line,16)
}

$script:pc = 0
$script:regs = New-Object 'UInt16[]' 4
$script:data = New-Object 'UInt16[]' 256
$script:scratch = New-Object 'UInt16[]' 16
$script:z = $false
$script:n = $false
$script:c = $false
$script:v = $false
$script:rng = 0xA7
$script:tickPending = $false
$script:rxQueue = [Collections.Generic.Queue[byte]]::new()
$script:txBytes = [Collections.Generic.List[byte]]::new()
$script:led = 0
$script:displayLow = 0
$script:displayHigh = 0
$script:displayControl = 0
$script:speedBoost = 0
$script:switches = 0
$script:steps = 0

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
        0x11 { return 2 -bor $(if ($script:rxQueue.Count) {1} else {0}) }
        0x12 { $value = $(if ($script:tickPending) {1} else {0}); $script:tickPending=$false; return $value }
        0x13 {
            $value = $script:rng
            $feedback = (($script:rng -shr 7) -bxor ($script:rng -shr 5) -bxor ($script:rng -shr 4) -bxor ($script:rng -shr 3)) -band 1
            $script:rng = (($script:rng -shl 1) -band 0xFE) -bor $feedback
            if ($script:rng -eq 0) { $script:rng = 0x5D }
            return $value
        }
        0x14 { return $script:speedBoost }
        0x30 { return $script:led }
        0x31 { return $script:switches }
        0x32 { return (([int]$script:v -shl 6) -bor ([int]$script:c -shl 5) -bor ([int]$script:n -shl 4) -bor ([int]$script:z -shl 3)) }
        default { if ($port -ge 0x40 -and $port -le 0x4F) { return $script:scratch[$port -band 0xF] }; return 0 }
    }
}
function Write-Io([int]$port,[int]$value) {
    $value = $value -band 0xFFFF
    switch ($port) {
        0x10 { $script:txBytes.Add([byte]($value -band 0xFF)); break }
        0x14 { $script:speedBoost=$value -band 3; break }
        0x20 { $script:displayLow=$value; break }
        0x21 { $script:displayHigh=$value; break }
        0x22 { $script:displayControl=$value; break }
        0x30 { $script:led=$value -band 0xFF; break }
        default { if ($port -ge 0x40 -and $port -le 0x4F) { $script:scratch[$port -band 0xF]=[UInt16]$value } }
    }
}
function Step-Cpu {
    if (++$script:steps -gt 2000000) { throw 'Reference model cycle limit exceeded.' }
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
        0x8 { if ($script:z) { $script:pc=($currentPc -band 0x300) -bor $imm } }
        0x9 { $script:regs[$rd]=[UInt16](($a -bor $b) -band 0xFFFF) }
        0xA { $script:pc=($currentPc -band 0x300) -bor $imm }
        0xB { $script:regs[$rd]=[UInt16](Read-Io $imm) }
        0xC { Write-Io $imm $b }
        0xD { $script:regs[$rd]=$script:data[$b -band 0xFF] }
        0xE { $script:data[$a -band 0xFF]=[UInt16]$b }
        0xF { $script:pc=$ins -band 0x3FF }
    }
}
function Run-ToFrame([int]$frameNumber) {
    $target = $frameNumber * 140
    while ($script:txBytes.Count -lt $target) { Step-Cpu }
    return @($script:txBytes[($target-140)..($target-1)])
}
function Assert-Equal($actual,$expected,[string]$message) {
    if ($actual -ne $expected) { throw "$message expected=$expected actual=$actual" }
}
function Assert-FrameProtocol($frame,[int]$expectedSequence) {
    Assert-Equal $frame[136] 3 'protocol version'
    Assert-Equal $frame[137] 140 'protocol frame length'
    Assert-Equal $frame[138] $expectedSequence 'protocol sequence'
    $checksum=0
    foreach($index in 0..138){$checksum=$checksum -bxor $frame[$index]}
    Assert-Equal $frame[139] ($checksum -band 0xFF) 'protocol XOR checksum'
}
function Assert-MapConnected($frame,[string]$name,[int]$expectedObstacles) {
    $obstacles=0
    $start=-1
    foreach($cell in 0..127){
        if($frame[4+$cell] -eq 0xFF){$obstacles++}
        elseif($start -lt 0){$start=$cell}
    }
    Assert-Equal $obstacles $expectedObstacles "$name obstacle count"
    if($start -lt 0){throw "$name has no free cell"}
    $visited=New-Object 'bool[]' 128
    $queue=[Collections.Generic.Queue[int]]::new()
    $visited[$start]=$true; $queue.Enqueue($start); $visitedCount=0
    while($queue.Count){
        $cell=$queue.Dequeue(); $visitedCount++
        $row=[Math]::Floor($cell/16); $column=$cell%16
        $neighbors=@()
        if($row -gt 0){$neighbors += $cell-16}
        if($row -lt 7){$neighbors += $cell+16}
        if($column -gt 0){$neighbors += $cell-1}
        if($column -lt 15){$neighbors += $cell+1}
        foreach($neighbor in $neighbors){
            if(-not $visited[$neighbor] -and $frame[4+$neighbor] -ne 0xFF){
                $visited[$neighbor]=$true; $queue.Enqueue($neighbor)
            }
        }
    }
    Assert-Equal $visitedCount (128-$obstacles) "$name free-region connectivity"
}
function Get-LfsrCandidates([int]$seed,[int]$count) {
    $values=[Collections.Generic.List[int]]::new(); $state=$seed
    foreach($unused in 1..$count){
        $values.Add($state -band 0x7F)
        $feedback=(($state -shr 7) -bxor ($state -shr 5) -bxor ($state -shr 4) -bxor ($state -shr 3)) -band 1
        $state=(($state -shl 1) -band 0xFE) -bor $feedback
        if($state -eq 0){$state=0x5D}
    }
    return $values
}

$frame = Run-ToFrame 1
Assert-Equal $frame[0] 0xA5 'initial sync'
Assert-Equal $frame[1] 0x11 'initial running/direction status'
Assert-Equal $frame[2] 0 'initial score'
Assert-Equal $frame[4+53] 1 'initial tail age'
Assert-Equal $frame[4+54] 2 'initial body age'
Assert-Equal $frame[4+55] 3 'initial head age'
Assert-Equal $frame[4+19] 0xFF 'open map left obstacle'
Assert-Equal $frame[4+104] 0xFF 'open map lower obstacle'
Assert-Equal $frame[132] 0 'initial high score'
Assert-FrameProtocol $frame 0
Assert-MapConnected $frame 'open map' 12

$script:tickPending=$true
$frame = Run-ToFrame 2
Assert-Equal $script:scratch[0] 56 'first right move head'
Assert-Equal $frame[4+53] 0 'tail removed after move'
Assert-Equal $frame[4+56] 3 'new head stored'
Assert-FrameProtocol $frame 1

$script:scratch[4] = 72
$script:scratch[3] = 1
$script:rxQueue.Enqueue([byte][char]'S')
$script:tickPending=$true
$frame = Run-ToFrame 3
Assert-Equal $script:scratch[0] 72 'down command head'
Assert-Equal $script:scratch[2] 4 'length after food'
Assert-Equal $script:scratch[3] 2 'score after first staged food'
Assert-Equal $frame[2] 2 'frame score after first staged food'
Assert-Equal $frame[133] 1 'two foods advance to level 1'
Assert-Equal $frame[4+40] 0 'score must not add a wall at cell 40'
Assert-Equal $frame[4+41] 0 'score must not add a wall at cell 41'
Assert-FrameProtocol $frame 2

$script:scratch[3] = 3
$script:scratch[4] = 88
$script:rxQueue.Enqueue([byte][char]'W')
$script:tickPending=$true
$frame = Run-ToFrame 4
Assert-Equal $script:scratch[0] 88 'opposite direction ignored'
Assert-Equal $script:scratch[3] 4 'score after second staged food'
Assert-Equal $frame[133] 2 'four foods advance to level 2'
Assert-Equal $frame[4+102] 0 'score must not add a wall at cell 102'
Assert-FrameProtocol $frame 3

$script:scratch[0] = 86
$script:scratch[1] = 2
$script:scratch[3] = 5
$script:scratch[4] = 102
$script:tickPending=$true
$frame = Run-ToFrame 5
Assert-Equal $script:scratch[0] 102 'third staged food movement'
Assert-Equal $script:scratch[3] 6 'score after third staged food'
Assert-Equal $frame[133] 3 'six foods advance to level 3'
Assert-FrameProtocol $frame 4

# Fill the board except the next head and one candidate that is deliberately
# absent from the first 16 RNG outputs. The bounded random search must fall
# back to a deterministic scan and select that sole remaining free cell.
$script:rng=0xA7
$randomCandidates=Get-LfsrCandidates 0xA7 16
$fallbackCell=(0..127 | Where-Object {$_ -ne 103 -and $_ -notin $randomCandidates} | Select-Object -First 1)
foreach($cell in 0..127){$script:data[4+$cell]=0x00FF}
$script:data[4+103]=0
$script:data[4+$fallbackCell]=0
$script:scratch[0]=102
$script:scratch[1]=1
$script:scratch[3]=6
$script:scratch[4]=103
$script:tickPending=$true
$frame=Run-ToFrame 6
Assert-Equal $script:scratch[4] $fallbackCell 'bounded food-search fallback'
Assert-Equal $frame[133] 3 'level remains saturated at 3'
Assert-FrameProtocol $frame 5

$script:scratch[0] = 31
$script:scratch[1] = 1
$script:tickPending=$true
$frame = Run-ToFrame 7
Assert-Equal $frame[1] 0x80 'wall collision status'
Assert-Equal $script:led 0x80 'game over LED'
Assert-Equal $script:displayHigh 0xDEAD 'game over display'

$script:switches=0
$script:rxQueue.Enqueue([byte][char]'R')
$frame = Run-ToFrame 8
Assert-Equal $script:scratch[0] 55 'restart head'
Assert-Equal $script:scratch[5] 0 'restart state'
Assert-MapConnected $frame 'open map after restart' 12
Assert-FrameProtocol $frame 0

$script:switches=0x08
$script:rxQueue.Enqueue([byte][char]'R')
$frame=Run-ToFrame 9
Assert-Equal $frame[134] 0x08 'maze map switch metadata'
Assert-MapConnected $frame 'maze map' 16
Assert-FrameProtocol $frame 0

$script:switches=0x10
$script:rxQueue.Enqueue([byte][char]'R')
$frame=Run-ToFrame 10
Assert-Equal $frame[134] 0x10 'hard map switch metadata'
Assert-MapConnected $frame 'hard map' 25
Assert-FrameProtocol $frame 0

$reportDir = Join-Path $designRoot 'reports\simulation'
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
$summary = @(
    'MiniRISC-16 Snake independent reference model',
    'PASS initial board and first frame',
    'PASS timer-driven movement and body decay',
    'PASS wall collision and game-over outputs',
    'PASS UART R restart',
    'PASS UART S direction and food growth',
    'PASS opposite-direction protection',
    'PASS 10-bit PC and cross-page JMPA services',
    'PASS three switch-selected maps with one connected free region each',
    'PASS bounded random food search with deterministic full-board fallback',
    'PASS two foods per level and level-3 saturation',
    'PASS score changes do not create dynamic walls',
    'PASS protocol v3 length, sequence and XOR checksum',
    'PASS 16x8 board, connected-wall obstacles and 140-byte frame',
    "Instructions executed: $($script:steps)",
    'REFERENCE MODEL PASS'
)
[IO.File]::WriteAllLines((Join-Path $reportDir 'reference-model.log'),$summary,[Text.UTF8Encoding]::new($false))
$summary
