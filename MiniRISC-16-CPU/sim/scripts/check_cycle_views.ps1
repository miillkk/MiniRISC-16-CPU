# Verify that every visible module view uses the same cycle-aligned trace and
# that the executed instruction at each valid edge matches the program ROM.
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$waveDir = Join-Path $repo 'reports/waveforms/cycle_views'
$vcdPath = Join-Path $waveDir 'tb_system_cycle.vcd'
$wdbPath = Join-Path $waveDir 'tb_system_cycle.wdb'
$programPath = Join-Path $repo 'sim/programs/system_demo.mem'
$views = @{
    system_top = 'trace_io_addr'
    instruction_memory = 'trace_instruction'
    cpu_core = 'trace_cycle_alu_result'
    controller = 'trace_cycle_reg_write'
    datapath = 'trace_cycle_pc_next'
    register_file = 'trace_cycle_writeback_data'
    alu = 'trace_cycle_alu_result'
    reset = 'trace_release_sync'
    gpio = 'trace_cycle_gpio_out_before'
}
$common = @('clk', 'trace_cycle_valid', 'trace_cycle_pc',
            'trace_cycle_instruction', 'trace_cycle_opcode')

if (!(Test-Path -LiteralPath $vcdPath) -or !(Test-Path -LiteralPath $wdbPath)) {
    throw 'Missing integrated cycle VCD/WDB.'
}
foreach ($view in $views.Keys) {
    $config = Join-Path $waveDir "${view}_cycle.wcfg"
    if (!(Test-Path -LiteralPath $config)) { throw "Missing $config" }
    $xml = Get-Content -LiteralPath $config -Raw
    foreach ($signal in @($common + $views[$view])) {
        if (!$xml.Contains("fp_name=`"/tb_system/$signal`"")) {
            throw "$view is missing $signal"
        }
    }
}

$program = @()
foreach ($line in Get-Content -LiteralPath $programPath) {
    if ($line -match '^\s*([0-9a-fA-F]{4})\b') {
        $program += [Convert]::ToInt32($Matches[1], 16)
    }
}

$codes = @{}
$values = [System.Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
$scopeDepth = 0
$headerEnded = $false
$timePs = 0L
$rise = $false
$records = [System.Collections.Generic.List[object]]::new()
foreach ($rawLine in Get-Content -LiteralPath $vcdPath) {
    $line = $rawLine.Trim()
    if (!$headerEnded) {
        if ($line -match '^\$scope\b') { $scopeDepth++; continue }
        if ($line -match '^\$upscope\b') { $scopeDepth--; continue }
        if ($scopeDepth -eq 1 -and $line -match '^\$var\s+\S+\s+\d+\s+(\S+)\s+(\w+)') {
            $codes[$Matches[2]] = $Matches[1]
        }
        if ($line -match '^\$enddefinitions\b') { $headerEnded = $true }
        continue
    }
    if ($line -match '^#(\d+)') {
        $newTimePs = [long]$Matches[1]
        if ($rise -and $values[$codes['trace_cycle_valid']] -eq '1') {
            $pcBits = $values[$codes['trace_cycle_pc']]
            $irBits = $values[$codes['trace_cycle_instruction']]
            $opBits = $values[$codes['trace_cycle_opcode']]
            if ($pcBits -notmatch '^[01]+$' -or $irBits -notmatch '^[01]+$' -or $opBits -notmatch '^[01]+$') {
                throw "Unknown PC/instruction/opcode at ${timePs}ps"
            }
            $records.Add([pscustomobject]@{
                TimePs = $timePs
                PC = [Convert]::ToInt32($pcBits, 2)
                Instruction = [Convert]::ToInt32($irBits, 2)
                Opcode = [Convert]::ToInt32($opBits, 2)
                NextPC = [Convert]::ToInt32($values[$codes['trace_cycle_pc_next']], 2)
            })
        }
        $timePs = $newTimePs
        $rise = $false
        continue
    }
    if ($line -match '^b([01xXzZ]+)\s+(\S+)$') {
        $values[$Matches[2]] = $Matches[1]
    } elseif ($line -match '^([01xXzZ])(\S+)$') {
        $values[$Matches[2]] = $Matches[1]
        if ($Matches[2] -ceq $codes['clk'] -and $Matches[1] -eq '1') { $rise = $true }
    }
}

# The testbench's cycles=32 includes the reset-release wait; only 29 rising
# edges have rst=0 and commit a program instruction.
if ($records.Count -ne 29) { throw "Expected 29 valid executed cycles, got $($records.Count)" }
for ($i = 0; $i -lt $records.Count; $i++) {
    $row = $records[$i]
    if ($row.PC -ge $program.Count -or $row.Instruction -ne $program[$row.PC]) {
        throw ('ROM mismatch at cycle {0}: PC={1:X2} IR={2:X4}' -f $i, $row.PC, $row.Instruction)
    }
    if ($row.Opcode -ne ($row.Instruction -shr 12)) {
        throw "Opcode mismatch at cycle $i"
    }
    if ($i -gt 0) {
        $previous = $records[$i - 1]
        if ($row.TimePs - $previous.TimePs -ne 10000) { throw "Clock gap at cycle $i" }
        if ($row.PC -ne $previous.NextPC) { throw "PC transition mismatch at cycle $i" }
    }
}
Write-Output "CYCLE_VIEWS PASS: $($views.Count) module views, $($records.Count) valid cycles, ROM/opcode/next-PC match"
