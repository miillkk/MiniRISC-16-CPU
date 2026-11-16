# Chess CPU AI verification — 2026-11-12

- Program: 2792 / 4096 instruction words; data RAM variables 128..210.
- Protocol: v7, 70-byte frames; side byte bit6 selects CPU opponent, bit3 indicates side to move.
- Execution: move generation, legal-move filtering and scoring run entirely as MiniRISC-16 instructions.
- AI: deterministic single-ply material / promotion / centre / destination-exposure score; white human, black CPU; automatic queen promotion.
- Rules model regression: PASS (20/400 initial counts, Kiwipete 48, special moves, mate/stalemate).
- AI model tests: PASS (mode/reset, autonomous reply, rejection, capture/exposure scoring, check evasion, promotion, special-move trial restoration, terminal conditions).
- Native XSim CPU: PASS (high PC, Fool's mate, AI mode and autonomous e2-e4 reply, XOR).
- Native XSim Loader: PASS (4096 addresses, legacy 1024 upload, capacity and oversized rejection).
- PowerShell scripts: syntax parsing PASS.
- Physical board and real serial UI: not yet tested.
- Program SHA256: B81340CCC7212A5EA075D3D2D182E90FB1CFB8736436666EF6BAC783F5FA21B4

Use menu 6 to upload the new program, then select mode 2. Existing released 4K bitstream remains valid; its built-in default is the older v6 two-player program, so re-upload after power loss or FPGA reconfiguration. No new hardware implementation was required for this AI update. Prior bitstream timing evidence remains in VERIFICATION.md.

Current simulation evidence: chess4k.log and loader4k.log. The older xsim.log belongs to the prior two-player release. AI tests are reproducible via tools/verify_ai.cjs or tools/build.ps1 -Simulate.
