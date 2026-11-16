# MiniRISC-16 CPU 项目演进与当前终端版答辩讲解稿

更新日期：2026-11-05。当前主展示版本为最新非 HDMI `runtime_system`；计算器和早期流水灯作为项目发展过程中的应用分支保留。

## 1. 使用说明

这份讲解稿与 `PROJECT_BRANCH_MAP.md` 配套，可直接作为项目发展说明阅读或用于现场讲解。内容不依赖现场下载 bitstream，主要使用以下证据：

- 系统架构与数据通路图
- 项目分支和 CPU/ISA 演进图
- 流水灯、计算器、Snake、2048 等程序实例
- 关键汇编代码
- 当前非 HDMI 终端版的原生 Vivado/XSim 波形
- 综合、实现和回归结果

早期流水灯和计算器内容作为项目发展过程中的应用案例保留，但涉及 PC 位宽、程序容量和 opcode `D/E/F` 时必须标明版本。当前结构和 ISA 以 10 位 PC、1K×16 程序 RAM、`LDR/STR/JMPA` 为准。

---

## 2. 项目总体介绍

本项目在 EES331 开发板的 Zynq-7020 FPGA 可编程逻辑区域中实现一个自定义 16 位软核 CPU。CPU 由 Verilog RTL 描述并综合到 FPGA 逻辑资源中，不是使用 Zynq PS 端已有的 ARM 处理器完成计算。

CPU 采用自定义 MiniRISC-16 指令集，能够完成：

- 立即数和寄存器之间的数据传送
- 加法、减法以及与、或、异或运算
- 比较和条件跳转
- 无条件跳转
- 独立端口输入和输出

项目不是一次性完成，而是沿着“CPU 基线—模块化—板级应用—可编程 Runtime”的路线逐步发展：

```text
原始 16 位单周期 CPU（8 位 PC，基础 ISA）
  → 模块化 CPU + Z/N/C/V
  → EES331 板级演示
     ├─ 验证展示：ISA 自检 / 流水灯 / 指令波形
     ├─ 运算应用：交互式计算器
     └─ 游戏与 Runtime：Snake V1
          → 当前非 HDMI Runtime（10 位 PC，1K 程序 RAM，LDR/STR/JMPA）
             ├─ Snake / 2048 / Running Light 终端 Arcade
             ├─ 2026-11-04 当前结构原生 XSim 波形验证
             └─ HDMI 历史扩展与链路诊断
```

流水灯证明持续取指、循环和 I/O；计算器证明基础 ISA 可以用软件实现乘除和交互状态机；Snake 首次加入 `LDR/STR` 和数据 RAM；当前 Runtime 再把 PC 扩为 10 位、程序空间扩为 1K×16，并加入跨页 `JMPA` 和 UART Loader。同一硬件现在可按需装载 Snake、2048 或 Running Light，体现处理器与固定功能电路的区别。

---

## 3. 系统架构分析

### 3.1 总体层次

计算器系统的主要层次可以概括为：

```text
calculator_board_top
├── power_on_reset
├── button_s1_controller
├── calculator_soc
│   ├── instruction_memory
│   ├── cpu_core
│   │   ├── controller
│   │   └── datapath
│   │       ├── register_file
│   │       ├── alu
│   │       └── status_register
│   └── peripheral_subsystem
│       ├── io_decoder
│       ├── display_registers
│       ├── led8
│       ├── switch8_input
│       ├── cpu_status_port
│       └── scratchpad_ram
└── seven_segment8_driver
    └── hex_to_7seg
```

从功能上看，可以分成五部分：

```text
拨码和按键
    ↓
输入同步、按键去抖与确认令牌
    ↓
MiniRISC-16 CPU ← 指令 ROM
    ↓
I/O 地址译码与 Scratchpad
    ↓
LED 和八位数码管
```

### 3.2 指令存储器

指令存储器接收 CPU 输出的 8 位 `mem_addr`，返回对应的 16 位指令。8 位地址可以表示 256 个指令字位置。

当前设计采用组合读取：PC 改变后，指令输出在同一周期内随之变化。这种实现适合单周期 CPU，因为取指、译码和执行需要在两个相邻时钟上升沿之间完成。

如果以后把组合 ROM 换成同步 BRAM，读取结果会晚一个时钟周期，当前单周期数据通路将不能直接工作，需要增加取指状态或流水寄存器。

### 3.3 CPU Core

CPU Core 由 Controller 和 Datapath 两个主要部分组成。

Controller 负责：

- 从指令中拆分 opcode、Rd、Rs 和 imm8/port 字段
- 根据 opcode 选择 ALU 运算
- 控制寄存器写回
- 控制 Flags 更新
- 控制 JZ 和 JUMP
- 产生 I/O 读写使能

Datapath 负责：

- 保存和更新 PC
- 读取 R0 至 R3
- 扩展立即数
- 选择 ALU 第二操作数
- 执行 ALU 运算
- 选择写回数据
- 更新 Z、N、C、V 标志
- 选择 PC+1、条件跳转目标或无条件跳转目标

### 3.4 外设子系统

计算器不是把拨码和数码管直接接到 CPU 寄存器，而是通过独立 I/O 地址空间访问外设。

主要地址如下：

| 地址 | 功能 | 访问方向 |
|---|---|---|
| `0x20` | 数码管低 16 位显示寄存器 | 读写 |
| `0x21` | 数码管高 16 位显示寄存器 | 读写 |
| `0x22` | 数码管控制寄存器 | 读写 |
| `0x30` | LED 输出寄存器 | 读写 |
| `0x31` | 八位拨码输入 | 只读 |
| `0x32` | CPU 状态标志 Z/N/C/V | 只读 |
| `0x33` | 输入有效位和 S1 确认令牌 | 只读 |
| `0x40～0x4F` | 16×16 位 Scratchpad | 读写 |

`io_decoder` 根据 `io_addr` 和 `io_re/io_we` 选择外设。读取时，它把被选外设的数据送回 CPU；写入时，它只给目标外设产生写使能，避免多个外设同时更新。

### 3.5 Scratchpad 的作用

CPU 只有四个通用寄存器，而计算器需要长期保存 A、B、运算编号、中间结果、商、余数和按键状态。因此系统增加了地址 `0x40～0x4F` 的 Scratchpad。

Scratchpad 不是通过 LDR/STR 指令访问的普通数据存储器。程序仍然使用 `INP` 和 `OUP` 指令，把它当作一组映射到 I/O 空间的 16 位寄存器。

这种设计的优点是无需扩展 CPU 的访存指令和总线结构，代价是 Scratchpad 与普通外设共用 I/O 访问方式。

### 3.6 当前非 HDMI Runtime 结构

计算器说明的是早期基础 ISA 应用；当前展示版本已经发展为独立的 Runtime：

```text
runtime_board_top
├── reset_conditioner
├── runtime_soc
│   ├── runtime_program_memory   1K×16，可由 UART Loader 写入
│   ├── program_loader
│   ├── cpu_core                10 位 PC，16 位数据通路
│   │   ├── controller
│   │   └── datapath
│   ├── data_memory             256×16，供 LDR/STR 使用
│   └── peripheral_subsystem
│       ├── uart_port
│       ├── tick_timer
│       ├── lfsr8
│       ├── display_registers
│       ├── led8
│       ├── scratchpad16
│       └── io_decoder
└── seven_segment8_driver
```

SW7 选择 Loader/Run。进入 Loader 后无需重新生成 bitstream，即可把 Snake、2048 或 Running Light 的机器码写入程序 RAM；退出 Loader 后 CPU 从 `0x000` 执行新程序。该结构是当前非 HDMI 终端版，也是本轮波形重新验证的对象。

---

## 4. CPU 数据通路与单周期原理

### 4.1 指令格式

MiniRISC-16 指令宽度为 16 位：

```text
15            12 11       10 9         8 7                 0
+----------------+-----------+-----------+-------------------+
|    opcode      |    Rd     |    Rs     |     imm8/port     |
+----------------+-----------+-----------+-------------------+
```

- `opcode[15:12]`：指令类别
- `Rd[11:10]`：目的寄存器，也可作为 ALU A 操作数
- `Rs[9:8]`：源寄存器，也可作为 ALU B 操作数或 OUP 数据源
- `imm8/port[7:0]`：立即数、跳转地址或 I/O 端口地址

### 4.2 指令集及版本差异

| Opcode | 指令 | 功能 |
|---|---|---|
| `0` | `MOVI Rd, imm8` | 将零扩展立即数写入 Rd |
| `1` | `MOVR Rd, Rs` | 将 Rs 复制到 Rd |
| `2` | `ADDI Rd, imm8` | Rd 与立即数相加 |
| `3` | `ADDR Rd, Rs` | Rd 与 Rs 相加 |
| `4` | `XOR Rd, Rs` | 按位异或 |
| `5` | `SUB Rd, Rs` | Rd 减 Rs |
| `6` | `CMP Rd, Rs` | 比较两个寄存器并更新 Flags |
| `7` | `AND Rd, Rs` | 按位与 |
| `8` | `JZ addr` | Z=1 时跳转 |
| `9` | `OR Rd, Rs` | 按位或 |
| `A` | `JUMP addr` | 无条件跳转 |
| `B` | `INP Rd, port` | 从 I/O 端口读入 Rd |
| `C` | `OUP port, Rs` | 将 Rs 写入 I/O 端口 |
| `D` | 基础版保留；Runtime 为 `LDR Rd,[addr8]` | 从 256×16 数据 RAM 读入寄存器 |
| `E` | 基础版保留；Runtime 为 `STR Rs,[addr8]` | 把寄存器写入 256×16 数据 RAM |
| `F` | 基础版保留；Runtime 为 `JMPA addr10` | 跳转到 10 位绝对程序地址 |

基础板级演示和计算器仍使用 8 位 PC，`D/E/F` 保留。Snake V1 使用 `D=LDR`、`E=STR`，但 PC 仍为 8 位。当前 Runtime 使用 10 位 PC，`JUMP/JZ` 跳到当前 256 字页内的目标，跨页跳转使用 `JMPA`。因此旧版本机器码和当前 Runtime 不能在不核对 ISA 的情况下混用。

### 4.3 三个关键多路选择器

数据通路中有三个特别关键的选择位置。

#### ALU-B MUX

```text
R[Rs] ─────────────┐
                   ├── ALU-B MUX ──→ ALU operand B
zero_extend(imm8) ─┘
```

寄存器型指令使用 `R[Rs]`，立即数指令使用零扩展后的 `imm8`。

#### Writeback MUX

```text
ALU result ─┐
            ├── Writeback MUX ──→ R[Rd]
I/O data ───┘
```

普通运算指令写回 ALU 结果，`INP` 写回外设返回的数据。

#### Next-PC MUX

```text
PC + 1 ─────────────┐
JZ page target ─────┤
JUMP page target ───┼── Next-PC MUX ──→ PC
JMPA absolute ──────┘
```

默认情况下 PC 加一。JZ 在 Z 标志为 1 时选择页内目标，JUMP 无条件选择页内目标；当前 Runtime 的 JMPA 直接选择 10 位绝对地址。

### 4.4 单周期执行过程

单周期并不表示 CPU 只有一个功能步骤，而是所有组合步骤在一个时钟周期内完成。

```text
时钟上升沿 N
    ↓
PC 稳定
    ↓
ROM 组合输出 instruction
    ↓
Controller 译码，Register File 组合读
    ↓
ALU 运算或 I/O 组合读取
    ↓
形成 writeback_data 和 pc_next
    ↓
时钟上升沿 N+1
    ↓
同时提交 PC、寄存器、Flags 或外设写入
```

所以普通指令理论 CPI 为 1，但时钟周期必须长到足以覆盖最慢的组合路径。

### 4.5 Flags

计算器版本使用四个状态标志：

- Z：结果为零
- N：结果最高位为 1
- C：无符号加法进位或减法相关的无符号关系
- V：有符号溢出

`status_register` 只在 `flags_write` 有效时更新。MOV、逻辑运算、INP、OUP 和跳转不会随意破坏已保存的标志。

JZ 使用状态寄存器中已经保存的 Z，而不是在 JZ 指令周期重新计算一个临时零值。

---

## 5. 流水灯程序原理

### 5.1 输出序列

流水灯的逻辑值按照下面的顺序循环：

```text
01 → 02 → 04 → 08 → 10 → 20 → 40 → 80 → 01
```

每个数只有一个二进制位为 1，因此每次只点亮一个 LED。开发板上 LED 的物理排列可能让视觉方向看起来相反，但逻辑值顺序不变。

### 5.2 初始化与第一次输出

```asm
MOVI R0, 0x01
OUP  0x30, R0
```

第一条指令把 `0x01` 写入 R0，第二条指令把 R0 写入 LED 端口 `0x30`。LED 外设在时钟沿锁存该值，因此 LED0 点亮并保持，不需要 CPU 持续驱动同一个组合信号。

### 5.3 延时循环

程序使用三层 `0xFF` 倒计数循环产生肉眼可见的延时：

```asm
MOVI R3, 0x01
MOVI R1, 0xFF
MOVI R2, 0xFF
MOVI R0, 0xFF

INNER:
    SUB  R0, R3
    JZ   INNER_DONE
    JUMP INNER
```

FPGA 的 CPU 时钟为 100 MHz。如果不加入延时，LED 会以人眼无法分辨的速度变化。延时循环消耗大量指令周期，把逻辑变化速度降低到约每步 0.5 秒。

### 5.4 移位原理

CPU 没有专门的移位指令，因此程序用寄存器自加实现左移：

```asm
ADDR R0, R0
```

`R0 + R0` 等于 `R0 × 2`，对于单比特模式就相当于左移一位：

```text
0000_0001 + 0000_0001 = 0000_0010
0000_0010 + 0000_0010 = 0000_0100
```

这段代码说明复杂功能不一定要求专用指令，可以组合现有基础指令实现。

### 5.5 回卷判断

```asm
INP  R0, 0x30
MOVI R1, 0x80
CMP  R0, R1
JZ   WRAP
ADDR R0, R0
OUP  0x30, R0
```

程序先读取当前 LED 寄存器。如果当前值已经是 `0x80`，则跳转到 `WRAP`，直接重新写入 `0x01`。

检测发生在移位之前非常重要。如果先把 `0x80` 左移，8 位 LED 结果会变成 `0x00`，流水灯在回卷时会多出一个全灭节拍。当前实现已经修复这个边界问题。

### 5.6 流水灯证明了什么

流水灯不只是 LED 驱动测试，它同时证明：

- PC 能持续取指
- SUB、ADDR 和 CMP 能正确执行
- Z 标志和 JZ 能组成条件分支
- JUMP 能形成循环
- INP 能读回外设寄存器
- OUP 能正确写 LED 端口
- 复位后 CPU 能从地址 0 重新开始

---

## 6. 交互式计算器原理

### 6.1 交互状态

计算器程序按以下阶段运行：

```text
输入 A → 确认 → 输入 B → 确认 → 选择运算 → 确认 → 结果保持
```

S1 短按并松开表示确认。长按约 1.2 秒触发系统复位。硬件按键控制器负责去抖，避免一次机械按键被 CPU 识别成多次确认。

程序使用确认令牌而不是简单读取按键电平。每次有效按键动作改变令牌，程序把当前令牌与上一次保存值比较，从而只对新的按键事件响应一次。

### 6.2 输入锁存

输入 A 后，程序把拨码值写入 Scratchpad 地址 `0x40`：

```asm
LATCH_A:
    OUP  0x40, R1
    JUMP ENTER_B
```

输入 B 后，程序写入 `0x41`：

```asm
LATCH_B:
    OUP  0x41, R1
```

这样拨码继续变化时，已经确认的 A 和 B 不会改变。

### 6.3 运算调度

拨码低三位提供 0 至 7 的运算编号。程序通过 CMP 和 JZ 依次判断：

```asm
CMP  R1, R2
JZ   OP_ADD
...
CMP  R1, R2
JZ   OP_MUL
...
JUMP OP_CMP
```

八种运算如下：

| 编号 | 运算 | 实现方式 |
|---:|---|---|
| 0 | ADD | ALU 加法 |
| 1 | SUB | ALU 减法 |
| 2 | AND | ALU 按位与 |
| 3 | OR | ALU 按位或 |
| 4 | XOR | ALU 按位异或 |
| 5 | MUL | 软件重复加法 |
| 6 | DIV | 软件比较和重复减法 |
| 7 | CMP | ALU 比较并读取 Flags |

### 6.4 加法代码

```asm
OP_ADD:
    INP  R0, 0x40
    INP  R1, 0x41
    ADDR R0, R1
    JUMP ARITH_FINISH

ARITH_FINISH:
    OUP  0x44, R0
    INP  R2, 0x32
    INP  R3, 0x42
    OR   R2, R3
    OUP  0x30, R2
```

程序从 `0x40`、`0x41` 读出 A、B，使用 ALU 完成加法，再把结果保存到 `0x44`。随后读取 `0x32` 的 Flags，与运算编号组合后写入 LED。

### 6.5 软件乘法

```asm
OP_MUL:
    INP  R2, 0x40       ; R2 = A
    INP  R1, 0x41       ; R1 = B
    MOVI R0, 0x00       ; R0 = result
    MOVI R3, 0x00
    CMP  R1, R3
    JZ   MUL_DONE

MUL_LOOP:
    ADDR R0, R2         ; result += A
    MOVI R3, 0x01
    SUB  R1, R3         ; B--
    JZ   MUL_DONE
    JUMP MUL_LOOP
```

CPU 没有乘法器和 MUL 指令。程序通过重复加法完成无符号乘法。例如 `12 × 0A` 会把 `0x12` 累加 10 次。

这体现了软核 CPU 的一个重要特点：硬件指令集可以保持精简，更复杂的运算由软件循环实现。代价是执行周期数明显多于单条 ALU 指令。

### 6.6 软件除法

除法先判断除数是否为零：

```asm
MOVI R2, 0x00
CMP  R1, R2
JZ   DIV_ZERO
```

正常除法使用重复减法：

```asm
DIV_LOOP:
    CMP  R0, R1
    ...                 ; 根据比较 Flags 判断是否还能继续减
    SUB  R0, R1
    ADDI R2, 0x01       ; quotient++
    JUMP DIV_LOOP
```

循环结束后：

- R2 或 Scratchpad 中保存商
- R0 保存余数
- 显示格式为 `AABBqqrr`

如果除数为零，程序进入 `DIV_ZERO`，显示 `E001AABB`，并把 LED7 置 1 表示错误。

### 6.7 比较运算

CMP 运算返回：

- A < B：结果 0
- A = B：结果 1
- A > B：结果 2

程序先执行硬件 CMP，然后读取 Flags 端口，根据 Z 和无符号关系判断三种情况。

### 6.8 显示格式

普通结果使用：

```text
AABBrrrr
```

其中 A、B 各占两个十六进制位，结果占四个十六进制位。

例如：

```text
A = 2D
B = 17
运算 = ADD
结果 = 0044
显示 = 2D170044
```

除法使用：

```text
AABBqqrr
```

`qq` 为商，`rr` 为余数。

---

## 7. 输入、复位与结果保持

### 7.1 输入同步

拨码和按键来自 CPU 时钟域之外。外部输入如果直接进入同步逻辑，可能在采样边沿附近违反建立或保持时间。因此拨码输入经过同步处理后再提供给 CPU。

输入同步只能降低亚稳态传播风险，不能自动完成机械按键去抖。S1 使用独立控制器实现去抖、确认令牌和长按复位。

### 7.2 结果保持

计算完成后，程序进入等待状态。没有新的确认事件时，显示寄存器和 LED 寄存器不会被重新写入。因此用户改变拨码，结果仍保持不变。

这个现象说明输出来自寄存器锁存，而不是拨码到数码管之间的直接组合连接。

### 7.3 复位

长按 S1 后，系统清除 CPU 和外设状态，返回 A 输入界面。复位期间应阻止无效 I/O 写入，避免 LED 或显示寄存器进入不可预测状态。

---

## 8. 验证方法与结果

### 8.1 验证层次

项目采用多层验证：

1. 汇编与参考模型：确认机器码生成和程序算法。
2. 模块级 RTL testbench：检查 ALU、Controller、Datapath、GPIO 和按键等模块。
3. 系统级 RTL testbench：检查 CPU、ROM、Scratchpad 和外设协同工作。
4. 综合与实现：检查资源使用、时序和布线。
5. Bitstream：确认设计可以生成可下载文件。

### 8.2 计算器结果

- 汇编程序占用 240 个有效指令字，保留 16 个位置。
- 独立指令参考模型 15/15 通过。
- Vivado XSim RTL 回归 9/9 通过。
- 系统 testbench 覆盖八种运算、结果保持、重新开始和复位。
- 目标频率 100 MHz。
- WNS 为 `+0.559 ns`，TNS 为 `0.000 ns`。
- 资源使用为 444 Slice LUT、494 Slice Register、42 IOB 和 1 BUFG。
- 路由无失败网络和未布通网络。

### 8.3 流水灯结果

- 指令模型得到完整的 `01→02→04→08→10→20→40→80→01` 序列。
- 综合、布局布线和 bitstream 生成完成。
- 100 MHz 下 WNS 为 `+0.683 ns`，TNS 为 `0.000 ns`。
- 资源使用为 239 LUT、176 Register、42 IOB 和 1 BUFG。
- 已修复 `0x80` 回卷时可能产生 `0x00` 的边界问题。

### 8.4 当前非 HDMI Runtime 验证结果

2026-11-04 按当前结构和 ISA 重新建立波形证据，旧 8 位 PC 工程的波形不再用来证明当前版本：

- Vivado 2026.1 原生 XSim：`tb_runtime_running_light_wave`、`tb_runtime_extended_isa_wave`，2/2 `TEST PASS`。
- Running Light 测试结束于 7576 ns，实际观察到 `OUP 0x30 = 0x0001`，随后 `OUP 0x30 = 0x0002`。
- 扩展 ISA 测试结束于 166 ns，覆盖 `CMP → JZ`、页内 `JUMP`、跨页 `JMPA`，以及 `STR [0x22]=0x005A`、`LDR R2=[0x22]`。
- 两项测试均经过 `xvlog → xelab → xsim`，并生成非空 WDB、VCD、WCFG 和仿真日志。
- 五张最终图全部使用原生 XSim VCD，标题与图内说明均为英文，图形采用 Vivado Wave 风格但不是伪装成 GUI 截图。
- 当前实现证据：WNS `+0.157 ns`、TNS `0`、WHS `+0.049 ns`、THS `0`；0 条未布通网络、DRC 0 Error；1204 LUT、750 FF、44 IOB。

五张图的讲解顺序：

1. `01_single_cycle_commit`：复位释放、取指和时钟沿提交。
2. `02_cmp_jz_jump_jmpa`：条件、页内与跨页跳转。
3. `03_registers_alu_writeback`：寄存器、ALU 和写回路径。
4. `04_runtime_io_led`：当前 Running Light 的 LED `0x01 → 0x02`。
5. `05_ldr_str_data_memory`：当前扩展 ISA 的数据 RAM 读写。

### 8.5 如何讲解波形

推荐按照下面的顺序读波形：

1. 观察 `pc` 或 `mem_addr`，确定当前指令地址。
2. 观察 `instruction` 和 `opcode`，确定执行的指令。
3. 观察 `rd_data`、`rs_data` 和 `alu_result`，说明运算过程。
4. 观察 `io_re/io_we`，判断是否访问外设。
5. 观察 `io_addr` 和 `io_wdata/io_rdata`，确认访问哪个端口以及传输什么数据。
6. 观察 LED、显示寄存器或写回数据，确认状态在时钟沿之后更新。

对于 I/O 波形，可以重点指出：

- `INP` 指令使 `io_re=1`，外设数据进入写回路径。
- `OUP` 指令使 `io_we=1`，`R[Rs]` 通过 `io_wdata` 写入指定端口。
- `io_addr=0x30` 对应 LED，`io_addr=0x31` 对应拨码输入。

---

## 9. 项目发展讲解顺序

### 第 1 部分：开场

建议用时 20 秒。

讲法：

> 我们在 Zynq-7020 的 FPGA 逻辑中实现了一个 16 位单周期软核 CPU，并从基础指令验证逐步发展到可以通过 UART 更换程序的 Runtime。当前展示对象是最新非 HDMI 终端版，支持 Snake、2048 和 Running Light。

### 第 2 部分：项目演进分支图

建议用时 50 秒。

沿 `PROJECT_BRANCH_MAP.md` 的主干讲四个阶段：

1. 原始 8 位 PC 单周期 CPU。
2. 模块化、ZNVC 和 EES331 板级公共层。
3. 流水灯、计算器与 Snake 等应用分支。
4. 当前 10 位 PC Runtime、UART Loader 和多程序 Arcade。

明确 HDMI 是从 Runtime 历史快照分出的显示扩展，当前波形验证对象是非 HDMI 终端版。

### 第 3 部分：当前 Runtime 系统架构

建议用时 70 秒。

按照从上到下顺序讲：`runtime_board_top`、可写程序 RAM、Loader、CPU、数据 RAM 和外设子系统。

重点区分两种存储：`data_memory` 由 `LDR/STR` 访问；`scratchpad16` 位于 I/O 地址空间，由 `INP/OUP` 访问。

### 第 4 部分：单周期数据通路

建议用时 80 秒。

先讲取指、译码、读寄存器、执行和提交，再强调这些步骤位于一个时钟周期内。结合图 01 和图 03 说明 PC、指令、ALU 和写回数据如何在相邻时钟沿之间变化。

### 第 5 部分：ISA 与存储演进

建议用时 70 秒。

用版本对比解释为什么旧波形不能继续代表当前设计：

1. 基础版：8 位 PC，`D/E/F` 保留。
2. Snake V1：加入 `LDR/STR` 和 256×16 数据 RAM。
3. 当前 Runtime：10 位 PC、1K×16 程序 RAM、`JMPA` 跨页跳转。

结合图 02 和图 05 展示 `JZ/JUMP/JMPA` 与 `STR/LDR` 的实际波形证据。

### 第 6 部分：程序与终端应用

建议用时 70 秒。

用三个程序说明 Loader 的意义：Snake 展示数据结构和实时交互，2048 展示更复杂的算法与状态，Running Light 展示最直观的板载 LED I/O。补充计算器是早期独立应用分支，不是当前 Runtime 的父程序。

### 第 7 部分：当前 Vivado/XSim 波形

建议用时 80 秒。

按 01 到 05 的顺序讲，不逐个信号朗读。图 04 必须指出 `PC/instruction/io_we/io_addr/io_wdata/board_led` 的因果关系，以及 `OUP 0x30` 使 LED 从 `0x01` 变为 `0x02`。说明五张英文图的数据来自原生 XSim VCD。

### 第 8 部分：实现结果与结论

建议用时 60 秒。

先说明当前聚焦测试原生 XSim 2/2 PASS，再给出 WNS、资源、布线和 DRC 结果。最后收束：项目从能执行基础指令的单周期 CPU，发展为具有数据 RAM、可写程序存储器、Loader、多程序终端和可重复验证证据的小型可编程系统。

---

## 10. 常见答辩问题

### 为什么叫单周期 CPU？

因为一条普通指令从取指到写回的组合逻辑位于两个相邻时钟沿之间，并在下一个上升沿提交状态。它不是五级流水线，也不是把每个步骤分配到不同周期的多周期 CPU。

### 为什么流水灯不用移位指令？

当前 ISA 没有专门移位指令。对于单比特模式，寄存器与自身相加等于乘 2，可以达到左移一位的效果。

### 为什么乘法和除法不用硬件乘除器？

项目希望验证 CPU 可以通过程序组合基础指令完成复杂运算。重复加法和重复减法虽然速度较慢，但减少了专用硬件，并展示了分支与循环能力。

### 单周期是不是所有指令耗时完全一样？

从 CPU 时钟周期数量看，普通硬件指令均为一个周期。软件乘法和除法由多条单周期指令组成，因此整个算法需要多个周期。

### 计算器为什么需要 Scratchpad？

CPU 只有四个通用寄存器，无法同时长期保存全部交互状态和中间结果。Scratchpad 提供 16 个 16 位位置，并通过 I/O 地址访问。

### 如何证明结果不是拨码直接连到显示？

输入确认后，A 和 B 被写入 Scratchpad。计算结果写入显示寄存器。进入结果状态后即使改变拨码，显示仍保持不变，这说明输出由程序和寄存器控制。

### JZ 使用哪个比较结果？

JZ 读取状态寄存器中此前由 CMP 或算术指令保存的 Z 标志，而不是在 JZ 周期重新比较。

### 如果把 ROM 换成同步 BRAM 会怎样？

同步 BRAM 通常在下一个时钟沿后才输出数据，当前组合取指的单周期结构无法直接适配，需要增加取指周期、状态机或流水级。

### 为什么不能继续使用早期流水灯波形证明当前版本？

早期版本是 8 位 PC、256×16 程序 ROM，而且 opcode `D/E/F` 的含义与当前 Runtime 不同。当前版本具有 10 位 PC、1K×16 可写程序 RAM、数据 RAM 和 `LDR/STR/JMPA`。波形必须来自相同结构和 ISA，才能作为当前版本证据。

### 这五张波形是 Vivado/XSim 的结果吗？

是。两项 testbench 都通过 Vivado 2026.1 的 `xvlog → xelab → xsim`，日志中有明确 `TEST PASS`，并生成 WDB、VCD 和 WCFG。五张图从原生 XSim VCD 读取数据，再按统一 Vivado Wave 风格排版；它们不是用其他仿真器生成的数据，也不是 Vivado GUI 的直接截图。

### 当前版本与 HDMI 版是什么关系？

HDMI 版从 Runtime 的历史快照分出，在视频时序、帧桥和 ADV7511/I²C 方向继续发展。当前答辩主版本是非 HDMI 终端 Runtime，两个目录独立维护，不能把 HDMI 分支的验证结果直接算作当前终端版结果。

### 当前验证还缺什么？

当前结构的原生 XSim 聚焦波形、历史综合实现和 bitstream 证据均已具备。需要区分的是：现有实现、资源和 bitstream 数据属于已验证构建；通过 Loader 上传的新程序无需重做 bitstream，但若要求重新配置 FPGA 后默认进入最新 16×8 Snake，则仍需重新生成并上板验收新的 bitstream。

---

## 11. 建议准备的展示素材

如果答辩前有时间，建议补充：

1. 一张 Runtime 连接开发板和串口终端的全景，屏幕显示 Snake 或 2048。
2. 一张 Running Light 实拍，拍清八个 LED；图 04 已经提供 `0x01 → 0x02` 的内部波形证据。
3. 可选保留计算器 `2D170044` 实拍，用于说明早期应用分支。

实拍用于增强可见效果，分支图、五张 XSim 波形和实现报告承担结构、因果和可重复验证的证明作用。

---

## 12. 主要依据文件

- `MiniRISC-16-CPU/docs/design/CPU项目说明_8位GPIO_单周期.md`
- `MiniRISC-16-CPU/docs/design/RTL_STRUCTURE_ANALYSIS.md`
- `MiniRISC-16-CPU/docs/design/CONTROL_TABLE.md`
- `MiniRISC-16-CPU/refactored_design/BOARD_LED_CHASER_GUIDE.md`
- `MiniRISC-16-CPU/refactored_design/sim/programs/board_led_chaser.mem`
- `MiniRISC-16-CPU/refactored_design/calculator_system/README.md`
- `MiniRISC-16-CPU/refactored_design/calculator_system/BOARD_TEST_GUIDE.md`
- `MiniRISC-16-CPU/refactored_design/calculator_system/program/calculator.asm`
- `MiniRISC-16-CPU/refactored_design/calculator_system/rtl/top/calculator_soc.v`
- `MiniRISC-16-CPU/refactored_design/calculator_system/rtl/peripherals/io_decoder.v`
- `MiniRISC-16-CPU/refactored_design/calculator_system/rtl/peripherals/peripheral_subsystem.v`
- `PROJECT_BRANCH_MAP.md`
- `MiniRISC-16-CPU/refactored_design/runtime_system/README.md`
- `MiniRISC-16-CPU/refactored_design/runtime_system/reports/verification-summary.txt`
- `MiniRISC-16-CPU/refactored_design/runtime_system/reports/waveforms/current_terminal/README.md`
- `MiniRISC-16-CPU/refactored_design/runtime_system/reports/waveforms/current_terminal/vivado-xsim-run.log`
- `MiniRISC-16-CPU/refactored_design/runtime_system/reports/waveforms/current_terminal/final_vivado_style/`

