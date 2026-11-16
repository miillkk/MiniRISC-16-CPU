# MiniRISC-16 交互式计算系统

这是一个完全独立的 EES331 上板工程。MiniRISC-16 CPU 通过执行 240 条以内的 ROM 程序完成输入交互、加减、逻辑、软件乘除和比较。工程不依赖外层 `refactored_design` 的 RTL 文件。

## 功能

- SW7..0：输入 `00～FF` 的完整 8 位无符号十六进制数。
- S1 短按并松开：确认当前输入；硬件去抖约 10 ms。
- S1 持续按住约 1 秒：复位整个计算系统。
- S2/S3 是 Zynq PS 专用复位按键，本纯 PL 系统不使用。
- 八位数码管：显示输入阶段、操作数和结果。
- LED2..0：运算编号。
- LED3..6：Z、N、C、V。
- LED7：除零错误。

运算编号：

| 编号 | 运算 | 编号 | 运算 |
|---:|---|---:|---|
| 0 | ADD | 4 | XOR |
| 1 | SUB | 5 | MUL（软件循环） |
| 2 | AND | 6 | DIV（软件循环） |
| 3 | OR | 7 | CMP |

CMP 返回：小于为 0、相等为 1、大于为 2。DIV 显示格式为 `AABBqqrr`，其余正常结果为 `AABBrrrr`。

## 层级

```text
calculator_board_top
├─ power_on_reset
├─ button_s1_controller
├─ calculator_soc
│  ├─ instruction_memory
│  ├─ cpu_core
│  │  ├─ controller
│  │  └─ datapath
│  └─ peripheral_subsystem
│     ├─ io_decoder
│     ├─ display_registers
│     ├─ led8
│     ├─ switch8_input
│     ├─ cpu_status_port
│     └─ scratchpad_ram
└─ seven_segment8_driver
   └─ hex_to_7seg
```

## I/O 地址

| 地址 | 功能 |
|---|---|
| `20` | 数码管低 16 位 |
| `21` | 数码管高 16 位 |
| `22` | 数码管控制 |
| `30` | LED |
| `31` | bits7..0 完整拨码输入值 |
| `32` | bits6..3 = V/C/N/Z |
| `33` | bit1 输入有效、bit0 S1 确认令牌 |
| `40～4F` | 16×16 位 Scratchpad |

Scratchpad 采用组合读、同步写。为满足复位清零语义，本版在器件中实现为寄存器阵列，而不是 BRAM。

## 主要文件

- Vivado 工程：`vivado_project/MiniRISC16_Calculator.xpr`
- 可直接上板文件：`reports/board/MiniRISC16_Calculator.bit`
- 汇编源码：`program/calculator.asm`
- ROM 文件：`program/calculator.mem`
- 整体 testbench：`tb/tb_calculator_system.v`
- 上板说明：`BOARD_TEST_GUIDE.md`
- Bug 记录：`BUG_FIX_LOG.md`

## 构建

在本目录打开 PowerShell：

```powershell
.\scripts\run.ps1 -Task Assemble -VivadoBin "F:\vivado\2026.1\Vivado\bin"
.\scripts\run.ps1 -Task Regression -VivadoBin "F:\vivado\2026.1\Vivado\bin"
.\scripts\run.ps1 -Task CreateProject -VivadoBin "F:\vivado\2026.1\Vivado\bin"
.\scripts\run.ps1 -Task Synthesis -VivadoBin "F:\vivado\2026.1\Vivado\bin"
.\scripts\run.ps1 -Task Bitstream -VivadoBin "F:\vivado\2026.1\Vivado\bin"
```

`-Task All` 会依次汇编、运行参考模型和 RTL 回归、创建工程并生成 bitstream。

## 已完成验证

- 汇编：240 个有效字，16 个保留字。
- 独立指令参考模型：15/15 PASS。
- Vivado XSim RTL 回归：9/9 PASS，并生成 VCD/WDB。
- 整体 testbench 覆盖全部 8 种运算、结果保持、重新开始和复位。
- 板级顶层 testbench 已覆盖 S1 短按确认和长按复位。
- 新版脚本模式综合、实现和 bitstream 已通过；当前打开的 Vivado GUI 关闭后需运行 `-Task CreateProject` 刷新 XPR 源文件列表。
- 目标器件：`xc7z020clg484-1`。
- 100 MHz：WNS `+0.559 ns`，TNS `0.000 ns`；WHS `+0.202 ns`，THS `0.000 ns`。
- 路由：0 条失败网络、0 条未布通网络。
- 方法学检查：0 项。
- DRC：仅保留纯 PL/JTAG 方案已知的 `ZPS7-1` 警告。
- 资源：444 Slice LUT、494 Slice Register、42 IOB、1 BUFG。
- Bitstream SHA-256：`E8B9984318B8A8D33639D54C4E5C425A926B63323A09F8C07640C9E2BA6CD404`。

实板功能仍需按 `BOARD_TEST_GUIDE.md` 完成最终人工验收。
