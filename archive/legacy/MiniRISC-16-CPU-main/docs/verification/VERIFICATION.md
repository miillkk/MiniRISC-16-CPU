# MiniRISC-16 验证记录

## 结论摘要

截至 2026-09-12，MiniRISC-16 单周期 CPU 与 8 位 GPIO 设计已完成两部分验证：第一部分为人工验证，即规格、接口、控制真值表、GPIO 地址表和测试程序机器码核对；第二部分为 EDA 验证，即在 Vivado Simulator 2026.1 下进行动态功能仿真。六个 testbench 均通过 `xvlog` 编译、`xelab` 展开和 `xsim` 自检执行，系统级仿真生成真实 VCD/WCFG，并由 VCD 渲染出四组 SVG/PNG 波形图。`system.wcfg` 和 PASS 判定波形配置已在 Vivado GUI 中打开并截图保存。最终回归汇总为 `Failures: 0`。

本机 Vivado Basic license 包含有效的 `Vivado_Simulation` feature。此前命令行失败的原因是当前 shell 没有设置 `XILINXD_LICENSE_FILE`，而 license 实际位于 `C:\Users\xieke\AppData\Roaming\XilinxLicense\Xilinx.lic`。`run_all.ps1` 已加入常见 license 路径自动发现，当前回归日志记录了该路径。

## 环境与命令

| 项目 | 实际值 |
|---|---|
| 操作系统 | Windows，本机 PowerShell |
| Vivado Simulator | 2026.1，SW Build 6511674 |
| License | Vivado Basic，含 `Vivado_Simulation`，版本上限 `2027.09` |
| License 路径 | `C:\Users\xieke\AppData\Roaming\XilinxLicense\Xilinx.lic` |
| RTL/testbench 时间单位 | `1ns/1ps` |
| 名义仿真时钟 | 10 ns 周期，仅用于功能仿真 |
| 回归入口 | `powershell -ExecutionPolicy Bypass -File .\sim\scripts\run_all.ps1` |

回归脚本支持可选 `-VivadoBin` 和 `-LicenseFile`。默认会从环境变量、PATH、常见 Vivado 安装目录以及常见 Xilinx license 目录中搜索，不硬编码本机安装盘符。

## 验证划分

| 部分 | 验证名称 | 验证对象 | 输出证据 |
|---|---|---|---|
| 1 | 人工验证 / 静态规格核对 | 设计 md、模块接口、opcode 控制真值表、GPIO 地址表、测试程序机器码和期望终态 | `docs/design/CONTROL_TABLE.md`、`docs/FILE_LAYOUT.md`、`sim/programs/README.md`、本报告的人工核对表 |
| 2 | EDA 验证 / 动态仿真和波形验证 | Verilog RTL、testbench、系统级参考模型、Vivado XSim 波形 | `reports/simulation/*.txt`、`regression-summary.txt`、`system.vcd`、`system.wcfg`、波形 PNG/SVG、Vivado GUI 截图 |

## 1. 人工验证：规格、接口和真值表核对

人工验证的目标是先确认“要实现什么”没有歧义。它不替代仿真，而是为后续 EDA 验证提供可追溯的规格依据。

| 人工核对项 | 依据 | 结论 |
|---|---|---|
| 设计优先级 | 用户要求和 `CPU项目说明_8位GPIO_单周期.md` | 以设计 md 为权威；与旧课件冲突时采用 md 定义 |
| 指令字段 | `docs/design/CONTROL_TABLE.md` | `opcode=instruction[15:12]`，`Rd=instruction[11:10]`，`Rs=instruction[9:8]`，`imm8/addr=instruction[7:0]` |
| opcode 控制真值表 | `docs/design/CONTROL_TABLE.md` 与 `rtl/core/controller.v` | 13 个有效 opcode 均有明确控制信号；`1101～1111` 为安全保留操作 |
| 单周期提交规则 | 设计 md、`rtl/core/datapath.v`、`rtl/core/cpu_core.v` | PC、寄存器、Z 和 GPIO 写操作均在非复位时钟上升沿提交 |
| GPIO 地址表 | 设计 md、`rtl/peripherals/gpio8.v` | `0x10` 为 OUT，`0x11` 为 IN，`0x12` 为 DIR；未映射地址读零、写无副作用 |
| 复位策略 | 设计 md、`rtl/peripherals/reset_conditioner.v` | 板级 `resetn` 异步拉低、两级同步释放；CPU/GPIO 内部使用同步高有效 `rst` |
| 模块边界和调用关系 | `docs/FILE_LAYOUT.md` | `system_top` 连接 reset、ROM、CPU core 和 GPIO；`cpu_core` 对外只暴露指令接口和 I/O 接口 |
| 系统测试程序 | `sim/programs/system_demo.mem` 与 `sim/programs/README.md` | 手工解码确认覆盖 MOV、ADD、XOR、SUB、AND、OR、CMP、JZ、JUMP、INP、OUP 和保留 opcode |
| 期望终态 | `sim/programs/README.md` 与 `tb_system` 参考模型 | PC=`0x21`、Z=`1`、R0～R3=`0x00A5`、GPIO_OUT=`0xA5`、GPIO_DIR=`0x0F`、GPIO_IN=`0xA5` |

人工验证结论：接口定义、控制真值表、GPIO 地址表、复位规则和测试程序期望值均已与设计 md 对齐，可作为 EDA 仿真的检查基准。

### 1.1 opcode 控制真值表

表中 `alu_src=0` 表示 ALU B 操作数来自 `R[Rs]`，`alu_src=1` 表示来自零扩展 `imm8`；`wb_sel=0` 表示写回 ALU 结果，`wb_sel=1` 表示写回 `io_rdata`；`PC+1` 表示按 8 位模 256 顺序递增。

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

## 2. EDA 验证：Vivado/XSim 仿真与波形

### 2.1 当前实测结果

| 测试 | xvlog | xelab | xsim/自检 | 当前说明 |
|---|---|---|---|---|
| `tb_alu` | PASS | PASS | PASS | 六种 ALU 功能、零值、回绕和下溢通过 |
| `tb_controller` | PASS | PASS | PASS | 13 个有效 opcode 与 3 个保留 opcode 通过 |
| `tb_datapath` | PASS | PASS | PASS | PC、寄存器、Z、JZ/JUMP 和回绕通过 |
| `tb_reset_conditioner` | PASS | PASS | PASS | 异步拉低、两级同步释放通过 |
| `tb_gpio8` | PASS | PASS | PASS | OUT/IN/DIR、未映射访问、高阻和同步输入通过 |
| `tb_system` | PASS | PASS | PASS | 端到端程序、参考模型和 opcode 覆盖通过 |

逐项输出保存在 `reports/simulation/tb_*.txt`，汇总保存在 `reports/simulation/regression-summary.txt`。脚本要求每个 testbench 输出唯一 `TEST PASS`，并额外检查 `TEST FAIL`、`ERROR tb_` 和超时类错误。

`tb_system` 的最终输出为 `tb_system: TEST PASS cycles=32 opcode_coverage=ffff JZ_taken=2 JZ_not_taken=1`。期望终态和实际终态一致：PC=`0x21`、Z=`1`、R0～R3=`0x00A5`、GPIO_OUT=`0xA5`、GPIO_DIR=`0x0F`、GPIO_IN=`0xA5`。

### 2.2 自检覆盖矩阵

以下检查均已在 XSim 动态执行中通过：

| 验证点 | ALU | Controller | Datapath | Reset | GPIO | System |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| 六种 ALU、加法回绕、减法下溢 | ✓ |  | ✓ |  |  | ✓ |
| 13 个有效 + 3 个保留 opcode |  | ✓ |  |  |  | ✓ |
| R0～R3 同步写/组合读 |  |  | ✓ |  |  | ✓ |
| CMP 不写 Rd、仅 CMP 更新 Z |  | ✓ | ✓ |  |  | ✓ |
| JZ 成功/失败、JUMP、PC 回绕 |  | ✓ | ✓ |  |  | ✓（回绕由 datapath） |
| 异步复位拉低、两级同步释放 |  |  |  | ✓ |  | ✓ |
| OUT/IN/DIR、非法地址、高阻、两级输入同步 |  |  |  |  | ✓ | ✓ |
| 逐周期参考模型比较 |  |  |  |  |  | ✓ |
| X/Z 检查和最大周期超时 |  |  | ✓ |  | ✓ | ✓ |

`tb_system` 在每个时钟下降沿根据当前机器码计算下一状态，在随后上升沿后延迟 1 ns 比较实际 PC、Z、R0～R3、GPIO_OUT 和 GPIO_DIR。程序终态应为 PC=`0x21`、Z=`1`、R0～R3=`0x00A5`、GPIO_OUT=`0xA5`、GPIO_DIR=`0x0F`、GPIO_IN=`0xA5`，opcode 覆盖位图应为 `0xFFFF`。

### 2.3 已生成的波形

`xsim_run.tcl` 限定采集 `tb_system` 层次并生成 `system.vcd` 和 `system.wcfg`。`render_waveforms.ps1` 只读取真实 VCD 中固定的 `trace_*` 信号，生成：

1. `01_single_cycle_commit.svg/png`：时钟、复位、PC、指令、寄存器写和 I/O 写。
2. `02_cmp_jz_jump.svg/png`：CMP、Z、JZ/JUMP 与下一 PC。
3. `03_registers_alu.svg/png`：寄存器操作数、ALU、写回和 R0～R3。
4. `04_gpio_io.svg/png`：I/O 总线、OUT/DIR/同步输入和物理管脚。

另有两张 Vivado 2026.1 GUI 真实界面截图：

- `vivado_wave_gui_screenshot.png`：打开 `tb_system_sim.wdb` 与 `system.wcfg` 后的完整波形窗口。
- `vivado_pass_check_screenshot.png`：打开 `system_pass_check.wcfg` 后的验收判定截图，直接显示 `errors=0`、`completed=1`、`opcode_coverage=ffff`、JZ 计数和最终 PC/寄存器/GPIO 状态。

为避免报告截图被窗口高度截断，额外提供两张一屏完整截图：

- `vivado_pass_summary_full_screenshot.png`：显示 `errors=0`、`completed=1`、`opcode_coverage=ffff`、JZ taken/not-taken 计数、最终 PC/指令/Z/GPIO OUT/DIR。
- `vivado_final_state_full_screenshot.png`：显示 `errors=0`、最终 PC/Z、R0～R3 和 GPIO OUT/DIR/IN。

## 验收状态

- 已满足：工程分类、可综合 RTL、机器码及注释、人工规格核对、控制真值表、GPIO 地址表、自检 testbench、可复现脚本、Vivado 编译、展开、动态仿真、六项 `TEST PASS`、动态参考模型比较、VCD/WCFG、四组 SVG/PNG。
- 不在本阶段：XDC、综合时序、bitstream、ILA、上板。

本阶段未执行 GitHub 上传、远端分支创建或上板相关工作。
