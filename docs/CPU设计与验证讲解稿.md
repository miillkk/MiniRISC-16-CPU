# MiniRISC-16 CPU 设计与验证讲解稿

本文档用于把项目设计和仿真验证结果整理成可讲解内容，可直接转换为答辩 PPT、报告讲稿或课堂演示说明。详细接口和控制信号以 `docs/design/CPU项目说明_8位GPIO_单周期.md`、`docs/design/CONTROL_TABLE.md` 和 `docs/verification/VERIFICATION.md` 为准。

## 1. 项目目标

本项目实现一个 MiniRISC-16 单周期 CPU，并集成 8 位 GPIO 外设。CPU 数据宽度为 16 位，包含 4 个通用寄存器 R0～R3，PC 为 8 位，因此指令地址空间为 256 条 16 位指令。

本阶段目标不是上板，而是完成 RTL 设计和功能仿真验证。最终交付内容包括 Verilog 源码、testbench、机器码测试程序、Vivado XSim 回归脚本、仿真日志、VCD/WCFG 原始波形、波形图片和 Vivado GUI 截图。

讲解时可以先强调三点：

1. CPU 是非流水线单周期结构，每个时钟上升沿提交一条指令。
2. 指令存储器采用组合读 ROM，不加入取指等待或握手。
3. GPIO 通过独立 I/O 接口访问，顶层才把内部输入、输出和方向信号组合成三态 `gpio[7:0]`。

## 2. 总体架构

工程主要分为三个层次：

| 层次 | 主要文件 | 作用 |
|---|---|---|
| CPU 核心 | `rtl/core/*.v` | 控制器、ALU、寄存器组、数据通路和 `cpu_core` |
| 外设与平台 | `rtl/peripherals/*.v` | 指令 ROM、GPIO、复位处理 |
| 顶层系统 | `rtl/top/system_top.v` | 连接 CPU、ROM、GPIO 和外部端口 |

系统顶层只有三个板级端口：

```verilog
input        clk
input        resetn
inout  [7:0] gpio
```

内部复位采用“外部低有效异步拉低、内部同步释放”的方式。`reset_conditioner` 把 `resetn` 转换成同步高有效 `rst`，CPU 和 GPIO 内部状态都在 `rst=1` 时清零。

## 3. 指令格式与控制

16 位指令字段如下：

| 位段 | 含义 |
|---|---|
| `[15:12]` | opcode |
| `[11:10]` | Rd |
| `[9:8]` | Rs |
| `[7:0]` | imm8 |

当前实现支持 13 个有效 opcode，另外 `D/E/F` 为安全保留操作。安全保留操作不会写寄存器、不会写 Z、不会访问 I/O，只让 PC 顺序加一。

| opcode | 指令 | 功能摘要 |
|---|---|---|
| `0` | MOVI | Rd = zero_extend(imm8) |
| `1` | MOVR | Rd = Rs |
| `2` | ADDI | Rd = Rd + zero_extend(imm8) |
| `3` | ADDR | Rd = Rd + Rs |
| `4` | XOR | Rd = Rd xor Rs |
| `5` | SUB | Rd = Rd - Rs |
| `6` | CMP | Z = (Rd - Rs == 0)，不写 Rd |
| `7` | AND | Rd = Rd and Rs |
| `8` | JZ | 如果 Z=1，PC = imm8 |
| `9` | OR | Rd = Rd or Rs |
| `A` | JUMP | PC = imm8 |
| `B` | INP | Rd = io_rdata |
| `C` | OUP | io_wdata = Rs，并写 I/O |
| `D/E/F` | Reserved | 安全空操作 |

讲解控制器时重点说明：`controller` 是纯组合逻辑，对所有控制信号先给安全默认值，再根据 opcode 覆盖。这样可以避免隐式锁存，也可以保证保留 opcode 不产生危险副作用。

## 4. 单周期执行通路

一条指令在一个时钟周期内完成以下组合路径：

```text
PC -> instruction_memory -> controller
                         -> register_file read
                         -> ALU / GPIO read
                         -> writeback mux
                         -> PC next logic
```

在当前时钟周期内，PC 组合读出指令；控制器解码得到 ALU 操作、寄存器写使能、I/O 读写使能、分支跳转控制；寄存器组组合读出 Rd 和 Rs；ALU 或 I/O 读数据形成写回值；下一 PC 同时由顺序加一、JZ 或 JUMP 决定。

到下一个时钟上升沿时，当前指令的所有副作用同时提交：

- PC 更新为 `pc_next`
- 若 `reg_write=1`，写回 Rd
- 若 `z_write=1`，更新 Z 标志
- 若 `io_we=1`，GPIO 接收写操作

这里特别要说明 Z 标志：只有 CMP 指令更新 Z，JZ 使用的是此前 CMP 保存下来的 Z，而不是当前 ALU 临时结果。这是验证分支行为时的关键点。

## 5. GPIO 设计

GPIO 外设使用三个内部寄存器或同步信号：

| 地址 | 名称 | 读写 | 说明 |
|---|---|---|---|
| `0x10` | GPIO_OUT | 读写 | 输出数据寄存器 |
| `0x11` | GPIO_IN | 只读 | 两级同步后的输入 |
| `0x12` | GPIO_DIR | 读写 | 方向控制，1 为输出，0 为输入 |

写 GPIO 时只使用 `io_wdata[7:0]`，读 GPIO 时高 8 位补零。未映射地址读零，写入无副作用。顶层 `system_top` 根据 `gpio_oe/gpio_dir` 逐位控制三态：

```text
gpio_oe = 1 -> 对外驱动 gpio_o
gpio_oe = 0 -> 该位为高阻输入
```

GPIO 输入经过两级同步器后才成为 `GPIO_IN`，这样可以降低异步输入直接进入同步逻辑带来的亚稳态风险。

## 6. 关键模块说明

| 模块 | 文件 | 讲解重点 |
|---|---|---|
| `alu` | `rtl/core/alu.v` | PASS_B、ADD、SUB、AND、OR、XOR 六种运算，16 位自然截断 |
| `controller` | `rtl/core/controller.v` | opcode 解码、控制信号默认安全值、保留指令处理 |
| `register_file` | `rtl/core/register_file.v` | 4 个 16 位寄存器，组合读、同步写，R0 也可写 |
| `datapath` | `rtl/core/datapath.v` | PC、Z、寄存器读写、ALU、写回选择和下一 PC |
| `cpu_core` | `rtl/core/cpu_core.v` | CPU 对外只暴露指令接口和 I/O 接口 |
| `instruction_memory` | `rtl/peripherals/instruction_memory.v` | 256×16 ROM，组合读，`$readmemh` 加载机器码 |
| `gpio8` | `rtl/peripherals/gpio8.v` | OUT/IN/DIR 地址映射、三态前的内部 GPIO 逻辑 |
| `reset_conditioner` | `rtl/peripherals/reset_conditioner.v` | 复位异步拉低、两级同步释放 |
| `system_top` | `rtl/top/system_top.v` | 连接 CPU、ROM、GPIO，并形成顶层 `inout gpio[7:0]` |

## 7. 验证总体划分

本项目的验证建议分成两部分讲：先做人工验证，再做 EDA 验证。人工验证证明“设计规格、指令真值表和测试程序本身是对的”；EDA 验证证明“RTL 在仿真器中按这个规格实际跑通”。

| 验证类别 | 作用 | 主要证据 |
|---|---|---|
| 人工验证，也可称静态规格核对 | 不运行仿真，逐项检查设计是否和项目 md 一致 | 接口表、opcode 控制真值表、GPIO 地址表、模块调用关系、测试程序机器码注释 |
| EDA 验证，也可称动态仿真验证 | 使用 Vivado/XSim 运行 RTL 和 testbench | 六个自检 testbench PASS、VCD/WCFG、Vivado 波形截图、最终状态对比 |

### 7.1 人工验证：规格和真值表核对

人工验证部分最适合用真值表来讲。这里检查的不是“波形像不像”，而是先确认设计输入是完整且自洽的：

| 人工核对项 | 核对方法 | 结论 |
|---|---|---|
| 指令格式 | 对照设计 md，确认 `[15:12] opcode`、`[11:10] Rd`、`[9:8] Rs`、`[7:0] imm8/addr` | RTL 字段提取与文档一致 |
| 控制真值表 | 用 `docs/design/CONTROL_TABLE.md` 逐 opcode 列出 `reg_we`、`z_we`、`alu_src`、`alu_op`、`wb_sel`、`io_re/io_we`、PC 选择 | 13 个有效 opcode 和 3 个保留 opcode 均有定义 |
| 保留指令 | 核对 `1101～1111` 是否不写寄存器、不写 Z、不访问 I/O | 保留 opcode 为安全 NOP，只让 PC 顺序递增 |
| GPIO 地址 | 核对 `0x10 OUT`、`0x11 IN`、`0x12 DIR` 的读写权限和高 8 位补零 | RTL 地址映射与 md 一致 |
| 复位与时序 | 核对 PC、寄存器、Z、GPIO_OUT、GPIO_DIR、输入同步器的复位值，以及单周期提交规则 | 所有状态只在时钟上升沿更新，复位后状态确定 |
| 测试程序 | 手工解码 `sim/programs/system_demo.mem` 的机器码和注释 | 程序覆盖 MOV、ALU、CMP、JZ、JUMP、INP、OUP 和保留 opcode |

因此，人工验证的结论是：控制真值表、地址表、模块接口和测试程序期望值已经先被静态核对，后面的 EDA 仿真是在这个明确规格上做动态验证。

答辩或报告中可以直接放下面这张人工验证真值表。表中 `alu_src=0` 表示 ALU B 操作数来自 `R[Rs]`，`alu_src=1` 表示来自零扩展 `imm8`；`wb_sel=0` 表示写回 ALU 结果，`wb_sel=1` 表示写回 `io_rdata`。

| opcode | 指令 | alu_op | alu_src | reg_write | z_write | branch_z | jump | wb_sel | io_re | io_we | PC 更新 | 状态副作用 |
|---:|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---|
| `0` | `MOVI Rd,#imm8` | PASS_B | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | `PC+1` | `Rd <= {8'h00,imm8}` |
| `1` | `MOVR Rd,Rs` | PASS_B | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | `PC+1` | `Rd <= R[Rs]` |
| `2` | `ADDI Rd,#imm8` | ADD | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | `PC+1` | `Rd <= Rd + imm8` |
| `3` | `ADDR Rd,Rs` | ADD | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | `PC+1` | `Rd <= Rd + R[Rs]` |
| `4` | `XOR Rd,Rs` | XOR | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | `PC+1` | `Rd <= Rd ^ R[Rs]` |
| `5` | `SUB Rd,Rs` | SUB | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | `PC+1` | `Rd <= Rd - R[Rs]` |
| `6` | `CMP Rd,Rs` | SUB | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | `PC+1` | `Z <= (Rd - R[Rs] == 0)` |
| `7` | `AND Rd,Rs` | AND | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | `PC+1` | `Rd <= Rd & R[Rs]` |
| `8` | `JZ #imm8` | PASS_B | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | `Z ? imm8 : PC+1` | 无寄存器/I/O 写入 |
| `9` | `OR Rd,Rs` | OR | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | `PC+1` | `Rd <= Rd \| R[Rs]` |
| `A` | `JUMP #imm8` | PASS_B | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | `imm8` | 无寄存器/I/O 写入 |
| `B` | `INP Rd,port` | PASS_B | 0 | 1 | 0 | 0 | 0 | 1 | 1 | 0 | `PC+1` | `Rd <= io_rdata` |
| `C` | `OUP port,Rs` | PASS_B | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | `PC+1` | `io_wdata <= R[Rs]`，GPIO 按地址写 OUT/DIR |
| `D` | 保留 | PASS_B | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | `PC+1` | 安全 NOP |
| `E` | 保留 | PASS_B | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | `PC+1` | 安全 NOP |
| `F` | 保留 | PASS_B | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | `PC+1` | 安全 NOP |

### 7.2 EDA 验证：XSim 和波形

EDA 验证采用“模块级 + 系统级”的方式。每个 testbench 都是自检型：只要检测到错误就增加 `errors`，最后只有错误数为 0 才打印 `TEST PASS`。

| testbench | 覆盖内容 |
|---|---|
| `tb_alu` | 六种 ALU 功能、零值、加法回绕、减法下溢和逻辑边界 |
| `tb_controller` | 13 个有效 opcode、3 个保留 opcode、字段提取和全部控制信号 |
| `tb_datapath` | 寄存器读写、CMP/Z、JZ/JUMP、PC 回绕 |
| `tb_reset_conditioner` | 异步拉低、两级同步释放 |
| `tb_gpio8` | OUT/IN/DIR、未映射访问、高阻态、输入同步 |
| `tb_system` | 运行端到端程序，逐周期参考模型比较，覆盖全部 opcode |

系统级测试程序在 `sim/programs/system_demo.mem` 中。该程序覆盖所有 opcode，包括保留 opcode；同时覆盖 JZ 跳转成功、JZ 不跳转、JUMP、自循环终点、GPIO 输入和输出。

## 8. EDA 验证 PASS 条件

系统级仿真的 PASS 条件不是只看波形像不像，而是 testbench 自动检查以下条件：

| 判定项 | 期望值 | 含义 |
|---|---|---|
| `errors` | `0` | 自检没有发现错误 |
| `completed` | `1` | 程序跑到预期终点 |
| `opcode_coverage` | `ffff` | 16 个 opcode 全部覆盖 |
| `jz_taken_count` | `2` | JZ 成功跳转 2 次 |
| `jz_not_taken_count` | `1` | JZ 未跳转 1 次 |
| `PC` | `0x21` | 程序停在最终自循环 |
| `instruction` | `0xA021` | 最终指令为 `JUMP 0x21` |
| `Z` | `1` | 最终比较结果为相等 |
| `R0～R3` | `0x00A5` | 四个寄存器终态正确 |
| `GPIO_OUT` | `0xA5` | GPIO 输出数据正确 |
| `GPIO_DIR` | `0x0F` | GPIO 低 4 位输出、高 4 位输入 |
| `GPIO_IN` | `0xA5` | 同步输入结果正确 |

最终日志中 `tb_system` 输出：

```text
tb_system: TEST PASS cycles=32 opcode_coverage=ffff JZ_taken=2 JZ_not_taken=1
```

完整回归汇总为：

```text
tb_alu : PASS
tb_controller : PASS
tb_datapath : PASS
tb_reset_conditioner : PASS
tb_gpio8 : PASS
tb_system : PASS
waveform-render : PASS
Failures: 0
```

## 9. EDA 波形图怎么讲

交付的波形分为三类：

| 文件 | 用途 |
|---|---|
| `reports/waveforms/system.vcd` | 通用原始波形，可被其他工具打开 |
| `reports/waveforms/system.wcfg` | Vivado 原始波形配置 |
| `reports/waveforms/01_*.png`～`04_*.png` | 从真实 VCD 渲染出的报告用波形图 |
| `reports/waveforms/vivado_pass_summary_full_screenshot.png` | Vivado GUI 中的 PASS 摘要截图 |
| `reports/waveforms/vivado_final_state_full_screenshot.png` | Vivado GUI 中的最终状态截图 |

讲 `vivado_pass_summary_full_screenshot.png` 时，可以说：

> 这张图用于证明系统级验证是否通过。黄色光标停在仿真结束位置，左侧 Value 栏显示 `errors=0`，说明没有自检错误；`completed=1`，说明程序到达终点；`opcode_coverage=ffff`，说明全部 opcode 都被执行覆盖；JZ taken 为 2，not-taken 为 1，说明条件跳转的两种情况都被验证。

讲 `vivado_final_state_full_screenshot.png` 时，可以说：

> 这张图用于证明最终状态正确。左侧 Value 栏显示 PC 为 `0x21`，Z 为 1，R0～R3 均为 `0x00A5`，GPIO_OUT 为 `0xA5`，GPIO_DIR 为 `0x0F`，GPIO_IN 为 `0xA5`。这些值与 testbench 的期望终态完全一致。

讲四张脚本渲染波形时，可以这样分工：

| 图片 | 讲解角度 |
|---|---|
| `01_single_cycle_commit.png` | 复位释放后，每个时钟周期 PC 和指令推进，写寄存器/I/O 写在周期边界提交 |
| `02_cmp_jz_jump.png` | CMP 更新 Z，JZ 根据已保存的 Z 决定是否跳转，JUMP 无条件改 PC |
| `03_registers_alu.png` | Rd/Rs 操作数、ALU 结果、写回数据和 R0～R3 变化 |
| `04_gpio_io.png` | I/O 地址、写数据、读数据、GPIO_OUT、GPIO_DIR、GPIO_IN 和物理引脚关系 |

## 10. 推荐 PPT 结构

可以按 8 页左右组织：

1. 项目目标：MiniRISC-16 单周期 CPU + 8 位 GPIO
2. 系统架构：CPU core、instruction memory、GPIO、reset、system top
3. 指令集与控制：指令格式、opcode、关键控制信号
4. 单周期数据通路：取指、译码、读寄存器、ALU/I/O、写回、PC 更新
5. GPIO 外设：地址映射、方向控制、三态输出、输入同步
6. 人工验证：接口表、控制真值表、GPIO 地址表、测试程序机器码核对
7. EDA 验证：模块级 testbench、系统级参考模型、Vivado/XSim PASS
8. 波形证明：PASS 摘要图、最终状态图和四组功能波形

## 11. 可直接使用的讲解词

下面是一段可以直接用于答辩的讲解：

> 本项目实现了一个 16 位 MiniRISC 单周期 CPU。CPU 内部包含 4 个通用寄存器、8 位 PC、组合控制器、ALU 和 Z 标志位。系统采用独立的指令 ROM 和独立的 I/O 接口，外设部分实现了一个 8 位 GPIO。GPIO 通过地址 `0x10`、`0x11`、`0x12` 分别访问 OUT、IN 和 DIR，其中 DIR 控制每一位是输入还是输出。
>
> CPU 的执行方式是单周期非流水线。当前 PC 组合读出指令，控制器根据 opcode 生成控制信号，寄存器组组合读出操作数，ALU 或 GPIO 读数据产生写回值。到时钟上升沿时，PC、寄存器、Z 标志和 GPIO 写操作同时提交。因此每个非复位时钟周期执行一条指令。
>
> 验证方面分为两部分。第一部分是人工验证，也就是根据设计 md 手工核对接口、指令字段、opcode 控制真值表、GPIO 地址表和测试程序机器码，确认规格本身完整一致。第二部分是 EDA 验证，我实现了 ALU、控制器、数据通路、复位、GPIO 和系统级六个 testbench。系统级 testbench 运行 `system_demo.mem`，覆盖所有 opcode，同时覆盖 JZ 跳转成功和失败、JUMP、GPIO 输入输出以及保留指令。testbench 内部有逐周期参考模型，在每个周期比较 PC、Z、寄存器和 GPIO 状态。
>
> 最终 Vivado XSim 回归结果显示六个 testbench 全部 PASS，波形渲染也 PASS，总错误数为 0。系统级终态为 PC=`0x21`，Z=`1`，R0～R3 均为 `0x00A5`，GPIO_OUT=`0xA5`，GPIO_DIR=`0x0F`，GPIO_IN=`0xA5`。波形截图中也可以看到 `errors=0`、`completed=1`、`opcode_coverage=ffff`，因此设计功能验证通过。

## 12. 常见答辩问题

**为什么说它是单周期 CPU？**

因为没有指令寄存器、执行 FSM、流水级或 RAM 等待状态。每条指令在一个时钟周期内完成组合计算，并在下一个上升沿提交所有状态变化。

**JZ 为什么不是直接看当前 ALU zero？**

设计要求 JZ 使用此前 CMP 保存的 Z 标志。只有 CMP 更新 Z，因此 JZ 的行为与前一次比较结果绑定，更接近一个简单状态标志架构。

**保留 opcode 怎么处理？**

`D/E/F` 被设计成安全空操作：不写寄存器、不更新 Z、不访问 I/O，只让 PC 顺序递增。这样即使 ROM 中出现未定义指令，也不会破坏状态。

**GPIO 为什么要两级同步？**

外部 GPIO 输入相对 CPU 时钟可能是异步的。两级同步器可以降低亚稳态传播到内部逻辑的风险，是 FPGA 输入同步的常见处理方式。

**怎么证明不是只跑了局部功能？**

人工验证先用控制真值表和机器码注释确认规格完整；EDA 验证再用模块级 testbench 覆盖 ALU、controller、datapath、reset 和 GPIO，并用系统级 testbench 运行完整程序，覆盖全部 opcode，逐周期比较参考模型。最终 `opcode_coverage=ffff` 和 `errors=0` 共同证明覆盖和结果都达标。

**为什么没有上板结果？**

本阶段范围是 RTL 设计与功能仿真，不包括 XDC、时序收敛、bitstream、ILA 和板级验证。上板还需要器件型号、时钟频率、I/O 电压和管脚分配等板级信息。
