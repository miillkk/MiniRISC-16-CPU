# File Manifest

## Included

- `README_FIRST.md`: recipient entry point.
- `docs/`: current version definition, ready-to-share English project evolution PNG/SVG, the detailed branch map and the Chinese explanation document.
- `runtime_system/rtl/`: synthesizable current non-HDMI RTL.
- `runtime_system/constraints/`: EES331 runtime constraints.
- `runtime_system/program/`: current Snake source, listing and image.
- `runtime_system/games/`: 2048 and Running Light sources, images, reference models and terminal tools.
- `runtime_system/tools/`: assembler, uploader, reference model, launcher and Snake terminal.
- `runtime_system/scripts/`: Vivado project, synthesis, bitstream, regression and waveform scripts.
- `runtime_system/tb/`: RTL testbenches, including current waveform tests.
- `runtime_system/vivado_project/MiniRISC16_Runtime.xpr`: Vivado project entry point.
- `runtime_system/reports/`: selected verification, waveform, synthesis, implementation and board evidence.

## Excluded

- HDMI Snake and HDMI diagnostic branches.
- Standalone calculator, Snake V1 and original CPU branches.
- Vivado generated caches, `.Xil`, run directories and temporary simulation build products.
- Browser profiles, crash dumps, backup journals and redundant historical waveform renders.
- ZIP backups and unrelated courseware.

## Report-version rule

When discussing this package, “current version” always means the latest non-HDMI `runtime_system` with 10-bit PC, 1K×16 writable program RAM, 256×16 data RAM and `LDR/STR/JMPA`.
