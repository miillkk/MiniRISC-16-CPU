# Current Report Version

## Version identity

- Report date: 2026-11-05.
- Verification evidence date: 2026-11-04.
- Official source directory: `MiniRISC-16-CPU/refactored_design/runtime_system/`.
- Report target: latest non-HDMI terminal Runtime.
- Explicitly not the report target: HDMI Snake, HDMI diagnostics, the standalone calculator project, Snake V1 or the original 8-bit-PC CPU.

## Architecture

| Item | Current report version |
|---|---|
| FPGA | Zynq-7020 `xc7z020clg484-1` |
| Clock | 100 MHz |
| Top module | `runtime_board_top` |
| Data path | 16-bit single-cycle |
| General registers | R0–R3 |
| Program counter | 10-bit |
| Program storage | writable 1K×16 program RAM |
| Data storage | 256×16 data RAM |
| Loader | UART binary loader selected by SW7 |
| Main applications | Snake, 2048, Running Light |

## ISA boundary

- Base arithmetic, logic, compare, branch and I/O instructions remain available.
- `D = LDR`, `E = STR`, `F = JMPA` in the current Runtime.
- `JUMP` and `JZ` select an 8-bit target inside the current 256-word page.
- `JMPA` selects a 10-bit absolute program address and is used for cross-page control flow.
- Machine code from older branches must not be mixed with the current Runtime without checking these definitions.

## Current verification result

- Native Vivado 2026.1/XSim pipeline completed `xvlog → xelab → xsim`.
- `tb_runtime_running_light_wave`: TEST PASS at 7576 ns; LED write sequence includes `0x01 → 0x02`.
- `tb_runtime_extended_isa_wave`: TEST PASS at 166 ns; covers `CMP/JZ/JUMP/JMPA` and `STR/LDR` data-memory access.
- Native artifacts are non-empty: WDB, VCD, WCFG and simulation logs.
- Five final English waveform figures are generated from native XSim VCD data.

## Existing implementation evidence

- WNS: `+0.157 ns`; TNS: `0`.
- WHS: `+0.049 ns`; THS: `0`.
- Unrouted nets: `0`.
- DRC errors: `0`.
- Utilization: 1204 LUT, 750 FF, 44 IOB.
- Included board bitstream SHA-256: `B0F2813099A7713DAD040DA765B50DF3B8DE8BBA3C6BAF7E2D49E1FF0DA15F71`.

The implementation reports and bitstream describe the verified Runtime hardware build. The latest application images are loaded through UART without changing that hardware. A new bitstream is required only to change the default power-on image or hardware RTL.

## Primary evidence files

- `runtime_system/reports/verification-summary.txt`
- `runtime_system/reports/waveforms/current_terminal/README.md`
- `runtime_system/reports/waveforms/current_terminal/vivado-xsim-run.log`
- `runtime_system/reports/waveforms/current_terminal/vivado/`
- `runtime_system/reports/waveforms/current_terminal/final_vivado_style/`
- `runtime_system/reports/implementation/`
- `runtime_system/reports/board/MiniRISC16_Runtime.bit`
