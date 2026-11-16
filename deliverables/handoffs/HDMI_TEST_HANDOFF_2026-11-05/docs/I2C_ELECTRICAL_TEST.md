# HDMI-I2C electrical test

## Bitstream

`i2c_electrical/MiniRISC16_HDMI_I2C_ElectricalTest.bit`

SHA-256: `82B160D655F48934E1EF8D52AF2FF1D745CD59D82B80CAF5F186A81354304B5C`

This image contains no CPU, game, video generator, ADV7511 register
transaction, or HDMI pixel output. It only drives the on-board ADV7511 I2C SCL
line low for 0.5 s, releases it for 0.5 s, always releases SDA, and displays the
commanded and sampled levels on LED3..0.

## Programming and observation

1. Power the EES331 board normally and connect J3 to the PC for JTAG.
2. Open Vivado Hardware Manager, connect to the target, and program the bitstream
   above. Do not use this image as the game image.
3. Release S1. Observe LED3..0 for at least five seconds.
4. Press and hold S1 once. While held, the design releases SCL and the expected
   value is LED3..0=`0111`. Release S1 and observe the alternating values again.
5. Record whether LED3..0 alternates between `0111` and `1100`.

LED meanings:

| LED | Meaning |
|---|---|
| L0 | SCL release command (`1` = FPGA releases SCL) |
| L1 | sampled SCL pad level |
| L2 | sampled SDA pad level |
| L3 | SCL drive-low command (`1` = FPGA drives SCL low) |

Expected patterns:

| Half-cycle | L3..L0 | Meaning |
|---|---:|---|
| SCL released | `0111` | command released, SCL rose, SDA high |
| SCL driven low | `1100` | command low, sampled SCL low, SDA high |

Interpretation:

- `0111`/`1100` alternate: FPGA pin, SCL pull-up, SDA pull-up, and readback are
  electrically working. The original stall is then in the I2C transaction or
  ADV7511 state/configuration, not a dead FPGA output pin.
- Release half-cycle has L0=1 but L1=0: SCL cannot rise. Check VADJ, R110,
  soldering/shorts, and whether the ADV7511 is holding SCL low.
- L2 remains 0: SDA cannot rise. Check VADJ, R140, soldering/shorts, and the
  ADV7511 SDA connection.
- L1 never goes low while L3=1: the FPGA is not reaching or controlling the SCL
  pad as expected; recheck the programmed file and AB10 assignment.

## Static build evidence

- Device: `xc7z020clg484-1`.
- Route: 55/55 routable nets fully routed; 0 routing errors.
- DRC: 0 errors. `ZPS7-1` is expected for this PL-only JTAG image. `RPBF-3` is
  expected because SDA is deliberately input-only/released in this diagnostic.
- Timing: WNS `+5.601 ns`, TNS `0`, WHS `+0.233 ns`; all user timing constraints
  met at 100 MHz.

