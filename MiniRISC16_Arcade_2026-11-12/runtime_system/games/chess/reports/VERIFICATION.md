# Build verification — 2026-11-12

- Chess program: 2235 / 4096 instruction words; data RAM variables 128..195.
- Model tests: PASS (initial legal moves 20/400, Kiwipete 48, special moves, check/mate/stalemate).
- Native Vivado XSim CPU: PASS (12-bit PC execution, Fool's mate, protocol XOR).
- Native Vivado XSim Loader: PASS (capacity, 4096 addresses, legacy 1024-word upload, oversized rejection).
- 50 MHz MMCM hardware implementation: PASS.
- Setup WNS: +4.734 ns; TNS 0.
- Hold WHS: +0.034 ns; THS 0.
- DRC: 0 errors; existing PL-only ZPS7-1 warning remains.
- Bitstream: MiniRISC16_Arcade4K.bit, 4045772 bytes.
- SHA256: 42726CC830BE7C17BE79D93C83AF33A73FB5A58E2D9DBB843BB2FEDF359EAC00
- Physical board / real serial session: NOT TESTED.
- Scope excludes repetition, move-count and dead-position draw adjudication, chess AI and clocks.

The original 100 MHz attempt failed timing and was not released. Reports under 100mhz_attempt document that attempt. Final timing.rpt, drc.rpt, utilization.rpt and build4k.log belong to the 50 MHz release.
