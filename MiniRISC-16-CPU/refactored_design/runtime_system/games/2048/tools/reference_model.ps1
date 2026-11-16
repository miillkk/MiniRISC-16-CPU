param([string]$Program = '')

$ErrorActionPreference = 'Stop'
$gameRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if (-not $Program) { $Program = Join-Path $gameRoot 'program\game_2048.mem' }

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
$script:rng = 0xA7
$script:rxQueue = [Collections.Generic.Queue[byte]]::new()
$script:txBytes = [Collections.Generic.List[byte]]::new()
$script:led = 0
$script:displayLow = 0
$script:displayHigh = 0
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
        0x13 {
            $value = $script:rng
            $feedback = (($script:rng -shr 7) -bxor ($script:rng -shr 5) -bxor ($script:rng -shr 4) -bxor ($script:rng -shr 3)) -band 1
            $script:rng = (($script:rng -shl 1) -band 0xFE) -bor $feedback
            if ($script:rng -eq 0) { $script:rng = 0x5D }
            return $value
        }
        0x32 { return (([int]$script:v -shl 6) -bor ([int]$script:c -shl 5) -bor ([int]$script:n -shl 4) -bor ([int]$script:z -shl 3)) }
        default { return 0 }
    }
}
function Write-Io([int]$port,[int]$value) {
    switch ($port) {
        0x10 { $script:txBytes.Add([byte]($value -band 0xFF)); break }
        0x20 { $script:displayLow = $value -band 0xFFFF; break }
        0x21 { $script:displayHigh = $value -band 0xFFFF; break }
        0x22 { $script:displayControl = $value -band 0xFFFF; break }
        0x30 { $script:led = $value -band 0xFF; break }
    }
}
function Step-Cpu {
    if (++$script:steps -gt 2000000) { throw '2048 reference-model instruction limit exceeded.' }
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
        0x0 { $script:regs[$rd] = [UInt16]$imm }
        0x1 { $script:regs[$rd] = [UInt16]$b }
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
function Run-ToNextFrame {
    $script:frameCount++
    $target = $script:frameCount * 27
    while ($script:txBytes.Count -lt $target) { Step-Cpu }
    return @($script:txBytes[($target-27)..($target-1)])
}
function Assert-Equal($actual,$expected,[string]$message) {
    if ($actual -ne $expected) { throw "$message expected=$expected actual=$actual" }
}
function Assert-Frame($frame,[int]$expectedSequence) {
    Assert-Equal $frame.Count 27 'frame length'
    Assert-Equal $frame[0] 0xA5 'frame sync'
    Assert-Equal $frame[1] 4 'protocol version'
    Assert-Equal $frame[2] 27 'protocol declared length'
    Assert-Equal $frame[3] 2 'game identifier'
    Assert-Equal $frame[5] ($expectedSequence -band 0xFF) 'frame sequence'
    Assert-Equal $frame[8] 4 'board width'
    Assert-Equal $frame[9] 4 'board height'
    $checksum = 0
    foreach ($index in 0..25) { $checksum = $checksum -bxor $frame[$index] }
    Assert-Equal $frame[26] ($checksum -band 0xFF) 'frame checksum'
}
function Set-Board([int[]]$cells) {
    if ($cells.Count -ne 16) { throw 'A test board must contain 16 cells.' }
    foreach ($index in 0..15) { $script:data[0x40+$index] = [UInt16]$cells[$index] }
    foreach ($address in (0x30..0x36 + 0x38..0x3C)) { $script:data[$address] = 0 }
    $script:led = 0
}
function Send-Move([char]$key) {
    $script:rxQueue.Enqueue([byte]$key)
    $frame = Run-ToNextFrame
    Assert-Frame $frame ($script:frameCount-1)
    return $frame
}
function Assert-BasePlusSpawn($frame,[hashtable]$fixed,[string]$name) {
    $extra = 0
    foreach ($index in 0..15) {
        $actual = [int]$frame[10+$index]
        if ($fixed.ContainsKey($index)) {
            Assert-Equal $actual $fixed[$index] "$name fixed cell $index"
        } elseif ($actual -ne 0) {
            if ($actual -ne 1 -and $actual -ne 2) { throw "$name invalid spawned exponent $actual at $index" }
            $extra++
        }
    }
    Assert-Equal $extra 1 "$name spawned tile count"
}

$frame = Run-ToNextFrame
Assert-Frame $frame 0
Assert-Equal $frame[4] 0 'initial state'
Assert-Equal $frame[6] 0 'initial score low'
Assert-Equal $frame[7] 0 'initial score high'
$initialTiles = @($frame[10..25] | Where-Object { $_ -ne 0 })
Assert-Equal $initialTiles.Count 2 'initial tile count'
foreach ($tile in $initialTiles) {
    if ($tile -ne 1 -and $tile -ne 2) { throw "invalid initial tile exponent $tile" }
}
Assert-Equal $script:displayLow 0x20 'display low signature'
Assert-Equal $script:displayHigh 0x48 'display high signature'

Set-Board @(1,1,1,1, 0,0,0,0, 0,0,0,0, 0,0,0,0)
$frame = Send-Move 'A'
Assert-BasePlusSpawn $frame @{0=2;1=2} 'left double-pair merge'
Assert-Equal $frame[6] 8 'left double-pair score'

Set-Board @(1,1,2,0, 0,0,0,0, 0,0,0,0, 0,0,0,0)
$frame = Send-Move 'A'
Assert-BasePlusSpawn $frame @{0=2;1=2} 'single-merge protection'
Assert-Equal $frame[6] 4 'single-merge score'

Set-Board @(1,0,1,0, 0,0,0,0, 0,0,0,0, 0,0,0,0)
$frame = Send-Move 'D'
Assert-BasePlusSpawn $frame @{3=2} 'right move'

Set-Board @(1,0,0,0, 0,0,0,0, 1,0,0,0, 0,0,0,0)
$frame = Send-Move 'W'
Assert-BasePlusSpawn $frame @{0=2} 'up move'

Set-Board @(1,0,0,0, 0,0,0,0, 1,0,0,0, 0,0,0,0)
$frame = Send-Move 'S'
Assert-BasePlusSpawn $frame @{12=2} 'down move'

Set-Board @(1,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0)
$script:data[0x36] = 0x1234
$frame = Send-Move 'A'
Assert-Equal (@($frame[10..25] | Where-Object { $_ -ne 0 })).Count 1 'unchanged move must not spawn'
Assert-Equal $frame[10] 1 'unchanged board cell'
Assert-Equal $frame[6] 0x34 'score low byte'
Assert-Equal $frame[7] 0x12 'score high byte'

Set-Board @(10,10,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0)
$frame = Send-Move 'A'
Assert-BasePlusSpawn $frame @{0=11} '2048 winning merge'
Assert-Equal ($frame[4] -band 1) 1 'win state bit'
Assert-Equal $frame[6] 0 '2048 score low byte'
Assert-Equal $frame[7] 8 '2048 score high byte'

Set-Board @(1,2,1,2, 2,1,2,1, 1,2,1,2, 2,1,2,1)
$frame = Send-Move 'A'
Assert-Equal ($frame[4] -band 0x80) 0x80 'full board game-over bit'
Assert-Equal $script:led 0x80 'game-over LED'

$reportDir = Join-Path $gameRoot 'reports'
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
$summary = @(
    'MiniRISC-16 2048 independent reference model',
    'PASS protocol v4 game-id, dimensions, sequence and XOR checksum',
    'PASS two-tile initial board',
    'PASS left/right/up/down transforms',
    'PASS one-merge-per-tile rule',
    'PASS spawn only after a changed move',
    'PASS 16-bit score transport',
    'PASS 2048 win state and full-board game over',
    "Instructions executed: $($script:steps)",
    'REFERENCE MODEL PASS'
)
[IO.File]::WriteAllLines((Join-Path $reportDir 'reference-model.log'),$summary,[Text.UTF8Encoding]::new($false))
$summary
