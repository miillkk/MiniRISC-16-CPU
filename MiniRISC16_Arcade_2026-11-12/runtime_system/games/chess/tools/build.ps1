param([string]$VivadoRoot='C:\AMDDesignTools\2026.1\Vivado',[switch]$Hardware,[switch]$Simulate,[string]$BuildRoot='')
$ErrorActionPreference='Stop'
$game=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$root=[IO.Path]::GetFullPath((Join-Path $game '..\..'))
& node (Join-Path $PSScriptRoot 'build.cjs')
if($LASTEXITCODE){throw 'Chess generation failed'}
& "$PSScriptRoot/assemble4k.ps1" -Source "$game/program/chess.asm" -Output "$game/program/chess.mem" -RomOutput "$game/hardware/runtime_program_memory.v"
& node "$PSScriptRoot/verify.cjs"
if($LASTEXITCODE){throw 'Chess model verification failed'}
& node "$PSScriptRoot/verify_ai.cjs"
if($LASTEXITCODE){throw 'Chess AI model verification failed'}
if(-not ($Hardware -or $Simulate)){return}
if(-not $BuildRoot){$BuildRoot=Join-Path $env:USERPROFILE 'AppData\Local\Temp\minirisc_chess4k_build'}
$BuildRoot=[IO.Path]::GetFullPath($BuildRoot)
if($BuildRoot -match '[^\x00-\x7F]'){throw 'BuildRoot must be an ASCII path for this Vivado installation.'}
$stagedGame=Join-Path $BuildRoot 'games\chess'
New-Item -ItemType Directory -Force "$stagedGame/tools","$stagedGame/hardware","$game/reports" | Out-Null
Copy-Item -LiteralPath "$root/rtl","$root/constraints" -Destination $BuildRoot -Recurse -Force
Copy-Item "$game/hardware/*.v" "$stagedGame/hardware" -Force
Copy-Item "$PSScriptRoot/build_hardware.tcl" "$stagedGame/tools" -Force
if($Simulate){
    $sim=Join-Path $stagedGame 'sim'
    New-Item -ItemType Directory -Force $sim | Out-Null
    $overrides=@(Get-ChildItem "$stagedGame/hardware" -Filter *.v | ForEach-Object BaseName)
    $files=@(Get-ChildItem "$BuildRoot/rtl" -Recurse -Filter *.v | Where-Object {$_.BaseName -notin $overrides} | ForEach-Object FullName)
    $files+=@(Get-ChildItem "$stagedGame/hardware" -Filter *.v | ForEach-Object FullName)
    $files | ForEach-Object {'verilog work "'+($_ -replace '\\','/')+'"'} | Set-Content "$sim/files.prj" -Encoding ascii
    Push-Location $sim
    try{
        & "$VivadoRoot/bin/xvlog.bat" -prj files.prj
        if($LASTEXITCODE){throw 'RTL compile failed'}
        foreach($name in @('chess4k','loader4k')){
            & "$VivadoRoot/bin/xelab.bat" "tb_$name" -s $name -mt off
            if($LASTEXITCODE){throw 'RTL elaboration failed'}
            & "$VivadoRoot/bin/xsim.bat" $name -runall -log "$name.log"
            if($LASTEXITCODE -or (Get-Content "$name.log" -Raw) -notmatch 'RTL PASS'){throw "$name simulation failed"}
            Copy-Item "$name.log" "$game/reports" -Force
        }
    }finally{Pop-Location}
}
if($Hardware){
    Push-Location $stagedGame
    try{
        & "$VivadoRoot/bin/vivado.bat" -mode batch -source tools/build_hardware.tcl -log build4k.log -journal build4k.jou
        $buildExit=$LASTEXITCODE
        Copy-Item build4k.log "$game/reports/build4k.log" -Force
        if(Test-Path reports){Copy-Item reports/* "$game/reports" -Force}
        if($buildExit -or (Get-Content build4k.log -Raw) -notmatch 'CHESS 4K BITSTREAM PASS'){throw 'Hardware build did not pass; inspect reports/build4k.log'}
    }finally{Pop-Location}
}
