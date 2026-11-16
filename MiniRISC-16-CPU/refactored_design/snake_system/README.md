# MiniRISC-16 Serial Snake

这是一个完全独立的 EES331 贪吃蛇系统。游戏规则由 FPGA 内的 MiniRISC-16 CPU 执行汇编程序；PL UART 负责与电脑终端交换按键和 8×8 棋盘帧，板载数码管显示分数，LED 显示方向和游戏状态。

## 系统层级

```text
snake_board_top
├─ reset_conditioner
├─ snake_soc
│  ├─ snake_program_rom        256×16，249 条有效程序
│  ├─ cpu_core
│  │  ├─ controller
│  │  └─ datapath
│  ├─ data_memory              256×16 蛇身与串口帧
│  └─ snake_peripheral_subsystem
│     ├─ uart_port
│     ├─ tick_timer
│     ├─ lfsr8
│     ├─ switch8_sync
│     ├─ display_registers
│     ├─ led8
│     ├─ scratchpad16
│     └─ io_decoder
└─ seven_segment8_driver
```

## CPU 与程序

原有 `MOVI/MOVR/ADDI/ADDR/XOR/SUB/CMP/AND/JZ/OR/JUMP/INP/OUP` 保持不变。新系统使用两个此前保留的 opcode：

| opcode | 指令 | 功能 |
|---|---|---|
| `D` | `LDR Rd, Rs` | `Rd ← data_memory[Rs[7:0]]` |
| `E` | `STR Rd, Rs` | `data_memory[Rd[7:0]] ← Rs` |
| `F` | 保留 | 无副作用 |

`program/snake.asm` 共 249 条有效指令。汇编器同时生成供参考模型使用的 `snake.mem`、便于检查的 `snake.lst`，以及供综合使用的 `rtl/memory/snake_program_rom.v`。CPU 完成方向解析、反向输入保护、定时移动、蛇身衰减、食物碰撞、增长、计分、墙壁碰撞和重新开始。

## I/O 地址

| 地址 | 方向 | 功能 |
|---|---|---|
| `10` | R/W | UART RX 数据 / UART TX 数据 |
| `11` | R | bit2 overrun、bit1 TX ready、bit0 RX valid |
| `12` | R | bit0 移动 tick；读取后确认 |
| `13` | R | 8 位 LFSR 随机数；读取后推进 |
| `20` | R/W | 数码管低 4 位值，即分数 |
| `21` | R/W | 数码管高 4 位值，运行时 `005A`，死亡时 `DEAD` |
| `22` | R/W | 数码管使能与小数点控制 |
| `30` | R/W | LED 状态 |
| `31` | R | 同步后的拨码输入 |
| `32` | R | CPU V/C/N/Z |
| `40～4F` | R/W | 16×16 位软件全局变量 |

## 板上操作

- `S1`：复位游戏。
- `S2/S3`：板上接到 Zynq PS 复位网络，本纯 PL 贪吃蛇不使用。
- `SW1..0`：速度，`00/01/10/11` 约为 2/4/8/16 格每秒。
- `SW2`：暂停。
- `SW7..3`：在按 S1 时参与随机种子。
- `LED1..0`：方向，0 上、1 右、2 下、3 左。
- `LED4`：运行。
- `LED7`：Game Over。
- J8 上方 USB 串口：115200、8N1，使用 `W/A/S/D` 或方向键，`R` 重启。

详细步骤见 `BOARD_TEST_GUIDE.md`。

## 构建与验证

```powershell
.\scripts\run.ps1 -Task Assemble -VivadoBin "F:\vivado\2026.1\Vivado\bin"
.\scripts\run.ps1 -Task Regression -VivadoBin "F:\vivado\2026.1\Vivado\bin"
.\scripts\run.ps1 -Task CreateProject -VivadoBin "F:\vivado\2026.1\Vivado\bin"
.\scripts\run.ps1 -Task Bitstream -VivadoBin "F:\vivado\2026.1\Vivado\bin"
```

电脑端界面：

```powershell
.\tools\snake_terminal.ps1
.\tools\snake_terminal.ps1 -PortName COM4
```

当前汇编与参考模型通过，Vivado XSim 回归 4/4 PASS，综合、布局布线和 Bitgen 均成功。100 MHz 时序 WNS 为 `+0.192 ns`、TNS 为 `0`，DRC 0 error（仅保留纯 PL/JTAG 设计预期的 `ZPS7-1` warning）。可直接下载的文件为 `reports/board/MiniRISC16_Snake.bit`。准确状态见 `reports/verification-summary.txt` 和 `BUG_FIX_LOG.md`。
