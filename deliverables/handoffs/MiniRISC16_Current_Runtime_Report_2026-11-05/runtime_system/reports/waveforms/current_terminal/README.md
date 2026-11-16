# 当前非 HDMI 终端版波形重新验证

## 验证对象

- 版本目录：`refactored_design/runtime_system`
- 顶层：`runtime_board_top`
- SoC：`runtime_soc`
- CPU：当前 `rtl/core`，10 位 PC、1K×16 程序空间、256×16 数据 RAM
- 新增 ISA：`LDR`、`STR`、`JMPA`
- 日期：2026-11-04

本次沿用 2026-10-17 20:21 左右提出的波形展示要求：主波形必须包含 `PC`、`instruction`、`io_we`、`io_addr`、`io_wdata` 和板载 `LED`，并显示 Running Light 从 `0x01` 到 `0x02`。由于当前结构和 ISA 已经变化，旧工程波形不再作为当前版本证据。

## 结论

### Vivado 2026.1

- 根因：Vivado 2026.1 自带的 MinGW 6.2 `gcc.exe` 在本机 Windows 上无法启动，导致 `xelab` 报 `XSIM 43-3409`；这不是 RTL 或 testbench 错误。
- 修复：按 Vivado 支持的 GCC 路径设置，让 `launch_simulation` 通过 `-gcc_install_path E:/mingw64/bin` 使用本机可正常运行的 GCC 13.2。未修改 Vivado 安装目录，也未设置永久的全局环境变量。
- `tb_runtime_running_light_wave`：原生 XSim 动态仿真 PASS，结束时间 7576 ns。
- `tb_runtime_extended_isa_wave`：原生 XSim 动态仿真 PASS，结束时间 166 ns。
- 两项测试均完整通过 `xvlog → xelab → xsim`，并生成非空 WDB、VCD、WCFG 和独立仿真日志。

Vivado 证据：

- 完整批处理日志：`reports/waveforms/current_terminal/vivado-xsim-run.log`
- 原生结果目录：`reports/waveforms/current_terminal/vivado/`
- 一键重跑：`scripts/run_runtime_waveforms_xsim.ps1`
- Vivado 仿真 Tcl：`scripts/run_runtime_waveforms_vivado.tcl`

### 独立动态 RTL 后端

同一份 RTL 也使用 Icarus Verilog作独立交叉检查，覆盖以下 8 项：

1. `tb_cpu_data_instructions`
2. `tb_program_capacity`
3. `tb_program_loader`
4. `tb_uart_port`
5. `tb_tick_timer`
6. `tb_snake_system`
7. `tb_runtime_running_light_wave`
8. `tb_runtime_extended_isa_wave`

汇总：`reports/simulation/iverilog/regression-summary.txt`

本机 Winget 提供的 Icarus 12 Windows 版存在进程偶发崩溃：本轮全量串行回归中 `tb_snake_system` 曾空输出退出，单独复跑随即明确 `TEST PASS`，其余 7 项通过。Icarus 仅作交叉检查；本次波形与环境修复的正式判定以原生 Vivado/XSim 的 2/2 PASS 为准。

## 最终波形图：分图与风格

最终交付目录：`final_vivado_style/`

沿用旧版“分主题、独立图片”的组织方式，并采用接近 Vivado Wave 窗口的灰白界面、绿色波形、`Name/Value` 两列、时间刻度和黄色游标标注。PNG 适合直接放入报告或讲解文档，SVG 便于无损缩放。图像数据来自本轮原生 XSim 导出的 VCD；图片是按 Vivado Wave 风格排版的验证图，不是 Vivado GUI 的直接截图。

1. `01_single_cycle_commit.png` / `.svg`
   - reset 释放、10 位 PC、取指、寄存器写、数据写和 I/O 写在时钟边界提交。
2. `02_cmp_jz_jump_jmpa.png` / `.svg`
   - `CMP` 置 `Z=1`，随后实际执行 `JZ → 0x008`、页内 `JUMP → 0x00A`、绝对 `JMPA → 0x200`。
3. `03_registers_alu_writeback.png` / `.svg`
   - `rd_data`、`rs_data`、ALU、writeback 与 `R0–R3` 的连续变化。
4. `04_runtime_io_led.png` / `.svg`
   - 两个聚焦捕获窗口均来自当前 Running Light 程序：`OUP 0x30 = 0x0001` 与下一次 `OUP 0x30 = 0x0002`；保留 10 月 17 日要求的 `PC/instruction/io_we/io_addr/io_wdata/LED`。
5. `05_ldr_str_data_memory.png` / `.svg`
   - 新 ISA 的 `STR [0x22] = 0x005A` 和 `LDR R2 = [0x22]`，包含 RAM 接口与写回证据。

底层原生 XSim VCD：

- `vivado/running_light.vcd`
- `vivado/extended_isa.vcd`

最终聚焦回归：`tb_runtime_running_light_wave`、`tb_runtime_extended_isa_wave`，2/2 PASS。

## 修改范围

- 未修改 CPU、SoC 或外设 RTL。
- 新增两项波形 testbench、Vivado/XSim 重跑脚本、Icarus 交叉检查脚本和波形渲染脚本。
- XSim 修复限定在本项目启动脚本内，通过受支持的 GCC 路径参数生效；未替换 Vivado 自带文件。
- 修正 `tb_tick_timer.v` 的复位释放竞态：改为在时钟负沿释放复位，并按设计规定等待完整 32 个周期；这是 testbench 时序修正，不改变设计逻辑。
