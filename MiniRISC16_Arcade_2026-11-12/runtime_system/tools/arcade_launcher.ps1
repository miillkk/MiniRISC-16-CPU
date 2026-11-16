param(
    [string]$PortName = '',
    [int]$BaudRate = 115200,
    [switch]$NoColor,
    [switch]$Demo,
    [ValidateSet('Snake','2048','RunningLight','SlidingPuzzle','Gomoku','Chess')]
    [string]$DemoSelection = 'Snake'
)

$ErrorActionPreference = 'Stop'
$esc = [char]27
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$toolRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$designRoot = Split-Path -Parent $toolRoot
$uploadTool = Join-Path $toolRoot 'upload_program.ps1'

$games = @(
    [pscustomobject]@{
        Id = 'SlidingPuzzle'
        Number = '04'
        Title = 'SLIDING PUZZLE'
        Description = 'Choose 3 x 3 to 6 x 6 | Solvable shuffle'
        Program = Join-Path $designRoot 'games\sliding_puzzle\program\sliding_puzzle.mem'
        Terminal = Join-Path $designRoot 'games\sliding_puzzle\tools\sliding_puzzle_terminal.ps1'
        Accent = '38;5;213'
    },
    [pscustomobject]@{
        Id = 'Snake'
        Number = '01'
        Title = 'SNAKE'
        Description = '16 x 8 board | Open / Maze / Hard | Speed levels'
        Program = Join-Path $designRoot 'program\snake.mem'
        Terminal = Join-Path $toolRoot 'snake_terminal.ps1'
        Accent = '38;5;84'
    },
    [pscustomobject]@{
        Id = '2048'
        Number = '02'
        Title = '2048'
        Description = '4 x 4 number puzzle | 16-bit score | Win / game-over states'
        Program = Join-Path $designRoot 'games\2048\program\game_2048.mem'
        Terminal = Join-Path $designRoot 'games\2048\tools\game_2048_terminal.ps1'
        Accent = '38;5;220'
    },
    [pscustomobject]@{
        Id = 'RunningLight'
        Number = '03'
        Title = 'RUNNING LIGHT'
        Description = '8 board LEDs | Direction control | Speed and pause switches'
        Program = Join-Path $designRoot 'games\running_light\program\running_light.mem'
        Terminal = Join-Path $designRoot 'games\running_light\tools\running_light_terminal.ps1'
        Accent = '38;5;51'
    },
    [pscustomobject]@{
        Id = 'Gomoku'
        Number = '05'
        Title = 'GOMOKU'
        Description = '15 x 15 | Two players / MiniRISC CPU opponent'
        Program = Join-Path $designRoot 'games\gomoku\program\gomoku.mem'
        Terminal = Join-Path $designRoot 'games\gomoku\tools\gomoku_terminal.ps1'
        Accent = '38;5;180'
    },
    [pscustomobject]@{
        Id = 'Chess'
        Number = '06'
        Title = 'CHESS'
        Description = 'Two players / CPU opponent | 4K runtime'
        Program = Join-Path $designRoot 'games\chess\program\chess.mem'
        Terminal = Join-Path $designRoot 'games\chess\tools\chess_terminal.ps1'
        UploadTool = Join-Path $designRoot 'games\chess\tools\upload_chess.ps1'
        Accent = '38;5;255'
    }
)

function Paint([string]$text,[string]$code) {
    if ($NoColor) { return $text }
    return "$esc[$code`m$text$esc[0m"
}
function Clear-Screen {
    [Console]::Write("$esc[2J$esc[H")
}
function Get-CharacterWidth([char]$character) {
    $value = [int]$character
    if (($value -ge 0x1100 -and $value -le 0x115F) -or
        ($value -ge 0x2E80 -and $value -le 0xA4CF -and $value -ne 0x303F) -or
        ($value -ge 0xAC00 -and $value -le 0xD7A3) -or
        ($value -ge 0xF900 -and $value -le 0xFAFF) -or
        ($value -ge 0xFE10 -and $value -le 0xFE19) -or
        ($value -ge 0xFE30 -and $value -le 0xFE6F) -or
        ($value -ge 0xFF00 -and $value -le 0xFF60) -or
        ($value -ge 0xFFE0 -and $value -le 0xFFE6)) { return 2 }
    return 1
}
function Fit([string]$text,[int]$width) {
    $builder = [Text.StringBuilder]::new()
    $used = 0
    foreach ($character in $text.ToCharArray()) {
        $characterWidth = Get-CharacterWidth $character
        if ($used + $characterWidth -gt $width) { break }
        [void]$builder.Append($character)
        $used += $characterWidth
    }
    [void]$builder.Append(' ' * ($width-$used))
    return $builder.ToString()
}
function Write-BoxLine([string]$text = '',[string]$style = '') {
    $content = Fit $text 72
    if ($style) { $content = Paint $content $style }
    [Console]::WriteLine('║ ' + $content + ' ║')
}
function Show-Menu([int]$selected,[string]$loadedGame,[string]$portLabel) {
    Clear-Screen
    [Console]::WriteLine((Paint '╔══════════════════════════════════════════════════════════════════════════╗' '38;5;39'))
    Write-BoxLine ''
    Write-BoxLine ('  MINIRISC-16  ARCADE                           PORT  {0} @ {1}' -f $portLabel,$BaudRate)
    Write-BoxLine '  ──────────────────────────────────────────────────────────────────────'
    Write-BoxLine '  SELECT A GAME'
    Write-BoxLine ''
    for ($index=0; $index -lt $games.Count; $index++) {
        $game = $games[$index]
        $marker = if ($index -eq $selected) { '▶' } else { ' ' }
        $loaded = if ($loadedGame -eq $game.Id) { '  [LOADED]' } else { '' }
        $title = ('  {0}  {1}  {2}{3}' -f $marker,$game.Number,$game.Title,$loaded)
        $description = ('         {0}' -f $game.Description)
        if ($index -eq $selected) {
            Write-BoxLine $title ('1;'+$game.Accent)
            Write-BoxLine $description $game.Accent
        } else {
            Write-BoxLine $title
            Write-BoxLine $description
        }
        Write-BoxLine ''
    }
    Write-BoxLine '  ──────────────────────────────────────────────────────────────────────'
    Write-BoxLine '  UP / DOWN or W / S   ENTER Play   1-6 Select   Q Quit'
    if ($loadedGame) {
        Write-BoxLine '  To switch games: set SW7=1 first; after upload, set SW7=0.'
    } else {
        Write-BoxLine '  First launch: set SW7=1; after upload, set SW7=0.'
    }
    Write-BoxLine ''
    [Console]::WriteLine((Paint '╚══════════════════════════════════════════════════════════════════════════╝' '38;5;39'))
}
function Wait-AfterMessage([string]$message) {
    [Console]::WriteLine()
    [Console]::WriteLine((Paint ('  '+$message) '1;38;5;203'))
    [Console]::WriteLine('  Press any key to return to the game menu.')
    [Console]::ReadKey($true) | Out-Null
}
function Start-GameTerminal($game) {
    Clear-Screen
    if ($NoColor) {
        & $game.Terminal -PortName $PortName -BaudRate $BaudRate -NoColor
    } else {
        & $game.Terminal -PortName $PortName -BaudRate $BaudRate
    }
}
function Install-AndStartGame($game) {
    Clear-Screen
    [Console]::WriteLine((Paint ('  Uploading {0} to {1}...' -f $game.Title,$PortName) ('1;'+$game.Accent)))
    [Console]::WriteLine()
    try {
        $selectedUploader = if ($game.PSObject.Properties['UploadTool']) { $game.UploadTool } else { $uploadTool }
        & $selectedUploader -PortName $PortName -Program $game.Program -BaudRate $BaudRate
    } catch {
        Wait-AfterMessage ('Upload failed: '+$_.Exception.Message)
        return $false
    }
    Start-GameTerminal $game
    return $true
}

$selected = switch($DemoSelection){'2048'{2};'RunningLight'{3};'SlidingPuzzle'{0};'Gomoku'{4};'Chess'{5};default{1}}
if ($Demo) {
    Show-Menu $selected '' 'COM3'
    exit 0
}

if (-not $PortName) {
    $ports = @([IO.Ports.SerialPort]::GetPortNames() | Sort-Object)
    if ($ports.Count -eq 0) { throw 'No serial port found. Connect the board or specify -PortName COM3.' }
    if ($ports.Count -gt 1) { throw ('Multiple serial ports found: {0}. Use -PortName to select the board port.' -f ($ports -join ', ')) }
    $PortName = $ports[0]
}

foreach ($game in $games) {
    if (-not (Test-Path -LiteralPath $game.Program)) { throw "Game image not found: $($game.Program)" }
    if (-not (Test-Path -LiteralPath $game.Terminal)) { throw "Game terminal not found: $($game.Terminal)" }
}

$loadedGame = ''
$quit = $false
try {
    while (-not $quit) {
        Show-Menu $selected $loadedGame $PortName
        $key = [Console]::ReadKey($true)
        switch ($key.Key) {
            'UpArrow'   { $selected = ($selected + $games.Count - 1) % $games.Count }
            'W'         { $selected = ($selected + $games.Count - 1) % $games.Count }
            'DownArrow' { $selected = ($selected + 1) % $games.Count }
            'S'         { $selected = ($selected + 1) % $games.Count }
            'D1'        { $selected = 1 }
            'NumPad1'   { $selected = 1 }
            'D2'        { $selected = 2 }
            'NumPad2'   { $selected = 2 }
            'D3'        { $selected = 3 }
            'NumPad3'   { $selected = 3 }
            'D6' { $selected = 5 }
            'NumPad6' { $selected = 5 }
            'D5' { $selected = 4 }
            'NumPad5' { $selected = 4 }
            'D4' { $selected = 0 }
            'NumPad4' { $selected = 0 }
            'Q'         { $quit = $true }
            'Enter' {
                $game = $games[$selected]
                if ($loadedGame -eq $game.Id) {
                    Start-GameTerminal $game
                } elseif (Install-AndStartGame $game) {
                    $loadedGame = $game.Id
                }
            }
        }
    }
} finally {
    if (-not $NoColor) { [Console]::Write("$esc[0m") }
    [Console]::WriteLine()
}




