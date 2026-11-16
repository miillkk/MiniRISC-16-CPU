param(
    [Parameter(Mandatory=$true)][string]$PortName,
    [string]$Program = '',
    [int]$BaudRate = 115200
)

$ErrorActionPreference = 'Stop'
$toolRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$designRoot = Split-Path -Parent $toolRoot
if (-not $Program) { $Program = Join-Path $designRoot 'program\snake.mem' }

$words = [Collections.Generic.List[UInt16]]::new()
$address = 0
foreach ($sourceLine in Get-Content -LiteralPath $Program) {
    $line = ($sourceLine -replace '//.*$','').Trim()
    if (-not $line) { continue }
    if ($line -match '^@([0-9A-Fa-f]+)$') {
        $address = [Convert]::ToInt32($Matches[1],16)
        while ($words.Count -lt $address) { $words.Add([UInt16]0xFFFF) }
        continue
    }
    if ($address -ge 1024) { throw 'Program exceeds the 1024-word runtime memory.' }
    $value = [Convert]::ToUInt16($line,16)
    if ($address -eq $words.Count) { $words.Add($value) }
    else { $words[$address] = $value }
    $address++
}
while ($words.Count -lt 1024) { $words.Add([UInt16]0xFFFF) }

$packet = [Collections.Generic.List[byte]]::new()
$packet.Add(0x55); $packet.Add(0x4C)
$packet.Add(0x04); $packet.Add(0x00)
$checksum = 0
foreach ($word in $words) {
    $packet.Add([byte](($word -shr 8) -band 0xFF))
    $packet.Add([byte]($word -band 0xFF))
    $checksum = ($checksum + $word) -band 0xFFFF
}
$packet.Add([byte](($checksum -shr 8) -band 0xFF))
$packet.Add([byte]($checksum -band 0xFF))

$serial = [IO.Ports.SerialPort]::new($PortName,$BaudRate,[IO.Ports.Parity]::None,8,[IO.Ports.StopBits]::One)
$serial.ReadTimeout = 5000
$serial.WriteTimeout = 5000
try {
    $serial.Open()
    $serial.DiscardInBuffer()
    $payload = $packet.ToArray()
    Write-Host "Uploading $($words.Count) words to $PortName..."
    $serial.Write($payload,0,$payload.Length)
    $reply = $serial.ReadByte()
    if ($reply -ne 0x06) { throw ('Loader returned NAK/unexpected byte 0x{0:X2}.' -f $reply) }
    Write-Host ('UPLOAD PASS: 1024 words, checksum 0x{0:X4}' -f $checksum)
    Write-Host 'Set SW7 back to 0. The CPU will reset and run the uploaded image.'
} finally {
    if ($serial.IsOpen) { $serial.Close() }
    $serial.Dispose()
}
