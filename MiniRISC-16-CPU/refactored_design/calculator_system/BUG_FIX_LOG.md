# Calculator System Bug Fix Log

## CALC-BUG-001：回归脚本把成功汇编误判为失败

- 日期：2026-10-15
- 影响模块：`scripts/run.ps1`
- 失败测试：`run.ps1 -Task Regression`
- 复现：汇编器打印 `ASSEMBLE PASS` 后，runner 仍抛出 `Assembler failed.`。
- 影响：RTL 编译尚未开始，无法生成错误波形。

修复前：

```powershell
& (Join-Path $designRoot 'tools\assemble.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Assembler failed.' }
```

根因：PowerShell 子脚本成功返回时不保证重置原生程序使用的 `$LASTEXITCODE`，runner 读取到了之前命令遗留的非零值。

修复后：

```powershell
& (Join-Path $designRoot 'tools\assemble.ps1')
```

子脚本已设置 `$ErrorActionPreference='Stop'`，失败会直接抛出异常，因此不再读取不相关的 `$LASTEXITCODE`。

证据：

- 失败日志：`reports/bugs/CALC-BUG-001/failing-runner.log`
- 修复后：汇编 240 个有效字，参考模型 15/15 PASS，RTL 回归 7/7 PASS。
- 修复后整体波形：`reports/simulation/tb_calculator_system.vcd`

## CALC-BUG-002：板级异步 I/O 时序意图未写入 XDC

- 日期：2026-10-15
- 影响模块：`constraints/EES331_calculator.xdc`
- 失败检查：Vivado `report_methodology`
- 复现：第一次实现报告 41 个 `TIMING-18 Missing input or output delay`。
- 影响：CPU 内部时序已经满足，但异步人机 I/O 的约束意图不明确。

根因：XDC 只包含 100 MHz 时钟和引脚位置，没有声明拨码/复位是异步输入，也没有声明 LED/数码管是非同步显示输出。

修复：

```tcl
set_false_path -from [get_ports {resetn switches[*]}]
set_false_path -to [get_ports {led[*] seg_low[*] seg_high[*] digit_enable[*]}]
```

这只排除板外异步端口路径；同步器内部级间路径和全部 CPU 内部路径仍按 100 MHz 分析。

证据：

- 修复前摘要：`reports/bugs/CALC-BUG-002/failing-methodology-excerpt.txt`
- 修复后报告：`reports/implementation/calculator-methodology.rpt`，Checks found = 0。
- 修复后时序：WNS `+0.426 ns`、TNS `0.000 ns`、WHS `+0.225 ns`、THS `0.000 ns`。

## CALC-BUG-003：Vivado 工程模式首次综合子进程启动失败

- 日期：2026-10-16
- 影响模块：Vivado 2026.1 运行环境、`scripts/check_project.tcl`
- 失败检查：打开独立 XPR 后启动 `synth_1`
- 复现：首次使用 `launch_runs synth_1 -jobs 2` 时，Vivado 子进程报告 `bad allocation`，随后无法装载 `Rdi_coretasks`。
- 影响：该次工程模式综合未开始 RTL elaboration，因此没有错误波形；此前脚本模式综合、实现和 bitstream 不受影响。

根因判断：失败发生在 Vivado 核心库装载阶段，尚未解析设计源码；同一工程改为单作业并重试后正常读取全部源码、XDC 和 `calculator.mem`。因此归类为 Vivado 并行子进程的瞬时环境故障，不是 RTL 功能错误。

修复/规避：

```tcl
launch_runs synth_1 -jobs 1
```

证据：

- 首次失败日志：`reports/bugs/CALC-BUG-003/first-project-synthesis-failure.log`
- 修复后日志：`reports/implementation/project-check.log`
- 修复后结果：`CALCULATOR PROJECT CHECK PASS: synth_design Complete!`，并确认 `$readmem` 成功读取 `calculator.mem`。

## CALC-BUG-004：8 位最大乘法测试的 N 状态期望错误

- 日期：2026-10-16
- 影响模块：`tools/reference_model.ps1`、`tb/tb_calculator_system.v`
- 失败测试：8 位扩展后的 `0xFF × 0xFF`
- 现象：乘法结果正确显示为 `0xFE01`，但测试期望 LED 为 `0x05`，实际为 `0x15`。

根因：逻辑、乘法和除法的软件状态规则要求根据最终 16 位结果生成 Z/N。`0xFE01[15]=1`，所以 N 必须为 1。LED4=N，LED2..0=运算编号 5，正确 LED 为 `0x15`。

修复：把参考模型和 RTL 整体测试的期望值从 `0x05` 改为 `0x15`，不修改正确的运算 RTL/程序行为。

证据：

- 修复前日志：`reports/bugs/CALC-BUG-004/failing-reference-model.log`
- 修复说明：`reports/bugs/CALC-BUG-004/fixed-expectation.txt`
- 修复后结果：参考模型 15/15 PASS，Vivado XSim 9/9 PASS。

## CALC-BUG-005：打开的 Vivado GUI 阻止重新创建 XPR

- 日期：2026-10-16
- 影响模块：Vivado 工程生成环境
- 失败步骤：`run.ps1 -Task All` 中的 `create_project -force`
- 现象：Vivado 无法删除正在使用的 `MiniRISC16_Calculator.runs`。

根因：同一个 `MiniRISC16_Calculator.xpr` 正在 Vivado GUI 中打开，且 Hardware Manager 已连接开发板。为防止丢失用户界面状态，没有强制结束该进程。

处理：使用不依赖 XPR 目录的 `-Task Bitstream` 流程完成新版 RTL 的综合、实现和 bitstream；关闭 GUI 后再执行 `-Task CreateProject` 即可刷新 XPR。

证据：

- 失败日志：`reports/bugs/CALC-BUG-005/failing-create-project.log`
- 处理说明：`reports/bugs/CALC-BUG-005/workaround-summary.txt`
- 新版实现结果：WNS `+0.559 ns`、TNS `0.000 ns`、0 条失败/未布通网络，bitstream 生成成功。

## 当前验证结论

- 未发现仍未修复的 RTL 功能错误。
- 独立参考模型覆盖 15 个运算/边界场景。
- 9 个 Vivado XSim testbench 全部通过。
- 综合、布局布线和新版 bitstream 成功。
- 当前打开的 Vivado GUI 关闭后，仍需刷新并复查独立 XPR。
- DRC 仅有纯 PL/JTAG Zynq 设计已知的 `ZPS7-1`，不影响本次 PL 下载测试。
- 实板交互测试仍需按 `BOARD_TEST_GUIDE.md` 由用户执行并补充观察记录。
