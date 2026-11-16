# Snake System Bug Fix Log

## SNK-BUG-001：XSim Tcl 路径被转义

- 失败现象：四个 testbench 均完成编译和 elaboration，但 XSim 找不到 `run_simulation.tcl`。
- 根因：Windows 反斜杠路径中的 `\r` 等字符被 Tcl 当作转义序列。
- 修复：传给 `-tclbatch` 前统一替换为正斜杠。
- 证据：`reports/bugs/SNK-BUG-001/failure-summary.txt`，修复后 RTL 回归 4/4 PASS。

## SNK-BUG-002：定时器确认周期可能再次置位

- 失败测试：`tb_tick_timer`，失败信息 `pause failed`。
- 影响：CPU 长时间发送串口帧时，确认 tick 的同一周期可能产生新 tick，导致紧邻的第二次移动。
- 根因：`tick_pending=1` 时分频计数器仍继续运行。
- 修复：pending 期间冻结计数器；CPU 读取 `0x12` 后再从下一周期重新计数。
- 修复前关键逻辑：pending 期间计数器仍执行 `counter <= counter + 1'b1`。
- 修复后关键逻辑：先判断 `if (tick_pending)` 并保持 `counter <= counter`，只在 pending 清除后重新计数。
- 失败日志：`reports/bugs/SNK-BUG-002/failing-tb_tick_timer.log`。
- 修复结果：定时器单测和整体系统回归通过。

## SNK-BUG-003：Vivado 2026.1 构建进程异常退出

- 失败阶段：第一次到达 synthesis IO insertion；后续新 Vivado 进程在 synthesis 启动或创建工程时退出。
- 信息：`EXCEPTION_ACCESS_VIOLATION`，没有 RTL error。
- 已尝试：单线程、临时短盘符、非工程模式和工程创建入口。
- 后续状态：遗留进程自行退出后，Vivado 成功完成综合、布局布线和报告生成；说明这不是 RTL 功能错误。
- 证据：`reports/bugs/SNK-BUG-003/` 下的三次日志和 `hs_err` 文件。
- 状态：环境异常已消失，后续构建进入 Bitgen，见 SNK-BUG-004。

## SNK-BUG-004：Bitgen 重新解析外部 MEM 失败

- 失败阶段：完成布线和 DRC 后执行 `write_bitstream`。
- 失败信息：`Loading data files...` 后出现 `[Designutils 12-1097] 71 - Unknown term found in boolean expression`。
- 失败前状态：设计 fully routed，DRC 0 error，100 MHz 时序 WNS `+0.192 ns`、TNS `0`。
- 根因定位：故障只出现在 Bitgen 的外部数据文件加载路径；综合和布局布线均已正确读取同一份机器码。为消除 Vivado 2026.1 对外部 MEM 的二次解析依赖，综合 ROM 改为汇编器生成的内嵌初始化 Verilog ROM。
- 修复前代码：`instruction_memory #(.INIT_FILE(INIT_FILE))` 使用 `$readmemh(INIT_FILE, memory)`。
- 修复后代码：`snake_program_rom u_instruction_memory`；汇编器继续生成 `snake.mem`，同时生成 `rtl/memory/snake_program_rom.v`。
- 一致性检查：MEM 和 Verilog ROM 均为 256 个字，逐项比较完全一致；程序仍为 249 条有效指令和 7 条保留指令。
- 失败日志：`reports/bugs/SNK-BUG-004/failing-write-bitstream.log`。
- 状态：已关闭。修复后 Bitgen 成功，生成 `reports/board/MiniRISC16_Snake.bit`。

## SNK-BUG-005：受限进程无法读取 Vivado 许可证目录

- 现象：四个 testbench 均重新完成 `xvlog` 和 `xelab`，但 XSim 启动时报 `Could not obtain the necessary license for Simulator`；Vivado batch 启动返回 exit code 42。
- 影响：在受限执行环境中暂时阻塞动态 XSim 和 Vivado 构建。
- 根因：许可证并未消失。受限进程不能读取 `%APPDATA%\XilinxLicense`，因此 Vivado 报告找不到有效许可证。
- 诊断结果：存在有效的 Vivado BASIC 节点锁定许可证，Simulation、Synthesis 和 Implementation 均可签出，有效期至 2027-09-03；许可证为 `uncounted`，不是席位耗尽。
- 分类：执行环境文件访问限制，不是许可证损坏、到期或 RTL 错误。
- 证据：`reports/bugs/SNK-BUG-005/regression-license-block.txt` 和 `tb_snake_system-license-block.log`。
- 修复结果：在允许读取本机许可证目录的正常权限下重新执行；XSim 4/4 PASS，综合、实现和 Bitgen 全部成功。

## SNK-BUG-006：组合 case ROM 导致 Vivado Technology Mapping 崩溃

- 失败阶段：第一次把外部 MEM 改为 256 项组合 `case` ROM 后，Vivado 在 Technology Mapping 阶段发生 `EXCEPTION_ACCESS_VIOLATION`。
- 根因：Vivado 2026.1 把组合 ROM展开成 257 输入、16 位 MUX，在 technology mapping 中触发工具崩溃；没有 RTL error。
- 修复前代码：`always @* case (addr) ... instruction = 16'hxxxx; endcase`。
- 修复后代码：生成 `reg [15:0] memory [0:255]`，用常量 `initial` 逐项初始化，再以 `assign instruction = memory[addr]` 读取。
- 失败证据：`reports/bugs/SNK-BUG-006/case-rom-techmap-crash.log`。
- 修复结果：XSim 4/4 PASS；综合、布局布线和 Bitgen 成功，WNS `+0.192 ns`。

## 当前结果

- 汇编 249 条有效指令，7 条保留。
- 独立指令模型通过初始化、移动、增长、碰撞、重启和反向保护。
- 当前 Vivado XSim 回归 4/4 PASS。
- 当前实现 fully routed，DRC 0 error，100 MHz 时序 WNS `+0.192 ns`、TNS `0`。
- Bitgen 成功，输出 `reports/board/MiniRISC16_Snake.bit`。
- 实板功能测试尚未执行。
