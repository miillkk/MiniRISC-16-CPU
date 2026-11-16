# Runtime System Bug Fix Log

## RUN-BUG-001：1024 字程序 RAM 导致默认实现时序失败

- 日期：2026-10-16
- 影响：`runtime_program_memory`、实现脚本、100 MHz 上板可靠性。
- 复现：运行 `scripts/run.ps1 -Task Bitstream`。
- 失败结果：默认布局布线后的 WNS 为 `-0.038 ns`，TNS 非零，脚本按验收规则终止且不生成 bitstream。
- 根因：`1K×16` 异步读分布式程序 RAM 到 CPU ALU/Flags 的单周期组合路径比原 256 字 ROM 更长，默认布局策略只差 38 ps 未收敛。
- 修复前流程：

```tcl
place_design
phys_opt_design
route_design
```

- 修复方案：保持非流水单周期 CPU，使用 timing-driven Explore 放置与 AggressiveExplore 物理优化，Router 使用稳定默认策略。
- 修复后流程：

```tcl
place_design -directive Explore
phys_opt_design -directive AggressiveExplore
route_design
```

- 修复结果：WNS `+0.185 ns`、TNS `0`、WHS `+0.099 ns`、THS `0`，0 未布通网络，bitstream 成功。
- 证据：`reports/bugs/RUN-BUG-001/failed-bitstream.log`、`failed-timing.rpt`、`fixed-bitstream.log`、`fixed-timing.rpt`。

## RUN-BUG-002：Loader 响应移位寄存器末项未驱动

- 日期：2026-10-16
- 影响：`program_loader` 综合质量。
- 复现：运行综合，Vivado 报告 `response[7] does not have driver`。
- 修复前代码只写入响应字节 `response[0..6]`，但统一移位循环读取 `response[7]`。
- 根因：最后一次移位不会把该值真正发送，因此仿真功能通过，但综合仍正确指出末项没有驱动。
- 修复：复位时显式清零 `response[0..7]`，保证数组每一项均有确定驱动。
- 修复结果：最终综合不再出现该警告，Loader testbench 继续 PASS。
- 证据：`reports/bugs/RUN-BUG-002/warning-before-fix.log`、`clean-elaboration-after-fix.log`。

## RUN-ENV-001：Vivado Explore Router 崩溃

- 日期：2026-10-16
- 分类：工具环境问题，不是 RTL 功能 Bug。
- 复现：执行 `route_design -directive Explore`。
- 现象：Vivado 2026.1 报 `Device 21-9324 Out of range request for wires in node template`，随后 `EXCEPTION_ACCESS_VIOLATION`。
- 处理：保留 Explore 放置和 AggressiveExplore 物理优化，Router 恢复默认策略。
- 结果：默认 Router 完成全部布线且最终 WNS `+0.185 ns`。
- 证据：`reports/bugs/RUN-ENV-001/vivado-route-crash.log`、`hs_err_pid94456.log`。

## RUN-ENV-002：较大计数比较常量触发 Vivado `opt_design` 内部异常

- 日期：2026-10-16
- 分类：工具环境问题，不是 RTL 功能 Bug。
- 复现：将 Snake 基准移动周期直接从 `50,000,000` 改为 `100,000,000` 后运行 bitstream 构建。
- 现象：综合连续两次均为 0 Error，但 Vivado 2026.1 在 `opt_design` 的 timing cache 阶段分别报 `ProcHandler::InvalidParam` 和进程退出码 `-1073740940`。
- 处理：保持已经稳定实现过的 5000 万周期比较器，增加一个 1 位半周期状态，使两个计数周期才产生一次移动事件。游戏速度同样降低一倍，同时避开不稳定的优化路径。
- 恢复结果：参考模型 PASS，XSim 6/6 PASS；稳定结构重新实现后 WNS `+0.157 ns`、TNS `0`，bitstream 成功生成。
- 证据：`reports/bugs/RUN-ENV-002/opt-design-internal-error.log`、`recovery-bitstream.log`。

## RUN-BUG-003：Loader 模式的 `10AD` 状态被显示使能关闭

- 日期：2026-10-16
- 影响：`runtime_soc`、Loader 上板状态提示。
- 实板复现：下载 Runtime bitstream，将 SW7 置 1；UART Loader 可以使用，但数码管未显示预期的 `10AD`。
- 修复前代码：`assign display_control = load_mode ? 16'h0000 : game_display_control;`
- 根因：`seven_segment8_driver` 使用 `control_value[0]` 作为全局显示使能；Loader 模式将整个控制寄存器清零，导致已经送到 `display_high` 的 `16'h10AD` 被消隐。
- 修复：Loader 模式改为输出 `16'h0001`，仅开启全局显示，不启用小数点。
- 修复后代码：`assign display_control = load_mode ? 16'h0001 : game_display_control;`
- 防回归：`tb_snake_system` 新增 Loader 模式断言，同时检查 `display_high==16'h10AD` 和 `display_control[0]==1`。
- 修复结果：参考模型 PASS，XSim 6/6 PASS；重新实现后 WNS `+0.101 ns`、TNS `0`、WHS `+0.049 ns`、THS `0`，DRC 0 Error，bitstream 成功生成。
- 证据：`reports/bugs/RUN-BUG-003/board-failure-and-root-cause.txt`、`regression-after-fix.txt`、`bitstream-after-fix.log`。

## 最终回归

- 汇编：294 active / 730 reserved。
- 参考模型：PASS。
- XSim：6/6 PASS。
- 综合：0 Error、0 Critical Warning、0 latch。
- 实现：WNS `+0.157 ns`、TNS `0`、0 unrouted net、DRC 0 Error。
- Bitstream：`reports/board/MiniRISC16_Runtime.bit`。

## RUN-ENH-001：终端蛇头、地图与障碍物重设计

- 日期：2026-10-30。
- 地图由 `8×8` 扩为 `16×8`，逻辑格数由 64 增为 128；仍使用现有 256 字数据 RAM，不修改 CPU 或外设 RTL。
- UART 状态帧由 72 字节扩为 140 字节：4 字节头、128 个地图格、4 字节状态元数据，以及版本、长度、序号和 XOR 校验。
- 蛇头默认恢复纯方向 Arrow 风格，并保留可选 Face 风格；蛇身根据年龄相邻关系绘制为粗线、收细尾端和拐角。尾部连接判断增加相邻蛇身兜底，孤立兜底字符也改为线端，从所有路径移除圆形尾巴。
- 障碍重新设计为 Open、Maze、Hard 三套固定地图，由 SW4..3 在重新开始时选择；三张地图的所有非墙格均属于同一个连通区域，右侧不再使用孤立横线和突兀直角。
- 取消 Score 2/4 动态加墙。Level 改为每两个食物提升一级，Score `0..1/2..3/4..5/6+` 对应 Level `0/1/2/3`，Level 3 饱和。
- 食物查找最多随机尝试 16 次，随后确定性扫描 128 个格子，消除地图较满时的无限随机循环。
- 暂停时棋盘变暗并显示恢复提示；Game Over 时棋盘中央显示重新开始提示。
- 汇编：477 active / 547 reserved；独立参考模型 PASS，执行 38592 条指令；三地图、彩色与 ASCII 终端预览 PASS。
- 2026-10-30 当次 XSim 的 6 个用例均通过 Verilog 编译与静态展开，随后统一被环境问题 `XSIM 43-3409` 阻断；该条记录描述当时状态，后续修复见 RUN-ENV-001。
- 当前可通过 SW7 UART Loader 上传 `program/snake.mem` 使用新版本，不要求重建 bitstream。

## RUN-ENV-001：本机 XSim 生成 C 文件失败

- 日期：2026-11-04。
- 根因：Vivado 2026.1 自带的 MinGW 6.2 `gcc.exe` 在本机 Windows 上无法启动，导致 `xelab` 报 `XSIM 43-3409`；RTL 与 testbench 本身已通过解析和静态展开。
- 修复：`run_runtime_waveforms_xsim.ps1` 和 Vivado Tcl 通过受支持的 `-gcc_install_path` 使用 `E:/mingw64/bin`，不替换 Vivado 安装文件。
- 结果：当前结构的 `tb_runtime_running_light_wave` 与 `tb_runtime_extended_isa_wave` 均完成 `xvlog → xelab → xsim`，原生 XSim 2/2 `TEST PASS`。
- 证据：生成非空 WDB、VCD、WCFG、独立仿真日志和五张英文 Vivado 风格波形图。
