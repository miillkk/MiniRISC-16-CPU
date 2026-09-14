# MiniRISC-16 单周期 CPU + 8 位 GPIO

本工程按照 `docs/design/CPU项目说明_8位GPIO_单周期.md` 实现 16 位、4 寄存器、8 位 PC 的非流水线单周期 CPU，并集成 8 位逐位方向 GPIO。设计支持 13 个有效 opcode、3 个安全保留 opcode、组合读指令 ROM 和独立 I/O 接口。

## 当前实现

- `rtl/core/`：组合控制器、六功能 ALU、4×16 寄存器组、PC/Z/写回数据通路和 `cpu_core`。
- `rtl/peripherals/`：256×16 组合读指令 ROM、8 位 GPIO、异步拉低/两级同步释放复位。
- `rtl/top/system_top.v`：固定 `clk`、`resetn`、`gpio[7:0]` 板级边界和逐位三态驱动。
- `sim/tb/`：ALU、控制器、数据通路、复位、GPIO 和全系统六个自检 testbench。
- `sim/programs/system_demo.mem`：覆盖全部 16 个 opcode、JZ 两种结果、JUMP 和 GPIO I/O 的端到端程序。
- `sim/scripts/`：Vivado XSim 回归、VCD/WCFG 采集、SVG/PNG 波形渲染。
- `vivado_project/MiniRISC16_CPU.xpr`：已创建的 Vivado GUI 项目，part 设为 EES331 Zynq-7020 常用 `xc7z020clg400-1`。

指令字段、接口和逐 opcode 控制真值表见 [CONTROL_TABLE.md](docs/design/CONTROL_TABLE.md)，完整文件分类和依赖关系见 [FILE_LAYOUT.md](docs/FILE_LAYOUT.md)。若需要转成答辩或课堂讲解，可直接使用 [CPU设计与验证讲解稿.md](docs/CPU设计与验证讲解稿.md)。

## Vivado GUI 项目

已生成可直接打开的 Vivado 项目：

```text
vivado_project\MiniRISC16_CPU.xpr
```

项目配置：

- Design top：`system_top`
- Simulation top：`tb_system`
- FPGA part：`xc7z020clg400-1`，对应 EES331 开发板的 Zynq-7020 系列
- Design Sources：`rtl/core/*.v`、`rtl/peripherals/*.v`、`rtl/top/*.v`
- Simulation Sources：`sim/tb/*.v`、`sim/programs/system_demo.mem`

若需要重建 Vivado 项目，可运行：

```powershell
$env:MINIRISC_FPGA_PART="xc7z020clg400-1"
powershell -Command "& '<Vivado安装目录>\bin\vivado.bat' -mode batch -source './sim/scripts/create_vivado_project.tcl'"
```

## 一条命令回归

在工程根目录运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\sim\scripts\run_all.ps1
```

若自动搜索不到 Vivado：

```powershell
powershell -ExecutionPolicy Bypass -File .\sim\scripts\run_all.ps1 -VivadoBin "<Vivado安装目录>\bin"
```

脚本会在 `XILINXD_LICENSE_FILE` 未设置时自动检查常见本地许可证位置，包括 `%APPDATA%\XilinxLicense\Xilinx.lic`。本机 Vivado Basic 许可证中的 `Vivado_Simulation` 已通过该方式被 XSim 命令行识别。

脚本依次调用 `xvlog`、`xelab`、`xsim`，且只有 testbench 打印对应的 `TEST PASS` 才计为通过。成功回归会生成：

- `reports/simulation/*.txt`：每项测试日志和总汇；
- `reports/waveforms/system.vcd`、`system.wcfg`：原始波形；
- `reports/waveforms/system_pass_check.wcfg`、`system_pass_summary.wcfg`、`system_final_state.wcfg`：验收判定和最终状态用 Vivado 波形配置；
- `reports/waveforms/01_*.svg/png`～`04_*.svg/png`：单周期提交、分支跳转、寄存器/ALU、GPIO 四组审查图。
- `reports/waveforms/vivado_wave_gui_screenshot.png`：Vivado/XSim GUI 打开 `system.wcfg` 后的界面截图。
- `reports/waveforms/vivado_pass_check_screenshot.png`：Vivado/XSim GUI 打开 PASS 判定波形配置后的界面截图。
- `reports/waveforms/vivado_pass_summary_full_screenshot.png`、`vivado_final_state_full_screenshot.png`：一屏完整显示的 PASS 摘要和最终状态截图。

## ISA 摘要

| opcode | 指令 | opcode | 指令 |
|---:|---|---:|---|
| `0` | MOVI | `7` | AND |
| `1` | MOVR | `8` | JZ |
| `2` | ADDI | `9` | OR |
| `3` | ADDR | `A` | JUMP |
| `4` | XOR | `B` | INP |
| `5` | SUB | `C` | OUP |
| `6` | CMP | `D`～`F` | 保留安全操作 |

仅 CMP 更新 Z；JZ 使用此前保存的 Z。R0～R3 全部可写；立即数零扩展；PC 和 16 位算术自然回绕。GPIO 地址 `0x10/0x11/0x12` 分别是 OUT/IN/DIR。

## 本地验证状态

验证分为两部分：人工验证负责核对设计 md、接口表、opcode 控制真值表、GPIO 地址表和测试程序机器码；EDA 验证负责用 Vivado 2026.1 XSim 跑 RTL 仿真和波形。当前 XSim 回归已完成：六个 testbench 全部输出唯一 `TEST PASS`，波形渲染 PASS，最终汇总为 `Failures: 0`。系统级仿真生成了 `reports/waveforms/system.vcd`、`system.wcfg`、四组 SVG/PNG 审查波形、完整 Vivado GUI 截图以及 PASS 判定截图；详情见 [VERIFICATION.md](docs/verification/VERIFICATION.md) 和 `reports/simulation/`。

## 本阶段边界

本阶段不含 XDC、时序收敛、bitstream、ILA 或上板结论。`fpga/README.md` 列出后续所需的原理图、器件、时钟、电压和管脚信息。项目通过 Git 管理并同步到 GitHub。
