# Bug 与修复记录

本文只记录 `refactored_design/` 在 RTL 设计、CPU 仿真和综合检查中真实发现的问题。原工程未修改。

## 验证结论

- 原 11 个 CPU testbench 在 CPU 重构阶段全部通过，每项均保存过 `.log`、`.vcd` 和 `.wdb`。
- `tb_cpu_core` 完成 29 个有效指令提交并覆盖全部 16 个 opcode。
- EES331 板级设计使用 `xc7z020clg484-1` 完成综合、布局布线和 bitstream 生成。
- 板级实现使用 218 LUT、144 Register、42 bonded IOB 和 1 BUFG；100 MHz 下 WNS 为 `+1.513 ns`、TNS 为 `0.000 ns`。
- 新增 6 个板级 testbench 已通过 `xvlog` 语法/模块解析；当前机器的 XSim 链接阶段被 BUG-006 所述工具环境问题阻塞。
- 全指令板上自检的独立模型执行到 PASS 循环并得到 opcode coverage=`FFFF`；对应设计已完成实现和独立 bitstream 生成，100 MHz WNS=`+0.928 ns`。
- 流水灯独立模型验证完整回卷序列，对应实现和 bitstream 已生成，100 MHz WNS=`+0.683 ns`。
- CPU 行为仿真未发现 RTL 功能 Bug，因此没有人为制造错误波形。

## BUG-001：综合脚本未自动发现 License

- 阶段：综合脚本启动。
- 现象：Vivado 启动后立即报告没有有效许可证。
- 失败证据：`reports/bugs/BUG-001/failing-console.log`。
- 修复前代码：综合脚本只查找 `vivado.bat`，没有设置 `XILINXD_LICENSE_FILE`。
- 根因：回归脚本已有许可证自动发现逻辑，但独立综合脚本遗漏了该逻辑。
- 修复：增加 `-LicenseFile` 参数，并依次检查显式参数、`%APPDATA%/XilinxLicense/Xilinx.lic` 和 `%USERPROFILE%/.Xilinx/Xilinx.lic`。
- 修复证据：`reports/bugs/BUG-001/fixed-vivado-synthesis.log`。
- 波形：无。错误发生在 Vivado 载入 RTL 前。

## BUG-002：Vivado Tcl 错误解析工程根路径

- 阶段：综合脚本初始化。
- 现象：报告目录被错误解析为 `C:/Users/xieke/CPU`，随后出现权限拒绝。
- 失败证据：`reports/bugs/BUG-002/failing-vivado-synthesis.log`。
- 修复前代码：Tcl 通过 `[file normalize [file join [file dirname [info script]] .. ..]]` 推导工程根目录。
- 根因：当前 Windows/Vivado 环境对脚本路径进行了与 PowerShell 不一致的规范化。
- 修复：PowerShell 使用 `Resolve-Path` 得到准确目录，通过 `MINIRISC_REFACTORED_ROOT` 传入 Tcl；同时把 Tcl、日志和 journal 路径转换为正斜杠。
- 修复证据：`reports/bugs/BUG-002/fixed-vivado-synthesis.log`。
- 波形：无。错误发生在 RTL 读入前。

## BUG-003：本机 Vivado Tcl Store 损坏导致 `read_verilog` 失败

- 阶段：Vivado 读入 RTL。
- 现象：Vivado 无法加载 `::tclapp::support::appinit`，随后又无法加载 `xilinx::xsim`、`xilinx::modelsim`。
- 失败证据：`reports/bugs/BUG-003/failing-vivado-synthesis.log`。
- 根因：用户目录中的 Xilinx Tcl Store catalog 损坏，Vivado 回退后没有把安装目录中的各个 package 目录加入 Tcl 搜索路径。
- 修复：不修改用户全局配置；脚本根据 `vivado.bat` 定位安装自带的 `XilinxTclStore`，临时设置 `XILINX_TCLAPP_REPO`，并把全部 `pkgIndex.tcl` 所在目录加入 `TCLLIBPATH`。Vivado 退出后恢复原环境变量。
- 修复证据：`reports/bugs/BUG-003/fixed-vivado-synthesis.log`。
- 已知环境现象：Vivado 启动时仍会报用户 Tcl Store catalog 损坏的 critical warning，但工程内临时搜索路径已使 RTL 读取、综合和工程创建全部成功。
- 波形：无。错误发生在编译阶段。

## BUG-004：空 ROM 使综合结果被全部裁剪

- 阶段：首次成功综合。
- 现象：综合命令返回成功，但报告显示 0 LUT、0 Register、0 IOB，无法证明 CPU 或 GPIO buffer 被实现。
- 失败证据：`reports/bugs/BUG-004/failing-vivado-synthesis.log`、`failing-utilization.rpt`。
- 修复前代码：`synth_design` 使用 `system_top` 的默认空 `INIT_FILE`，ROM 因而全部为无副作用保留指令。
- 根因：在固定的空程序下，CPU 永远不会产生可观察输出，Vivado 合法地裁剪了整个设计。
- 修复：综合时通过 generic 将 `sim/programs/system_demo.mem` 绑定到 `INIT_FILE`；同时把 `gpio8.io_wdata` 缩为实际使用的 8 位并在顶层显式连接 `io_wdata[7:0]`。
- 修复证据：`reports/bugs/BUG-004/fixed-vivado-synthesis.log`、`fixed-utilization.rpt`。
- 修复结果：232 LUT、107 Register、10 bonded IOB，其中包含 8 个 `IOBUF`。
- 波形：无。该问题属于综合配置错误；行为仿真此前已经通过。

## BUG-005：板级目标器件封装设置错误

- 阶段：读取 EES331 用户手册并准备 XDC。
- 现象：原重构工程和综合脚本使用 `xc7z020clg400-1`，而 EES331 v1.0 实际器件为 `xc7z020clg484-1`。
- 失败证据：`reports/bugs/BUG-005/before-create_vivado_project.tcl`、`before-run_synthesis.tcl`、`before-utilization.rpt`。
- 影响：CLG400 与 CLG484 的封装和可用管脚不同；继续使用旧器件配置会导致 EES331 XDC 管脚不可用，旧 bitstream 也绝不能用于该板。
- 根因：CPU 重构阶段缺少已确认的板级资料，临时目标器件选错。
- 修复：把通用工程和综合脚本的 Part 改为 `xc7z020clg484-1`；新增板级工程、EES331 XDC 和独立 bitstream 流程。
- 修复证据：`reports/board/board-implemented-drc.rpt`、`board-io.rpt`、`board-implemented-timing.rpt`、`MiniRISC16_EES331.bit`。
- 修复结果：全部 42 个顶层 I/O 已定位并指定 LVCMOS33，布局布线完成，bitstream 成功生成。
- 波形：无。该问题是器件/约束配置错误，不是行为仿真错误。

## BUG-006：Vivado 2026.1 自带 XSim 编译器无法在当前 Windows 运行

- 阶段：加入 4 个板级 testbench 后执行 15 项回归。
- 复现：运行 `sim/scripts/run_all.ps1 -IncludeBoard`。
- 现象：`xvlog` 能成功解析全部 RTL 和 testbench，但 `xelab` 调用 `Vivado/tps/mingw/6.2.0/.../gcc.exe` 时失败；系统报告“无效的系统 DLL 重定位”，全部测试在仿真启动前停止。
- 失败证据：`reports/bugs/BUG-006/failing-regression-summary.txt`、`failing-tb_alu.log`、`failing-tb_board_top_smoke.log`。
- 根因：Vivado 2026.1 的 XSim 仍硬编码调用旧 MinGW 6.2.0；该可执行文件与当前 Windows 系统 DLL 地址布局不兼容。使用安装中可运行的 MinGW 10 代替后又会因链接模型不同产生 `IMAGE_REL_AMD64_ADDR32` 溢出，因此不能把替换编译器作为可靠修复交付。
- 影响：当前机器无法重新执行动态 XSim 回归；这不影响 `read_verilog`、综合、实现、DRC、时序分析或 bitstream 生成。
- 处理：保留完整失败现场，不修改 Vivado 安装目录；建议在可正常运行 XSim 的 Vivado/Windows 环境中执行 15 项回归，或安装独立 Icarus Verilog/Verilator 后增加第二套回归脚本。
- 波形：无。错误发生在 XSim 生成的 C 文件编译/链接阶段，仿真内核从未启动，无法产生可信的失败波形。

## BUG-007：通用 Vivado 工程误收录板级 testbench

- 阶段：生成独立 EES331 工程后检查两个 `.xpr` 的源文件集合。
- 现象：通用工程脚本用通配符加入 `sim/tb/*.v`，因此把 `tb_board_top_smoke` 等板级 testbench 加入了通用工程；但通用工程的 Design Sources 不包含 `rtl/board`，切换仿真顶层时会出现缺少 `board_top` 的错误。
- 失败证据：`reports/bugs/BUG-007/before-MiniRISC16_Refactored.xpr`。
- 根因：新增板级测试后，原先“所有 testbench 都属于 CPU”的假设不再成立。
- 修复：通用工程显式列出 11 个 CPU testbench；板级工程仍包含 CPU 和板级测试，并以 `tb_board_top_smoke` 为默认仿真顶层。
- 修复结果：两个工程职责分离，通用工程不会出现板级模块缺失的伪错误。
- 波形：无。该问题是工程文件集配置错误。

## BUG-008：Vivado 通用综合首次重跑发生访问冲突

- 阶段：将通用 `system_top` 的目标器件从 CLG400 更新为 CLG484 后重跑综合。
- 现象：Vivado 在 `synth_design` 启动阶段异常终止，报告 `EXCEPTION_ACCESS_VIOLATION`。
- 失败证据：`reports/bugs/BUG-008/hs_err_pid44664.log`、`hs_err_pid44664.dmp`、`clockInfo.txt`。
- 根因：Vivado 进程的瞬时本机异常；崩溃发生在同一份 RTL 第二次运行能够正常综合之前，没有形成可重复的 RTL 触发条件。
- 处理：不改 RTL，清理本次临时进程状态后重试同一命令。
- 修复结果：第二次运行成功，`system_top` 在 `xc7z020clg484-1` 下综合为 0 errors、0 critical warnings、0 warnings，仍推断 8 个 `IOBUF`。
- 后续复现：创建 ISA 自检 Vivado 工程时，Vivado 启动阶段又出现 `alloc: invalid block` 和 `EXCEPTION_BREAKPOINT`；现场保存为 `isa-project-hs_err_pid24784.log/.dmp`。同一套 ISA RTL 的非工程 bitstream 流程已经完整成功，因此该现象继续归类为本机 Vivado 启动异常，而不是 RTL 错误。
- 再次复现：首次构建流水灯 bitstream 时，综合、布局和物理优化均为 0 Error，但 Vivado 在 `route_design` 的 Build RT Design 阶段发生 `EXCEPTION_ACCESS_VIOLATION`；现场保存为 `led-route-hs_err_pid15040.log/.dmp` 和 `led-route-clockInfo.txt`。不改 RTL 重试同一命令后，布线、时序报告和 bitstream 生成全部成功，进一步证明这是工具瞬时异常。
- 波形：无。问题发生在综合工具进程内部。

## BUG-009：新增板级任务未预先创建报告目录

- 阶段：首次运行 `BoardIsaBitstream`。
- 复现：运行 `sim/scripts/run_synthesis.ps1 -Task BoardIsaBitstream`，且 `reports/board_isa/` 尚不存在。
- 现象：Vivado 在执行 Tcl 前无法创建 `board-isa-bitstream.log` 和 `.jou`，报告 `Failed to open handle`；同一次启动随后发生与 BUG-008 同类的瞬时 `EXCEPTION_ACCESS_VIOLATION`。
- 失败证据：`reports/bugs/BUG-009/failing-console.log`、`hs_err_pid37004.log` 和 `hs_err_pid37004.dmp`。
- 修复前代码：脚本直接把尚不存在的新目录中的路径传给 Vivado `-log` 和 `-journal`，报告目录只会在 Vivado 启动后的 Tcl 脚本中创建。
- 根因：PowerShell 启动器没有在启动 Vivado 前创建所选任务的报告目录。
- 修复：计算 `logPath` 后立即用 `New-Item -ItemType Directory -Force` 创建其父目录，再启动 Vivado。
- 修复范围：所有现有和以后新增的综合、工程创建及 bitstream 任务。
- 修复结果：重试 `BoardIsaBitstream` 后日志和 journal 均正常生成，综合、布局布线和 bitstream 写入成功；完整成功日志为 `reports/bugs/BUG-009/fixed-board-isa-bitstream.log`。
- 波形：无。错误发生在 Vivado 读入 RTL 之前。

## BUG-010：流水灯从 LED7 回卷时插入全灭状态

- 阶段：流水灯机器码的独立指令模型检查。
- 复现：执行序列 `01→02→04→08→10→20→40→80` 后继续运行一次更新。
- 现象：失败序列为 `01→02→04→08→10→20→40→80→00→01`，LED 在回卷前多出一个全灭节拍。
- 失败证据：`reports/bugs/BUG-010/failing-model.log`。程序尚未生成 bitstream，因此没有错误实板波形；模型日志是最早失败现场。
- 修复前代码：读取 8 位 LED 回读值后直接执行 16 位 `ADDR R0,R0`，并尝试通过结果 Z 判断回卷。
- 根因：LED 的 `0x80` 回读为 16 位 `0x0080`，左移后得到 `0x0100` 而不是 `0x0000`；Z=0，但 OUP 只使用低8位，因此实际输出 `0x00`。
- 修复：移位前先把当前值与 `0x0080` 做 CMP；相等时直接写 `0x01`，否则再执行左移。
- 修复结果：独立模型得到 `01→02→04→08→10→20→40→80→01`；证据为 `reports/bugs/BUG-010/fixed-model.log`。

## 当前板级保留项

EES331 板级 XDC 已消除 `NSTD-1`、`UCIO-1` 和缺少时钟约束的问题。当前实现后的 DRC 只保留 `ZPS7-1`：本设计通过 JTAG 做纯 PL 易失性验证，不实例化 PS7。该警告未降级或隐藏；若后续需要 QSPI/SD 掉电启动，将另行增加 PS7、FSBL 和启动镜像流程。
