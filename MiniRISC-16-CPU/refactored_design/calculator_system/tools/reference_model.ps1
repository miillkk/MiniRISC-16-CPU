param(
    [string]$Program = "",
    [string]$Report = ""
)

$ErrorActionPreference = "Stop"
$toolRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$designRoot = Split-Path -Parent $toolRoot
if (-not $Program) { $Program = Join-Path $designRoot "program\calculator.mem" }
if (-not $Report) { $Report = Join-Path $designRoot "reports\simulation\reference-model.log" }

function Load-Program {
    param([string]$Path)
    $words = New-Object 'System.Collections.Generic.List[UInt16]'
    foreach ($raw in Get-Content -LiteralPath $Path) {
        $line = ($raw -replace '//.*$', '').Trim()
        if (-not $line -or $line.StartsWith('@')) { continue }
        $words.Add([Convert]::ToUInt16($line, 16))
    }
    if ($words.Count -ne 256) { throw "Expected 256 memory words, found $($words.Count)." }
    return $words.ToArray()
}

function New-Model {
    param([UInt16[]]$Words, [int]$InitialToken)
    return @{
        Program = $Words
        Regs = [UInt16[]](0, 0, 0, 0)
        Scratch = [UInt16[]](0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        Pc = 0; Z = $false; N = $false; C = $false; V = $false
        DisplayLow = 0; DisplayHigh = 0; DisplayControl = 0; Led = 0
        SwitchData = 0; Token = $InitialToken; Cycles = 0
    }
}

function Get-IoValue {
    param([hashtable]$State, [int]$Address)
    switch ($Address) {
        0x20 { return $State.DisplayLow }
        0x21 { return $State.DisplayHigh }
        0x22 { return $State.DisplayControl }
        0x30 { return $State.Led }
        0x31 { return ($State.SwitchData -band 0xFF) }
        0x32 {
            return (([int]$State.V -shl 6) -bor ([int]$State.C -shl 5) -bor
                    ([int]$State.N -shl 4) -bor ([int]$State.Z -shl 3))
        }
        0x33 { return (0x0002 -bor ($State.Token -band 1)) }
        default {
            if (($Address -band 0xF0) -eq 0x40) { return $State.Scratch[$Address -band 0x0F] }
            return 0
        }
    }
}

function Set-IoValue {
    param([hashtable]$State, [int]$Address, [int]$Value)
    $value16 = $Value -band 0xFFFF
    switch ($Address) {
        0x20 { $State.DisplayLow = $value16 }
        0x21 { $State.DisplayHigh = $value16 }
        0x22 { $State.DisplayControl = $value16 }
        0x30 { $State.Led = $value16 -band 0xFF }
        default {
            if (($Address -band 0xF0) -eq 0x40) { $State.Scratch[$Address -band 0x0F] = $value16 }
        }
    }
}

function Set-Flags {
    param([hashtable]$State, [int]$A, [int]$B, [int]$Result, [bool]$Subtract)
    $State.Z = (($Result -band 0xFFFF) -eq 0)
    $State.N = (($Result -band 0x8000) -ne 0)
    if ($Subtract) {
        $extended = $A + ((-bnot $B) -band 0xFFFF) + 1
        $State.C = (($extended -band 0x10000) -ne 0)
        $State.V = (((($A -bxor $B) -band 0x8000) -ne 0) -and
                    ((($Result -bxor $A) -band 0x8000) -ne 0))
    } else {
        $extended = $A + $B
        $State.C = (($extended -band 0x10000) -ne 0)
        $State.V = (((($A -bxor $B) -band 0x8000) -eq 0) -and
                    ((($Result -bxor $A) -band 0x8000) -ne 0))
    }
}

function Step-Model {
    param([hashtable]$State)
    $instruction = [int]$State.Program[$State.Pc]
    $opcode = ($instruction -shr 12) -band 0xF
    $rd = ($instruction -shr 10) -band 0x3
    $rs = ($instruction -shr 8) -band 0x3
    $imm = $instruction -band 0xFF
    $a = [int]$State.Regs[$rd]
    $b = [int]$State.Regs[$rs]
    $nextPc = ($State.Pc + 1) -band 0xFF

    switch ($opcode) {
        0x0 { $State.Regs[$rd] = $imm }
        0x1 { $State.Regs[$rd] = $b }
        0x2 {
            $result = ($a + $imm) -band 0xFFFF
            $State.Regs[$rd] = $result
            Set-Flags $State $a $imm $result $false
        }
        0x3 {
            $result = ($a + $b) -band 0xFFFF
            $State.Regs[$rd] = $result
            Set-Flags $State $a $b $result $false
        }
        0x4 { $State.Regs[$rd] = ($a -bxor $b) -band 0xFFFF }
        0x5 {
            $result = ($a - $b) -band 0xFFFF
            $State.Regs[$rd] = $result
            Set-Flags $State $a $b $result $true
        }
        0x6 {
            $result = ($a - $b) -band 0xFFFF
            Set-Flags $State $a $b $result $true
        }
        0x7 { $State.Regs[$rd] = ($a -band $b) -band 0xFFFF }
        0x8 { if ($State.Z) { $nextPc = $imm } }
        0x9 { $State.Regs[$rd] = ($a -bor $b) -band 0xFFFF }
        0xA { $nextPc = $imm }
        0xB { $State.Regs[$rd] = (Get-IoValue $State $imm) -band 0xFFFF }
        0xC { Set-IoValue $State $imm $b }
        default { }
    }
    $State.Pc = $nextPc
    $State.Cycles++
}

function Run-UntilDisplay {
    param([hashtable]$State, [int]$High, [int]$Low, [int]$Limit = 200000)
    for ($count = 0; $count -lt $Limit; $count++) {
        Step-Model $State
        if ($State.DisplayHigh -eq $High -and $State.DisplayLow -eq $Low) { return }
    }
    throw ('Timeout waiting for display {0:X4}{1:X4}; current={2:X4}{3:X4}, PC={4:X2}' -f
           $High, $Low, $State.DisplayHigh, $State.DisplayLow, $State.Pc)
}

function Run-Transaction {
    param(
        [UInt16[]]$Words, [int]$A, [int]$B, [int]$Operation,
        [int]$ExpectedHigh, [int]$ExpectedLow, [int]$ExpectedLed,
        [int]$InitialToken = 0
    )
    $state = New-Model $Words $InitialToken
    $state.SwitchData = $A
    Run-UntilDisplay $state 0xA000 $A
    $state.Token = 1 - $state.Token
    Run-UntilDisplay $state 0xB000 $A
    $state.SwitchData = $B
    Run-UntilDisplay $state 0xB000 $B
    $state.Token = 1 - $state.Token
    Run-UntilDisplay $state 0xC000 $B
    $state.SwitchData = $Operation
    Run-UntilDisplay $state 0xC000 $Operation
    $state.Token = 1 - $state.Token
    Run-UntilDisplay $state $ExpectedHigh $ExpectedLow

    if ($state.Led -ne $ExpectedLed) {
        throw ('LED mismatch: expected {0:X2}, got {1:X2}' -f $ExpectedLed, $state.Led)
    }
    if ($state.DisplayControl -ne 1) { throw 'Display was not enabled.' }

    $savedHigh = $state.DisplayHigh; $savedLow = $state.DisplayLow; $savedLed = $state.Led
    $state.SwitchData = ($A + 3) -band 0xFF
    for ($index = 0; $index -lt 100; $index++) { Step-Model $state }
    if ($state.DisplayHigh -ne $savedHigh -or $state.DisplayLow -ne $savedLow -or $state.Led -ne $savedLed) {
        throw 'Result changed without an S1 short press.'
    }

    $state.Token = 1 - $state.Token
    Run-UntilDisplay $state 0xA000 $state.SwitchData
    if ($state.Led -ne 0) { throw 'LED status did not clear when starting a new transaction.' }
    return $state.Cycles
}

$words = Load-Program $Program
$tests = @(
    @{ Name='ADD 2D+17'; A=0x2D; B=0x17; Op=0; High=0x2D17; Low=0x0044; Led=0x00; Token=0 },
    @{ Name='ADD zero'; A=0x00; B=0x00; Op=0; High=0x0000; Low=0x0000; Led=0x08; Token=1 },
    @{ Name='SUB underflow'; A=0x14; B=0x23; Op=1; High=0x1423; Low=0xFFF1; Led=0x11; Token=0 },
    @{ Name='SUB equal'; A=0x23; B=0x23; Op=1; High=0x2323; Low=0x0000; Led=0x29; Token=0 },
    @{ Name='AND'; A=0x5A; B=0x0F; Op=2; High=0x5A0F; Low=0x000A; Led=0x02; Token=0 },
    @{ Name='OR'; A=0x5A; B=0x0F; Op=3; High=0x5A0F; Low=0x005F; Led=0x03; Token=0 },
    @{ Name='XOR'; A=0x5A; B=0x0F; Op=4; High=0x5A0F; Low=0x0055; Led=0x04; Token=0 },
    @{ Name='MUL'; A=0x12; B=0x0A; Op=5; High=0x120A; Low=0x00B4; Led=0x05; Token=0 },
    @{ Name='MUL max'; A=0xFF; B=0xFF; Op=5; High=0xFFFF; Low=0xFE01; Led=0x15; Token=0 },
    @{ Name='DIV remainder'; A=0x65; B=0x0A; Op=6; High=0x650A; Low=0x0A01; Led=0x06; Token=0 },
    @{ Name='DIV max'; A=0xFF; B=0x01; Op=6; High=0xFF01; Low=0xFF00; Led=0x06; Token=0 },
    @{ Name='DIV zero'; A=0x23; B=0x00; Op=6; High=0xE001; Low=0x2300; Led=0x86; Token=0 },
    @{ Name='CMP less'; A=0x33; B=0x34; Op=7; High=0x3334; Low=0x0000; Led=0x17; Token=0 },
    @{ Name='CMP equal'; A=0x33; B=0x33; Op=7; High=0x3333; Low=0x0001; Led=0x2F; Token=0 },
    @{ Name='CMP greater'; A=0x34; B=0x33; Op=7; High=0x3433; Low=0x0002; Led=0x27; Token=0 }
)

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("MiniRISC-16 calculator independent reference model")
$lines.Add("Timestamp: $([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss zzz'))")
$lines.Add("Program words: 256; active words: 240; reserved words: 16")
$failures = 0
foreach ($test in $tests) {
    try {
        $cycles = Run-Transaction $words $test.A $test.B $test.Op $test.High $test.Low $test.Led $test.Token
        $lines.Add(('PASS {0,-18} display={1:X4}{2:X4} led={3:X2} cycles={4}' -f
                    $test.Name, $test.High, $test.Low, $test.Led, $cycles))
    } catch {
        $failures++
        $lines.Add("FAIL $($test.Name): $($_.Exception.Message)")
    }
}
$lines.Add("Tests: $($tests.Count); Failures: $failures")
$reportDir = Split-Path -Parent $Report
New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
[IO.File]::WriteAllLines($Report, $lines, [Text.UTF8Encoding]::new($false))
$lines | ForEach-Object { Write-Output $_ }
if ($failures -ne 0) { exit 1 }
