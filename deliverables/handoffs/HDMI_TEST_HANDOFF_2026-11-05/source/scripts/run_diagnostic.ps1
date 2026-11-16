param([string]$VivadoBin='', [switch]$FromCheckpoint, [switch]$LinkOnly)
$ErrorActionPreference='Stop'
$scriptRoot=Split-Path -Parent $MyInvocation.MyCommand.Path
$designRoot=[IO.Path]::GetFullPath((Join-Path $scriptRoot '..'))
$diagDir=Join-Path $designRoot 'reports\diagnostics'
New-Item -ItemType Directory -Force -Path $diagDir | Out-Null
$candidates=@($VivadoBin,$env:VIVADO_BIN,'F:\vivado\2026.1\Vivado\bin') | Where-Object { $_ }
$tool=Get-Command vivado.bat -ErrorAction SilentlyContinue
if($tool){$candidates += Split-Path -Parent $tool.Source}
$resolved=$null
foreach($candidate in $candidates){
    if(Test-Path (Join-Path $candidate 'vivado.bat')){$resolved=(Resolve-Path $candidate).Path;break}
}
if(!$resolved){throw 'Vivado not found. Pass -VivadoBin <Vivado/bin>.'}
$env:HDMI_SNAKE_ROOT=$designRoot.Replace('\','/')
try {
    $tclName=if($LinkOnly){'build_hdmi_link_only.tcl'}elseif($FromCheckpoint){'finish_hdmi_diagnostic.tcl'}else{'build_hdmi_diagnostic.tcl'}
    & (Join-Path $resolved 'vivado.bat') -mode batch `
        -source (Join-Path $scriptRoot $tclName) `
        -log (Join-Path $diagDir 'build.log') `
        -journal (Join-Path $diagDir 'build.jou')
    if($LASTEXITCODE -ne 0){throw "HDMI diagnostic build failed: Vivado exit $LASTEXITCODE"}
} finally {
    Remove-Item Env:HDMI_SNAKE_ROOT -ErrorAction SilentlyContinue
}
