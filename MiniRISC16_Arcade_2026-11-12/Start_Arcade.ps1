param([string]$PortName='')
$ErrorActionPreference='Stop'
if(-not $PortName){$PortName=Read-Host 'Enter CP210x PL UART port (example COM6)'}
if($PortName -notmatch '^COM[0-9]+$'){throw 'Expected a COM port such as COM6'}
Push-Location (Join-Path $PSScriptRoot 'runtime_system')
try { & '.\tools\arcade_launcher.ps1' -PortName $PortName } finally { Pop-Location }
