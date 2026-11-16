$ErrorActionPreference = 'Stop'

$serverPath = 'C:\Users\xieke\Desktop\CPU\tools\amd-ross\vivado-mcp-server.exe'
$vivadoPath = 'F:\vivado\2026.1\Vivado\bin\vivado.bat'
$workingDirectory = 'C:\Users\xieke\Desktop\CPU'

$startInfo = [System.Diagnostics.ProcessStartInfo]::new()
$startInfo.FileName = $serverPath
$startInfo.ArgumentList.Add('--stdio')
$startInfo.UseShellExecute = $false
$startInfo.RedirectStandardInput = $true
$startInfo.RedirectStandardOutput = $true
$startInfo.RedirectStandardError = $false
$startInfo.CreateNoWindow = $true
$startInfo.Environment['VIVADO_PATH'] = $vivadoPath

$process = [System.Diagnostics.Process]::new()
$process.StartInfo = $startInfo
$null = $process.Start()

function Send-JsonRpc {
    param([Parameter(Mandatory)] [hashtable] $Message)
    $json = $Message | ConvertTo-Json -Compress -Depth 20
    $process.StandardInput.WriteLine($json)
    $process.StandardInput.Flush()
}

function Receive-JsonRpcResponse {
    param(
        [Parameter(Mandatory)] [int] $Id,
        [int] $TimeoutSeconds = 180
    )

    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    while ([DateTime]::UtcNow -lt $deadline) {
        $remaining = $deadline - [DateTime]::UtcNow
        $lineTask = $process.StandardOutput.ReadLineAsync()
        if (-not $lineTask.Wait($remaining)) {
            throw "Timed out waiting for JSON-RPC response id=$Id"
        }
        $line = $lineTask.Result
        if ($null -eq $line) {
            throw "Vivado MCP exited before returning response id=$Id"
        }
        $message = $line | ConvertFrom-Json -Depth 30
        if ($message.id -eq $Id) {
            return $message
        }
    }
    throw "Timed out waiting for JSON-RPC response id=$Id"
}

$sessionId = $null
try {
    Send-JsonRpc @{jsonrpc='2.0'; id=1; method='initialize'; params=@{protocolVersion='2024-11-05'; capabilities=@{}; clientInfo=@{name='codex-vivado-smoke-test'; version='1.0'}}}
    $initialize = Receive-JsonRpcResponse -Id 1 -TimeoutSeconds 30
    if ($initialize.error) { throw ($initialize.error | ConvertTo-Json -Compress -Depth 10) }

    Send-JsonRpc @{jsonrpc='2.0'; method='notifications/initialized'}
    Send-JsonRpc @{jsonrpc='2.0'; id=2; method='tools/call'; params=@{name='vivado_start'; arguments=@{working_dir=$workingDirectory; session_type='general'; gui_mode=$false}}}
    $start = Receive-JsonRpcResponse -Id 2 -TimeoutSeconds 300
    if ($start.error) { throw ($start.error | ConvertTo-Json -Compress -Depth 10) }

    $startJson = $start.result | ConvertTo-Json -Compress -Depth 30
    $startPayload = $start.result.content[0].text | ConvertFrom-Json -Depth 20
    $sessionId = $startPayload.session_id
    if (-not $sessionId) {
        throw "Vivado started but no session_id was returned: $startJson"
    }

    Send-JsonRpc @{jsonrpc='2.0'; id=3; method='tools/call'; params=@{name='vivado_execute'; arguments=@{session_id=$sessionId; command='version -short'; capture_log=$false}}}
    $version = Receive-JsonRpcResponse -Id 3 -TimeoutSeconds 120
    if ($version.error) { throw ($version.error | ConvertTo-Json -Compress -Depth 10) }

    [pscustomobject]@{
        ServerName = $initialize.result.serverInfo.name
        ServerVersion = $initialize.result.serverInfo.version
        SessionId = $sessionId
        VivadoResult = $version.result
    } | ConvertTo-Json -Depth 30
}
finally {
    if ($sessionId) {
        try {
            Send-JsonRpc @{jsonrpc='2.0'; id=4; method='tools/call'; params=@{name='vivado_stop'; arguments=@{session_id=$sessionId; close_vivado=$true}}}
            $null = Receive-JsonRpcResponse -Id 4 -TimeoutSeconds 60
        }
        catch {
            Write-Warning "Could not stop Vivado through MCP: $($_.Exception.Message)"
        }
    }

    try { $process.StandardInput.Close() } catch {}
    if (-not $process.WaitForExit(5000)) {
        $process.Kill($true)
    }
}
