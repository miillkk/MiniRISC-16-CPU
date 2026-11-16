# HDMI diagnostic build status (2026-10-17)

**Board-level I2C electrical-test bitstream is available (2026-10-30):**

File: `i2c_electrical/MiniRISC16_HDMI_I2C_ElectricalTest.bit`  
SHA-256: `82B160D655F48934E1EF8D52AF2FF1D745CD59D82B80CAF5F186A81354304B5C`  
Implementation: WNS `+5.601 ns`, TNS `0`, WHS `+0.233 ns`, DRC `0 Error`,
55/55 routable nets fully routed.

This image contains no CPU, game, video output, or I2C transaction. It drives
SCL low for 0.5 s, releases it for 0.5 s, and always releases SDA. Expected
LED3..0 patterns are `0111` while released and `1100` while driven low. The
complete procedure and interpretation are in `I2C_ELECTRICAL_TEST.md`.

**Internal-pull-up diagnostic bitstream is now available (2026-10-30):**

File: `link_pullup_eco/MiniRISC16_HDMI_PullupDiagnostic.bit`  
SHA-256: `9C11C96F1D64EF754F688A53E6B00564C0061590D1AB3755A8DD0FB70D7EDA1F`  
Implementation: WNS `+4.268 ns`, TNS `0`, WHS `+0.163 ns`, DRC `0 Error`,
498/498 routable nets fully routed. The two reported warnings are the known
loadless diagnostic net and PL-only `ZPS7-1` warning.

This image retains the third diagnostic LED mapping and enables the 7-series
IOB weak pull-up option on both `iic_scl_hdmi` and `iic_sda_hdmi`. It is for
distinguishing a missing/ineffective external I2C pull-up from a line actively
held low by the external HDMI circuit. With SW0=1: LED7..3 = I2C state, LED2 =
sampled SCL, LED1 = sampled SDA, LED0 = SCL released by the FPGA.

**Board observation with the first link-only bitstream:** after S1 reset,
only L5 and L2 are lit, and the monitor reports no signal. Under the first
diagnostic LED mapping this is controller state `2` (waiting for the first
register read) with the I2C master busy. It does **not** establish whether
SCL is electrically stuck, the slave is stretching, or the RTL is stalled.

**Board observation with the second bus diagnostic bitstream:** SW0=1 shows
L5 and L3 lit while L2 is off. This encodes I2C state `5` (`S_TX_HIGH`),
with sampled SCL low. Holding S1 makes L1 and L2 light and L5 go out:
SDA and SCL both rise while the I2C master is reset/released. After S1 is
released, L5 and L3 light again. The first transaction stalls while trying
to raise SCL; the exact driver holding it low remains unverified.

**Third SCL-drive diagnostic bitstream is now available:**

File: `link_drive_eco/MiniRISC16_HDMI_SCLDiagnostic.bit`  
SHA-256: `BE468FDBB5564EFEAF08EFF502FB047BE1030C3137FBC6A3F6207419968164D8`  
Implementation: WNS `+4.268 ns`, TNS `0`, DRC `0 Error`, no unrouted nets.

It was produced by a one-net ECO from the already verified second diagnostic
checkpoint because fresh synthesis still exits with Vivado's native
`EXCEPTION_ACCESS_VIOLATION`. With SW0=1, LED7..3 remain the I2C state, LED2 is
sampled SCL, LED1 is sampled SDA, and LED0 is the SCL IOBUF tristate control
(`1` = FPGA released SCL, `0` = FPGA drives SCL low). This is the next file to
program on the board.

Further retries on 2026-10-17 confirmed this is not a long-running/hung job:
Vivado exited by itself. Reducing the build to only reset/video/diagnostic RTL
still ended in `EXCEPTION_ACCESS_VIOLATION` after elaboration. A routed-checkpoint
inspection succeeded once and confirmed the internal SCL-related nets remain
available, but a later identical read crashed while restoring timing. The next
startup failed before opening the checkpoint with `bad allocation` and
`Could not load library 'xv_coretasks'`, while the host still reported about
22 GB available virtual memory. License detection succeeded. No Vivado process
was left running. This points to the Vivado 2026.1 installation/runtime state,
not a license wait or a deterministic RTL compile error.

**Second, more detailed bus diagnostic bitstream is now available:**

File: `link_detail/MiniRISC16_HDMI_BusDiagnostic.bit`  
SHA-256: `9DED703AA7815813088E4EF0F9904E1A16308C8D50B9CFD9688A3E61F44B1D77`  
Implementation: WNS `+4.268 ns`, TNS `0`, WHS `+0.163 ns`, DRC `0 Error`
(one expected PL-only `ZPS7-1` warning). Bitgen completed successfully.
With this build, SW0=0 shows the first controller page; SW0=1 shows
I2C state on LED7..3, SCL on LED2, SDA on LED1, ACK error on LED0.
Physical testing produced the state-5/SCL-low observation documented above.

**The HDMI-only link diagnostic bitstream is available and statically verified.**

File: `link_only/MiniRISC16_HDMI_LinkDiagnostic.bit`  
SHA-256: `2B067EEC426C60D55743B3F278D5CFA07CD6E37FB20AA8511FD1C9DC4A2486B3`  
Implementation: WNS `+4.096 ns`, TNS `0`, WHS `+0.164 ns`, DRC `0 Error`
(one expected PL-only `ZPS7-1` warning). Bitgen completed successfully.

This build removes the CPU/game and drives color bars continuously. It has
**not** yet been tested on the physical board. Program this file only for HDMI
fault isolation, then send the complete LED7..0 pattern after pressing S1.

The full-system diagnostic bitstream below is still unavailable.

The existing game bitstream remains unchanged at `reports/board/MiniRISC16_HDMISnake.bit`
(SHA-256 `BA5B7B3A314A72495435F0CA260FC7B332D6E2FF0BDCDCB18C4FEA86095D520A`).

The diagnostic RTL selects an LED display of the ADV7511 controller state without
changing board pins. Vivado completed RTL elaboration and synthesis on the third
attempt; `diagnostic_synth.dcp` is saved here. It repeatedly crashed with
`EXCEPTION_ACCESS_VIOLATION` or Windows exit code `-1073740940` during placement.
Therefore there is no routed/timing-checked design or diagnostic `.bit`.

The independent CPU reference model passed. The latest XSim regression attempt
compiled and statically elaborated the RTL, then all ten tests failed at XSim's
generated-C compilation step (`XSIM 43-3409`); dynamic simulation is not claimed.

When Vivado is stable, retry from the synthesis checkpoint:

```powershell
cd C:\Users\xieke\Desktop\CPU\MiniRISC-16-CPU\refactored_design\hdmi_snake_system
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_diagnostic.ps1 -FromCheckpoint
```

Only use the full-system `MiniRISC16_HDMI_Diagnostic.bit` after the command prints
`HDMI DIAGNOSTIC BITSTREAM PASS` and the timing/DRC reports pass.

Diagnostic LED mapping: LED7..4 = controller state (binary 0..9), LED3 = HPD
detected, LED2 = I2C master busy, LED1 = fault, LED0 = ready. This mapping is
**different** from the normal game bitstream.

State codes: 0=startup delay, 1=start HPD read, 2=wait for HPD read,
3=retry delay, 4=start configuration write, 5=wait for write,
6=PLL settling delay, 7=start PLL read, 8=wait for PLL read,
9=ready/recheck delay. A persistent state 2 with LED2=1 suggests I2C is
stalled; state 3 with LED3=0 and LED1=0 means the chip responded but HPD was
not detected. These are diagnostic interpretations, not yet board observations.

For the HDMI-only bitstream, seven-segment displays are intentionally off and
SW6/SW7 are ignored. The LED mapping above applies; it differs from the normal
game bitstream's LED5/LED6 meanings.
