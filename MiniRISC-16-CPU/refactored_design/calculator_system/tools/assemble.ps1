param(
    [string]$Source = "",
    [string]$Output = ""
)

$ErrorActionPreference = "Stop"
$toolRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$designRoot = Split-Path -Parent $toolRoot
if (-not $Source) { $Source = Join-Path $designRoot "program\calculator.asm" }
if (-not $Output) { $Output = Join-Path $designRoot "program\calculator.mem" }
$Source = [IO.Path]::GetFullPath($Source)
$Output = [IO.Path]::GetFullPath($Output)

function Parse-Number {
    param([string]$Token, [hashtable]$Labels)
    $valueText = $Token.Trim()
    if ($Labels.ContainsKey($valueText.ToUpperInvariant())) {
        return [int]$Labels[$valueText.ToUpperInvariant()]
    }
    if ($valueText -match '^0[xX]([0-9a-fA-F]+)$') {
        return [Convert]::ToInt32($Matches[1], 16)
    }
    if ($valueText -match '^[0-9]+$') {
        return [int]$valueText
    }
    throw "Unknown number or label '$Token'."
}

function Parse-Register {
    param([string]$Token)
    if ($Token.Trim() -notmatch '^[Rr]([0-3])$') {
        throw "Invalid register '$Token'; expected R0..R3."
    }
    return [int]$Matches[1]
}

function Require-Byte {
    param([int]$Value, [string]$Context)
    if ($Value -lt 0 -or $Value -gt 255) {
        throw "$Context value $Value is outside 0..255."
    }
    return $Value
}

$sourceLines = Get-Content -LiteralPath $Source
$labels = @{}
$instructions = New-Object System.Collections.Generic.List[object]
$pc = 0

for ($lineIndex = 0; $lineIndex -lt $sourceLines.Count; $lineIndex++) {
    $original = $sourceLines[$lineIndex]
    $line = ($original -replace ';.*$', '').Trim()
    if (-not $line) { continue }

    while ($line -match '^([A-Za-z_][A-Za-z0-9_]*):\s*(.*)$') {
        $label = $Matches[1].ToUpperInvariant()
        if ($labels.ContainsKey($label)) { throw "Duplicate label '$label' on line $($lineIndex + 1)." }
        $labels[$label] = $pc
        $line = $Matches[2].Trim()
        if (-not $line) { break }
    }
    if (-not $line) { continue }
    if ($pc -ge 256) { throw "Program exceeds the 256-word instruction memory." }
    $instructions.Add([pscustomobject]@{
        Address = $pc
        Text = $line
        SourceLine = $lineIndex + 1
        Original = $original.Trim()
    })
    $pc++
}

$words = New-Object 'System.Collections.Generic.List[UInt16]'
for ($index = 0; $index -lt 256; $index++) { $words.Add([UInt16]0xF000) }
$comments = @{}

foreach ($item in $instructions) {
    $tokens = @($item.Text.Replace(',', ' ').Split([char[]]" `t", [StringSplitOptions]::RemoveEmptyEntries))
    $mnemonic = $tokens[0].ToUpperInvariant()
    $word = 0
    try {
        switch ($mnemonic) {
            'MOVI' {
                if ($tokens.Count -ne 3) { throw 'MOVI requires: MOVI Rd, imm8' }
                $rd = Parse-Register $tokens[1]
                $imm = Require-Byte (Parse-Number $tokens[2] $labels) 'MOVI immediate'
                $word = (0x0 -shl 12) -bor ($rd -shl 10) -bor $imm
            }
            'MOVR' {
                if ($tokens.Count -ne 3) { throw 'MOVR requires: MOVR Rd, Rs' }
                $rd = Parse-Register $tokens[1]; $rs = Parse-Register $tokens[2]
                $word = (0x1 -shl 12) -bor ($rd -shl 10) -bor ($rs -shl 8)
            }
            'ADDI' {
                if ($tokens.Count -ne 3) { throw 'ADDI requires: ADDI Rd, imm8' }
                $rd = Parse-Register $tokens[1]
                $imm = Require-Byte (Parse-Number $tokens[2] $labels) 'ADDI immediate'
                $word = (0x2 -shl 12) -bor ($rd -shl 10) -bor $imm
            }
            { $_ -in @('ADDR','XOR','SUB','CMP','AND','OR') } {
                if ($tokens.Count -ne 3) { throw "$mnemonic requires: $mnemonic Rd, Rs" }
                $opcodes = @{ ADDR = 0x3; XOR = 0x4; SUB = 0x5; CMP = 0x6; AND = 0x7; OR = 0x9 }
                $rd = Parse-Register $tokens[1]; $rs = Parse-Register $tokens[2]
                $word = ($opcodes[$mnemonic] -shl 12) -bor ($rd -shl 10) -bor ($rs -shl 8)
            }
            'JZ' {
                if ($tokens.Count -ne 2) { throw 'JZ requires: JZ target' }
                $target = Require-Byte (Parse-Number $tokens[1] $labels) 'JZ target'
                $word = (0x8 -shl 12) -bor $target
            }
            'JUMP' {
                if ($tokens.Count -ne 2) { throw 'JUMP requires: JUMP target' }
                $target = Require-Byte (Parse-Number $tokens[1] $labels) 'JUMP target'
                $word = (0xA -shl 12) -bor $target
            }
            'INP' {
                if ($tokens.Count -ne 3) { throw 'INP requires: INP Rd, address' }
                $rd = Parse-Register $tokens[1]
                $addr = Require-Byte (Parse-Number $tokens[2] $labels) 'INP address'
                $word = (0xB -shl 12) -bor ($rd -shl 10) -bor $addr
            }
            'OUP' {
                if ($tokens.Count -ne 3) { throw 'OUP requires: OUP address, Rs' }
                $addr = Require-Byte (Parse-Number $tokens[1] $labels) 'OUP address'
                $rs = Parse-Register $tokens[2]
                $word = (0xC -shl 12) -bor ($rs -shl 8) -bor $addr
            }
            'WORD' {
                if ($tokens.Count -ne 2) { throw 'WORD requires one 16-bit value' }
                $word = Parse-Number $tokens[1] $labels
                if ($word -lt 0 -or $word -gt 65535) { throw 'WORD value is outside 0..65535' }
            }
            default { throw "Unknown mnemonic '$mnemonic'." }
        }
    } catch {
        throw "Assembly error on source line $($item.SourceLine): $($item.Original)`r`n$($_.Exception.Message)"
    }
    $words[$item.Address] = [UInt16]$word
    $comments[$item.Address] = $item.Original
}

$outputLines = New-Object System.Collections.Generic.List[string]
$outputLines.Add('@00')
for ($address = 0; $address -lt 256; $address++) {
    $encoded = '{0:X4}' -f $words[$address]
    if ($comments.ContainsKey($address)) {
        $outputLines.Add("$encoded // $($comments[$address])")
    } else {
        $outputLines.Add($encoded)
    }
}

$outputDir = Split-Path -Parent $Output
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
[IO.File]::WriteAllLines($Output, $outputLines, [Text.UTF8Encoding]::new($false))
Write-Output "ASSEMBLE PASS: $($instructions.Count) active words, $((256 - $instructions.Count)) reserved words"
Write-Output "Output: $Output"
