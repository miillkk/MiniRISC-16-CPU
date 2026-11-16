# HDMI Snake Bug / Fix Log

## HDMI-BUG-001：无用 SPDIF 端口约束到不可放置管脚

- 日期：2026-10-16
- 影响：`hdmi_snake_board_top`、`hdmi_video_subsystem`、XDC。
- 复现：运行 bitstream 构建，综合后解析 XDC。
- 失败信息：`Cannot set LOC property ... hdmi_spdif_OBUF_inst ... site A8 ... do not match cell type (OBUF)`。
- 修复前：顶层输出 `hdmi_spdif`，XDC 将其约束到 A8；本系统不传输音频。
- 根因：手册中的该网络不是本设计所需的普通 PL 输出位置，且纯视频方案根本不需要 SPDIF。
- 修复：从 RTL 顶层、子系统、testbench 和 XDC 中删除 SPDIF 端口，不占用无关板级资源。
- 修复后：后续综合显示 0 Error、0 Critical Warning，原非法 LOC 消失。
- 证据：`reports/implementation/bitstream_90332.backup.log`（修复前）和后续综合日志。

## HDMI-BUG-002：XDC 使用不受支持的 Tcl `if`

- 日期：2026-10-16
- 影响：HDMI 输出寄存器 IOB 约束。
- 复现：综合时读取 `EES331_hdmi_snake.xdc`。
- 失败信息：`Command 'if' is not supported in the xdc constraint file`。
- 修复前：用 `if {[llength ...] > 0}` 包围 `set_property IOB TRUE`。
- 根因：XDC 解析器只接受约束命令子集，不接受普通 Tcl 控制流。
- 修复：改为直接对精确层级匹配结果应用 IOB 属性。
- 修复后：XDC 解析不再出现该 Critical Warning。

## HDMI-ENV-001：受限执行环境中的 XSim 生成 C 文件编译失败

- 日期：2026-10-16
- 分类：工具环境问题，不是 RTL Bug。
- 现象：受限环境执行 `xelab` 时，10 个用例都报 `[XSIM 43-3409] Failed to compile generated C file`。
- 判定：最小 `tb_video_timing_640x480` 与原有 CPU 用例表现完全相同。
- 处理：在完整 Vivado 环境重跑同一回归。
- 结果：参考模型 PASS；XSim 10/10 PASS。
- 证据：`reports/simulation/regression-summary.txt` 和各用例 `.log/.wdb/.vcd`。

## HDMI-ENV-002：Vivado 2026.1 实现进程内部崩溃

- 日期：2026-10-16
- 分类：工具环境间歇性问题；之后同一机器成功完成构建。
- 现象：Vivado 在器件加载、综合尾部或 `opt_design` 随机出现 `EXCEPTION_ACCESS_VIOLATION`、`ProcHandler::InvalidParam` 或 `Node template data out of sync`。
- 排除方法：用只有一个 D 触发器的 `minimal_top.v` 运行同一器件综合，仍可在启动综合子进程时崩溃；因此问题不依赖 HDMI、CPU 或 Snake RTL。
- 已采取措施：单线程、修正全部 XDC Critical Warning、尝试稳定综合策略、把综合和实现拆成两个独立 Vivado 进程，并完整保存失败日志。2026-10-16 又分别用独立隐藏进程运行最小综合、在 Vivado 图形工程中以 1 个 job 运行完整综合；两者仍发生同样的访问冲突。
- 当前结果：后续批处理重跑完成综合、布线、布线后物理优化和 bitstream；标准脚本复跑 WNS=+0.073 ns。构建时空闲 Vivado 工程窗口保持打开，因此关闭窗口不是必要条件。间歇性崩溃的底层原因仍未确定。
- 复现时处理：保留失败日志，重跑 `scripts\run.ps1 -Task Bitstream`；只有出现 `HDMI SNAKE BITSTREAM PASS` 且时序达标才使用生成文件。
- 证据：`reports/bugs/HDMI-ENV-001/minimal_synthesis.log`、`minimal_detached.log`、根目录 `hs_err_pid*.log`、`reports/implementation/bitstream*.log`、`synthesis-checkpoint.log`，以及 `vivado_project/MiniRISC16_HDMISnake.runs/synth_1/runme.log`。图形工程这次在约束验证后异常退出，没有生成综合 DCP。

## HDMI-BUG-003：像素渲染组合路径超过半个像素周期

- 日期：2026-10-16；影响：`hdmi_video_subsystem.v`。
- 复现：原 RTL 综合报告中 `pixel_x_reg` 到反沿 `hdmi_data_reg` 的路径有 36 级逻辑，Slack=-5.763 ns。
- 修复前：`snake_renderer` 的 Y/Cb/Cr 与同步信号直接连接到反沿 HDMI 输出寄存器。
- 根因：渲染器的坐标换算、字符选择及调色板逻辑只能使用约 19.86 ns 半周期。
- 修复后：在像素时钟上升沿同时寄存 Y/Cb/Cr、同步、DE 和奇偶位，反沿输出寄存器读取这一组同相位数据；渲染器因此获得完整像素周期。
- 验证：修改后综合报告像素域最差 Slack=+16.467 ns；参考模型与 XSim 回归 10/10 PASS。时序问题以综合报告为证据，不产生错误波形。
- 证据：`reports/synthesis/hdmi-snake-synth-timing.rpt`（修复后）、`reports/implementation/bitstream_64220.backup.log`（旧综合过程）及 `reports/simulation/regression-summary.txt`。

## HDMI-BUG-004：整帧跨时钟握手被按单周期路径计时

- 日期：2026-10-16；影响：`video_frame_bridge.v` 的时序约束与实现流程。
- 复现：首轮完全布线的 `hdmi-snake-implemented-timing.rpt` 报 WNS=-1.944 ns、TNS=-930.703 ns；546 个失败端点主要是 `held_frame_reg` 到 `pixel_frame_reg`。
- 修复前：该稳定保持的整帧数据总线没有专用跨域约束。
- 根因：数据在 100 MHz 域锁存后，由双级同步的 `frame_toggle` 通知像素域延后采集；工具却要求数据在相邻的两个异域时钟沿之间到达。
- 修复后：`video_frame_cdc.xdc` 只排除该握手数据总线和首级同步器的跨域路径；保留 CPU、像素域内部及同步器级间时序。再做布线后物理优化。
- 验证：首次应用约束后 WNS=-0.287 ns，物理优化后 WNS=+0.011 ns；标准脚本从头复跑 WNS=+0.073 ns、TNS=0；DRC 0 Error，bitstream 成功。跨域时序问题以实现报告为证据，不产生错误波形。
- 证据：`reports/implementation/hdmi-snake-implemented-timing.rpt`、`hdmi-snake-cdc-timing.rpt`、`hdmi-snake-postroute-timing.rpt`、`hdmi-snake-postroute-drc.rpt` 与 `finalize-routed.log`。

由于上述工具崩溃发生在综合/实现阶段，不会生成有意义的错误波形；按规范保存完整工具日志，并明确注明“无法产生失败波形”。RTL 功能错误则由 XSim WDB/VCD 覆盖。

## HDMI-ENV-003：诊断版构建时 Vivado 再次崩溃

- 日期：2026-10-17；分类：工具环境问题，尚未完成诊断 bitstream。
- 背景：实板已能显示 `10AD`，外部 5V 供电；显示器、同一根 HDMI 线和同一输入口在电脑上正常，但板卡 LED5=0、LED6=0、屏幕无信号。当前灯位不足以确定 ADV7511 停在哪一步。
- 诊断修改：增加只用于诊断构建的 `HDMI_DIAGNOSTIC_LEDS` 参数；原版参数默认为 0，已生成的游戏 bitstream 未被覆盖。
- 失败复现：`scripts/run_diagnostic.ps1` 两次在综合期间访问冲突；第三次成功写出 `reports/diagnostics/diagnostic_synth.dcp`，随后在放置阶段访问冲突。从综合检查点重试，并改用保守放置策略，仍在放置优化阶段以 `-1073740940` 退出。
- 证据：`reports/diagnostics/build*.log`、`diagnostic_synth.dcp`、根目录新增的 `hs_err_pid*.log`。异常退出发生在实现阶段，无法产生错误波形，也不能声明时序或 bitstream PASS。
- 当前处理：`reports/diagnostics/STATUS.md` 明确禁止下载不存在的诊断 bitstream；待 Vivado 稳定后从综合检查点继续。
- 后续隔离验证：另建不包含 CPU/游戏的 `hdmi_link_diagnostic_top`，持续输出彩条并将控制器状态编码到 LED。该独立 bitstream 已成功综合、布线和生成：WNS=+4.096 ns、TNS=0、DRC 0 Error。文件在 `reports/diagnostics/link_only/MiniRISC16_HDMI_LinkDiagnostic.bit`；仍待实板验证，不能据此认定 HDMI 功能 PASS。完整系统诊断 bitstream 仍未生成。

## HDMI-ENV-004：XSim 生成的 C 文件编译失败复现

- 日期：2026-10-17；分类：工具环境问题。
- 复现：诊断 RTL 改动后运行 `scripts/run.ps1 -Task Regression`；10 个测试均通过 `xvlog` Verilog 编译和 `xelab` 静态展开，然后在生成的 C 文件编译阶段报 `XSIM 43-3409`。
- 证据：`reports/simulation/regression-last-attempt.txt` 和各 `tb_*.log`。未得到动态波形，不能将本次尝试计为 XSim PASS；此前的 `regression-summary.txt` 仅代表修改前的成功结果。

## HDMI-BOARD-001：实板首次 I²C 读取一直未完成（原因待定位）

- 日期：2026-10-17；状态：未修复，不把当前症状当作已确认的 RTL Bug。
- 复现：外部 5V 供电；与电脑测试相同的显示器、HDMI 线和输入口；原游戏 bitstream 可显示 `10AD`，但屏幕无信号。第一版 HDMI-only 诊断 bitstream 下载后，仅 L5 和 L2 亮。
- 解释：第一版的 LED7..4 是控制器状态，因此 L5=1 对应状态 `2`（等待首次读取 ADV7511 寄存器 `0x42`）；L2=1 表示 I²C 主机忙。HPD 尚未读出，不能直接归因于显示器未产生 HPD。
- 下一步：第二版 `reports/diagnostics/link_detail/MiniRISC16_HDMI_BusDiagnostic.bit` 已生成并通过 WNS=+4.268 ns、DRC 0 Error。SW0=1 时显示 I²C 状态及 SCL/SDA 实际电平，等待用户实板结果后再确定根因与修复方案。
- 证据：用户提供的实板 LED/屏幕观察、`reports/diagnostics/STATUS.md`、`reports/diagnostics/build*.log`、`reports/diagnostics/link_detail/timing.rpt` 与 `drc.rpt`。当前没有错误波形或逻辑分析仪捕获，不能虚构。
- 第二页实板复现：SW0=1 后 L5、L3 亮，L2 灭，即 I²C 主机状态 `5` (`S_TX_HIGH`) 且 SCL 引脚读回低。按住 S1 时 L1、L2 亮、L5 灭，说明复位/总线释放时 SDA/SCL 都能上升；松开又回到 L5、L3 亮。故障发生在发起第一次 I²C 事务后，而不是总线永久短路到地。仍未确定是 FPGA 输出未释放，还是外部器件/IOBUF 持续拉低。
- 第三版诊断源码增加 FPGA 的 `scl_low` 输出显示，但 **bitstream 尚未生成**。Vivado 重试在综合启动阶段访问冲突，并在另一轮报告 `Invalid ntl library file: .../PHASER_IN_PHY.btl`；详见 `reports/diagnostics/build*.log`。此工具异常与实板 I²C 故障分开记录。
- 后续重试：将诊断构建缩减为仅复位、视频和 HDMI 诊断源码后，RTL 展开与 XDC 解析完成，但仍发生 `EXCEPTION_ACCESS_VIOLATION`。同一个已布线 DCP 曾成功打开并确认 `scl_low` 相关网络存在，随后相同操作在恢复 timing archive 时崩溃；下一次 Vivado 启动又报告 `bad allocation` 和 `Could not load library 'xv_coretasks'`。当时日志显示仍有约 22 GB 可用虚拟内存，许可证成功取得，且没有残留 Vivado 进程。因此判定为 Vivado 2026.1 安装/运行环境异常，而非许可证不足或固定的 RTL 编译错误。证据见 `reports/diagnostics/inspect-link.log` 及新增 `hs_err_pid*.log`。
- ROSS 重试结果：ROSS MCP 已正常安装和响应，但 Windows 启动器未能通过 `vivado.bat` 建立会话；改用官方批处理入口后许可证、Verilog 读取和器件加载均成功，仍在 `synth_design` 辅助进程启动时发生 `EXCEPTION_ACCESS_VIOLATION`。这再次排除了许可证不足和 RTL 语法错误。
- 诊断绕行方案：打开已验证的 `link_detail/link_routed.dcp`，确认 `iic_scl_hdmi_IOBUF_inst/T` 由 `iic_scl_hdmi_TRI` 驱动。通过一根网表 ECO 将 LED0 改接到该三态控制网，保留 LED2 为 SCL 引脚读回值。增量布线无失败网络，WNS=+4.268 ns、TNS=0、DRC 0 Error，生成 `reports/diagnostics/link_drive_eco/MiniRISC16_HDMI_SCLDiagnostic.bit`。该文件只用于定位，不视为 HDMI 功能已通过。
- 上拉诊断：实板显示状态5时 LED0亮、LED2灭，证明FPGA已经释放SCL但管脚未上升；LED1灭是因为首个地址字节 `8'h72` 的bit7为0，属于正常主机输出。XDC未配置内部上拉，因此建立独立上拉诊断版。首次在设置 `PULLUP=1` 后调用 `route_design -preserve`，Vivado再次发生 `EXCEPTION_ACCESS_VIOLATION`；由于PULLUP仅为IOB配置且源DCP已完整布线，移除不必要的重布线步骤后成功生成 `reports/diagnostics/link_pullup_eco/MiniRISC16_HDMI_PullupDiagnostic.bit`。验证结果为WNS=+4.268 ns、TNS=0、DRC 0 Error、498/498可布线网络完全布通。该版本仍仅用于实板故障隔离。
- 2026-10-30 电气隔离测试：新增不含 CPU、视频和 I2C 事务的 `hdmi_i2c_electrical_test_top`，SCL 每 0.5 秒在“拉低/释放”间切换，SDA 始终释放，LED 同时显示命令和实际管脚电平。最初 XDC 将双向 I2C 端口同时加入输入/输出 false-path，Vivado 在 `Cache Timing Information` 报 `ProcHandler::InvalidParam`；删除这两条对本测试无必要的约束后，优化和布局通过。默认路由仍间歇报 `Device 21-9324`/访问冲突，改为从 placed DCP 重建时序约束并使用 `route_design -directive Quick` 后成功。最终 55/55 可布线网络完全布通，DRC 0 Error，WNS=+5.601 ns、TNS=0，bitstream 为 `reports/diagnostics/i2c_electrical/MiniRISC16_HDMI_I2C_ElectricalTest.bit`。错误发生在实现阶段，无法产生错误波形；完整失败日志由根目录 `hs_err_pid*.log` 和批处理输出保留。

