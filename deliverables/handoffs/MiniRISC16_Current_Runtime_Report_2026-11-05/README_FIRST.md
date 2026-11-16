# MiniRISC-16 Current Runtime Report Package

Report date: 2026-11-05  
Official report target: latest non-HDMI `runtime_system`

This package is the clean handoff for the current MiniRISC-16 report version. It contains the explanation documents, rebuildable RTL project, current programs, testbenches, Vivado/XSim evidence, implementation reports and the existing board bitstream. HDMI and older standalone project branches are intentionally excluded from the main package.

## Start here

1. Read `docs/CURRENT_REPORT_VERSION.md` for the exact version boundary and verified results.
2. Open `docs/PROJECT_BRANCH_MAP.png` or `.svg` for the ready-to-share English project evolution figure, then read `docs/PROJECT_BRANCH_MAP.md` for the detailed branch explanation.
3. Read `docs/MiniRISC16_Current_Runtime_Explanation.md` for the complete Chinese technical explanation and presentation order.
4. Open `runtime_system/reports/waveforms/current_terminal/final_vivado_style/` for the five English Vivado-style waveform figures.

## Current design at a glance

- Board/device: EES331, `xc7z020clg484-1`, 100 MHz.
- Top module: `runtime_board_top`.
- CPU: 16-bit single-cycle datapath, four general-purpose registers, 10-bit PC.
- Program memory: writable 1K×16 RAM with UART Loader.
- Data memory: 256×16 RAM.
- Extended ISA: `LDR`, `STR`, `JMPA`; `JUMP/JZ` are page-local.
- Programs: Snake, 2048 and Running Light through the same Runtime/Loader platform.
- Native Vivado/XSim current-structure waveform tests: 2/2 PASS.

## Important version note

The included implementation reports and `MiniRISC16_Runtime.bit` belong to the previously verified Runtime hardware build. The latest Snake/2048/Running Light program images can be uploaded through the existing SW7 UART Loader without regenerating the bitstream. Rebuilding the bitstream is only required if the newest program must become the power-on default or if RTL/constraints change.

## Rebuild and verification entry points

Run from `runtime_system/`:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\run.ps1" -Task Assemble
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\run.ps1" -Task Regression
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\run.ps1" -Task CreateProject
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\run.ps1" -Task Bitstream
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\run_runtime_waveforms_xsim.ps1"
```

The portable rebuild entry point is `scripts/create_project.tcl`; the included XPR is a convenience copy and may retain creator-machine metadata. The XSim waveform wrapper is configured for this machine's Vivado 2026.1 and working GCC path. Recipients with different installation paths can pass `-VivadoRoot` and `-GccBin`.

## Integrity

`manifest/SHA256SUMS.txt` lists SHA-256 hashes for every delivered file. `manifest/FILE_MANIFEST.md` explains what is included and excluded.
