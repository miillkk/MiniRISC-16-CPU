# CPU 工作区总览：MiniRISC-16 设计、验证、实板与答辩

整理日期：2026-10-23。本文件是整个 `CPU` 文件夹的导航和阶段说明；子工程自己的 README、测试指南、源代码和报告仍分别保存。此次只新增本文件，没有移动、删除源码或重建工程。

完整的并行方向、CPU/ISA 演进和分支差异见 [PROJECT_BRANCH_MAP.md](PROJECT_BRANCH_MAP.md)。

## 1. 当前项目到了哪里

项目已从最初的 **16 位单周期 CPU + GPIO 功能仿真**，发展为包含重构 CPU、板级演示、ISA 自检、流水灯、交互式计算器、串口贪吃蛇、可加载程序 Runtime 和 HDMI 扩展的工作区。当前有两条主要工作线：

- **可讲解和演示的成果线**：基础 CPU、ZNVC 重构、板级 I/O、流水灯与计算器，以及五类指令的聚焦波形；已生成静态答辩 PPT 和详细讲解稿。
- **进一步扩展线**：串口贪吃蛇与 Runtime 已有用户实板运行反馈；HDMI 游戏已生成 bitstream，但真实显示链路尚未打通，正在定位 ADV7511/I²C 的 SCL 等待问题。

不能用基础 README 中的“尚未做上板”描述整个工作区，也不能把某一轮仿真或 bitstream 成功等同于全部系统实板验收完成。

### 状态证据怎么读

本文区分三种证据：①当前实际存在的文件；②历史脚本日志、验证汇总和实现报告；③旧聊天中的用户反馈与助手执行记录。本次没有重新运行 Vivado、连接板卡或复测硬件。聊天中的建议和开发计划不自动视为已实现功能；旧附件图片未重新逐张读取。

## 2. 整个文件夹的分工

```text
CPU/
├─ README.md                         本总览
├─ MiniRISC-16-CPU/                   持续开发的主工程目录，内有独立 .git
│  ├─ README.md                      基础 GPIO 版本说明
│  ├─ docs/                          需求、设计、结构图、验证说明
│  ├─ rtl/                           原始基础 CPU/GPIO RTL
│  ├─ sim/                           基础测试、程序和脚本
│  ├─ reports/                       基础仿真日志、波形、截图
│  ├─ fpga/                          早期 FPGA 阶段边界说明
│  ├─ vivado_project/                基础 GUI 工程
│  └─ refactored_design/             重构 CPU 及后续各独立应用
├─ MiniRISC-16-CPU-main/              早期解压工作副本，保留基础仿真成果
├─ MiniRISC-16-CPU-main.zip           压缩副本，未逐文件比较内容
├─ MiniRISC-16-CPU-main (2).zip        另一压缩副本，不能仅凭名称判断新旧
├─ deliverables/                     最终演示 PPT 和讲解稿
├─ .codex-ppt-build/                 PPT 构建脚本、预览与检查材料
├─ ross-ai-assistant/                AMD Ross 工具/技能官方仓库副本
├─ tools/amd-ross/                   Vivado MCP 程序和冒烟测试脚本
├─ tmp/pdfs/                        文档处理中间材料
├─ -p/                              当前枚举为空的目录
├─ .Xil/、xsim.dir/                  Vivado/XSim 工作缓存
└─ vivado.*、xvlog.*、xelab.pb、xlicdiag.rpt  顶层工具运行残留
```

截至整理时，主工程约 4478 个文件、412 MB；早期副本约 399 个文件、26.8 MB；Ross 约 1304 个文件、33.9 MB。这些数字包含缓存、报告等，不等于源代码规模。主工程根部还保留项目描述、lab1～lab5、Topic 导论、DOC/PPT 模板、重构 ZIP 等原始资料。

**版本管理边界**：`CPU/` 本身不是 Git 仓库；`MiniRISC-16-CPU/.git` 的 HEAD 指向 `main`，origin 为 `https://github.com/miillkk/MiniRISC-16-CPU.git`。本次未联网核对远端，也未判断本地工作树与远端是否一致。顶层 deliverables 与本 README 位于这个嵌套仓库之外。

## 3. 开发过程和版本差异

| 阶段 | 实际实现与目的 | 主要入口 |
|---|---|---|
| 原始规格与功能基线 | 16 位数据、4×16 寄存器、8 位 PC、256×16 指令 ROM；13 个有效 opcode；仅 CMP 更新 Z；GPIO OUT/IN/DIR | `MiniRISC-16-CPU/rtl/`、`docs/design/CPU项目说明_8位GPIO_单周期.md` |
| 原始仿真 | ALU、Controller、Datapath、复位、GPIO、系统六项自检；端到端程序覆盖 16 个 opcode | `sim/tb/`、`reports/simulation/regression-summary.txt` |
| 独立模块化重构 | 拆出 PC、下一 PC MUX、立即数扩展、ALU 操作数 MUX、写回 MUX、状态寄存器；GPIO 三态收进 GPIO 模块 | `refactored_design/rtl/` |
| ZNVC 扩展 | ADDI/ADDR/SUB/CMP 更新 Z/N/C/V；其他指令保持 Flags；不是原版“仅 CMP 更新 Z”的规则 | `refactored_design/rtl/core/status_register.v`、`controller.v` |
| 板级集成 | EES331、100 MHz、LED、拨码、动态数码管与 S1；器件依据实板改为 clg484 | 三个 board 工程及上板指南 |
| 计算器 | 不增乘除 opcode，以汇编循环实现乘除；完整 8 位输入；S1 短按确认、长按复位 | `calculator_system/` |
| 串口贪吃蛇 V1 | CPU 执行游戏程序，新增 LDR/STR 与数据 RAM；UART 显示 8×8 棋盘 | `snake_system/` |
| Runtime / Snake V2 | PC 扩为 10 位、1K×16 可写程序存储器、JMPA、UART Loader、障碍/加速/高分 | `runtime_system/` |
| HDMI 扩展 | Runtime 基础上增加视频时序、帧桥、渲染和 ADV7511 初始化；实板链路待定位 | `hdmi_snake_system/` |
| 展示材料 | 五类指令独立波形、流水灯和计算器静态答辩 | `instruction_waveforms/`、顶层 `deliverables/` |

课件曾涉及多周期结构；后续用户提供的设计 md 确立了当前单周期基线。旧对话中早于该 md 的多周期计划不是现有 RTL 的准确描述。单周期表示取指、译码、寄存器读取、运算、选择写回与下一 PC 在一周期内组合传播，周期末提交状态；GPIO 同步或软件延时循环不改变这一 CPU 组织方式。

各应用保留自己的 RTL 副本，开发时按用户要求隔离新旧工程。它们不是共享一套可任意替换的 CPU 文件；尤其 Flags、PC 宽度、D/E/F opcode 和 I/O 地址在版本间不同。

## 4. 应该打开哪个工程、下载哪个 bit

以下路径均相对于 `MiniRISC-16-CPU/refactored_design/`，基础版本单独注明。

| 用途 | Vivado XPR | bitstream |
|---|---|---|
| 原始 GPIO 基线 | `../vivado_project/MiniRISC16_CPU.xpr` | 此基线不以板级 bit 为交付目标 |
| 重构 CPU / 指令内部分析 | `vivado_project/MiniRISC16_Refactored.xpr` | CPU 分析入口，非独立板级演示 bit |
| 基础板级演示 | `board_vivado_project/MiniRISC16_EES331.xpr` | `reports/board/MiniRISC16_EES331.bit` |
| 全指令板级自检 | `board_isa_vivado_project/MiniRISC16_EES331_ISA_TEST.xpr` | `reports/board_isa/MiniRISC16_EES331_ISA_TEST.bit` |
| 流水灯 | `board_led_vivado_project/MiniRISC16_EES331_LED_CHASER.xpr` | `reports/board_led/MiniRISC16_EES331_LED_CHASER.bit` |
| 计算器 | 独立项目目录完整；当前未在 `vivado_project/` 根部找到文档所列的 `MiniRISC16_Calculator.xpr`，需要时可用项目脚本刷新/重建 GUI 入口 | `calculator_system/reports/board/MiniRISC16_Calculator.bit` |
| 串口贪吃蛇 V1 | `snake_system/vivado_project/MiniRISC16_Snake.xpr` | `snake_system/reports/board/MiniRISC16_Snake.bit` |
| Runtime / Snake V2 | `runtime_system/vivado_project/MiniRISC16_Runtime.xpr` | `runtime_system/reports/board/MiniRISC16_Runtime.bit` |
| HDMI 贪吃蛇 | `hdmi_snake_system/vivado_project/MiniRISC16_HDMISnake.xpr` | `hdmi_snake_system/reports/board/MiniRISC16_HDMISnake.bit` |
| 五类指令波形 | `instruction_waveforms/project/instruction_waveforms_project.xpr` | 无需板级 bit |

### 各项目验证了什么

- **基础板级演示**：LED 自检 A5，数码管显示 `C0DE` 与拨码输入加一；验证 CPU 运行、INP/OUP、地址译码、显示与复位。旧聊天用户已反馈“测试没问题”。
- **ISA 自检**：输入为 `3C` 时，预期 LED=`A5`、数码管=`600D0000`；错误输入可触发 `EB`。指令模型执行 166 条后进入 PASS 循环，覆盖 16 个 opcode。不能把基础演示的一次反馈扩展成所有 ISA 边界用例都有单独实拍。
- **流水灯**：`01→02→04→08→10→20→40→80→01`，约 0.5 秒一步，数码管熄灭；实际由 CPU 执行循环、比较、跳转与端口读写。回卷曾多出 `00`，修复已记录。
- **计算器**：ADD/SUB/AND/OR/XOR/MUL/DIV/CMP；A、B 为 `00～FF`，结果 16 位；最大乘法 `FF×FF=FE01`；SUB 负结果按 16 位回绕，除零有错误显示。普通结果 `AABBrrrr`，除法 `AABBqqrr`。当前完整 8 位版使用 S1 短按确认、长按约 1 秒复位；旧计划的 SW7 确认与 7 位输入已被后续版本替代。
- **串口 Snake**：游戏规则、方向保护、移动、增长、计分与重启由 CPU 汇编程序实现；UART、定时器、显示等是硬件外设。用户在旧聊天确认可运行后，才进入 Runtime 开发。
- **Runtime**：固定 FPGA 硬件后可上传新的 1024 字程序，无需每次重做 bitstream。SW7=1 停 CPU 并进入 Loader，`10AD` 表示 LOAD；SW7=0 运行。旧聊天有“程序没问题但是我看到10ad”和后续“没问题了速度可不可以调低一点”反馈；随后生成了减速版 bit。该反馈证明运行闭环已建立，不等于减速后每一项边界验收都有记录。
- **HDMI**：CPU/游戏、Loader、视频时序和 I²C 单元已有仿真与实现成果；但完整 ADV7511 真实初始化不在已通过仿真的全部覆盖范围内。实板尚无正常 HDMI 画面结论。

## 5. 验证结果和限制

| 版本 | 历史验证证据 | 实现时序记录（100 MHz） | 状态解释 |
|---|---|---|---|
| 原始基线 | 六个 testbench、波形渲染 PASS，Failures=0 | 不以该阶段板级时序为结论 | 基础功能仿真完成 |
| 重构 CPU | 历史 11 项 PASS；CPU 29 次提交，opcode_coverage=ffff | 初期有综合成果 | 后续板级汇总另记 17 个 TB 解析通过，但 xelab 被 MinGW DLL relocation 阻塞，不能写成 17/17 动态通过 |
| 基础板级 | 综合/实现/bit 成功 | WNS +1.513 ns，TNS 0 | 有用户实板通过反馈 |
| ISA 自检 | 模型与实现通过 | WNS +0.928 ns，TNS 0 | 对应独立 bit |
| 流水灯 | 模型与实现通过 | WNS +0.683 ns，TNS 0 | 对应独立 bit |
| 计算器完整 8 位版 | 参考模型 15/15；XSim 9/9 | WNS +0.559 ns，WHS +0.202 ns | 本地汇总仍保留 XPR 刷新与人工验收待办；旧 7 位版 7/7、WNS +0.426 不应混入最新版指标 |
| 串口 Snake | 模型、ROM 等价、XSim 4/4 | WNS +0.192 ns，WHS +0.156 ns | 文件汇总的 NOT RUN 已落后于后续用户运行反馈 |
| Runtime | 模型 13964 条，XSim 6/6 | WNS +0.157 ns，WHS +0.049 ns | 294/1024 程序字，用户有运行反馈 |
| HDMI 游戏 | 历史 XSim 10/10；bitstream 已生成 | WNS +0.073 ns，TNS 0 | 后续诊断轮次又发生 XSim 生成 C 编译错误；历史通过与后来失败必须分开 |

依据：基础 `reports/simulation/regression-summary.txt`；重构 `reports/simulation/regression-summary.txt`；各应用 `reports/verification-summary.txt`；HDMI README、BUG_FIX_LOG 和诊断 STATUS。时序数值属于相应构建，不代表每次重建必然相同。

纯 PL/JTAG 方案的报告保留 `ZPS7-1` 警告；它没有被作为零警告工程宣传。掉电启动、PS7/FSBL/启动镜像属于不同工作范围。当前 bitstream 下载是易失性验证。

## 6. HDMI 当前故障与下一次验证入口

这是扩展线目前最明确的未完成项。旧聊天用户报告：游戏 bit 能运行基本逻辑、Loader 有 `10AD`，但屏幕无反应；外部 5V 已接。第二版总线诊断中，切 SW0=1 后 SCL 指示低，状态位指向 I²C 状态 5；按住 S1 时 SDA/SCL 指示能升高，松开后回到等待状态。

当前合理定位是“第一次 I²C 事务等待 SCL 升高”，尚不能确定 FPGA 输出、IOBUF、ADV7511 或板上线路哪一处是根因。不能直接写成显示器故障或 CPU 游戏逻辑故障。

| 诊断版本 | 相对 `hdmi_snake_system/` 的文件 | 用途与状态 |
|---|---|---|
| 链路隔离版 | `reports/diagnostics/link_only/MiniRISC16_HDMI_LinkDiagnostic.bit` | 不运行 CPU，持续彩条，用于分离视频链路 |
| 总线细节版 | `reports/diagnostics/link_detail/MiniRISC16_HDMI_BusDiagnostic.bit` | SW0 两页显示控制器/I²C 状态；已有用户板测反馈 |
| SCL 驱动观察版 | `reports/diagnostics/link_drive_eco/MiniRISC16_HDMI_SCLDiagnostic.bit` | 最新聊天记录通过已布线 DCP 的 ECO 生成，WNS +4.268 ns、DRC 0 Error；待用户反馈 |

最新 SCL 版 SW0=1：LED7..3 是 I²C 状态；LED2 是 SCL 实测；LED1 是 SDA 实测；LED0 是 FPGA 是否释放 SCL。此 LED0 含义与第二版的 ACK error 不同。**不能混用不同 bit 的 LED 解码。**

SCL 版下一步是观察“已命令释放但仍读低”还是“FPGA 仍在拉低”，再缩小问题范围。第三版成功生成的聊天结论取代此前“第三版尚未生成”的阶段结论；相关 STATUS 保留多轮追加记录，阅读时必须看先后。完整游戏 bit 与诊断 bit 都保留，不应相互覆盖。

## 7. 文件导航：需要什么就从哪里看

### 原始需求、结构图和原版代码

- 需求：`MiniRISC-16-CPU/docs/requirements/`、`项目描述.txt`。
- 权威基础设计：`docs/design/CPU项目说明_8位GPIO_单周期.md`。
- opcode 与控制信号：`docs/design/CONTROL_TABLE.md`。
- 原版层级、端口与单周期路径：`RTL_STRUCTURE_ANALYSIS.md`、`RTL_MODULE_PORTS_BY_HIERARCHY.md`、`RTL_MODULE_BOXES.md`。
- draw.io：`SYSTEM_TOP_LEVEL.drawio`、`SYSTEM_TOP_MODULE_HIERARCHY.drawio`、`SYSTEM_TOP_WITH_DATAPATH_INTERNAL.drawio` 等；这些主要描述原始九模块基线，不直接代表 Runtime/HDMI 的最终结构。
- 原始文件布局：`docs/FILE_LAYOUT.md`。其中列过 courseware/templates，但当前课件和模板也保留在工程根部；应按实际路径找文件。

### 重构与应用源码

`refactored_design/rtl/core/` 内包含 controller、datapath、cpu_core、ALU、register_file、program_counter、next_pc_mux、status_register、zero_extender_8_to_16、alu_operand_mux、writeback_mux。`rtl/` 的其他子目录包含外围和板级模块。

每个 `calculator_system/`、`snake_system/`、`runtime_system/`、`hdmi_snake_system/` 通常自带：

- `rtl/`：该版本的 CPU、存储器、外设和顶层；HDMI 另有视频模块。
- `program/`：ASM、MEM、LST 等软件与机器码。
- `tb/`：单元及系统 testbench。
- `scripts/`、`tools/`：汇编、参考模型、仿真、综合与工程生成；Runtime 另有上传与终端工具。
- `constraints/`：实际板级 XDC。
- `vivado_project/`：GUI 工程。
- `reports/`：simulation、implementation、board、bugs 等验证证据。
- `README.md`、`BOARD_TEST_GUIDE.md`、`BUG_FIX_LOG.md`：功能、操作、问题根因和修复过程。

### 波形和答辩

`instruction_waveforms/` 专门展示指令引发的控制信号、数据通路和时钟沿状态变化，分为 move、arithmetic、logic、branch、io 五类。`output/` 下同名 PNG、WDB、WCFG、VCD 和 simulate 日志分别对应图片、原始波形库、显示配置、通用波形及自检结果。

五张图片已按后续用户要求改为 Vivado 风格并去掉中文；它们是由仿真数据渲染的图，不能统称为 Vivado GUI 原生截图。若需真实 GUI 截图，打开对应 WDB + WCFG；基础 `reports/waveforms/` 另保留命名为 vivado_*_screenshot 的历史界面截图。

顶层 `deliverables/`：

- `MiniRISC16_设计与验证答辩稿_v2.pptx`：当前静态讲解版，共 8 页。
- `MiniRISC16_答辩详细讲解稿.md`：配套原理、架构、ISA、代码、逐页讲法及问答。
- `MiniRISC16_LED_Calculator_Demo_v1.pptx`：较早演示稿。

最新聊天明确不需要现场下载演示；v2 已按静态证据讲解制作。可补流水灯实拍和计算器 `2D170044` 实拍。`.codex-ppt-build/led-calculator-20261017/` 保存构建脚本，`led-calculator-20261017-v2/` 保存新版预览材料；不要按目录后缀假设脚本也全部在 v2 目录中。

## 8. 操作与交付注意点

- 实板 EES331 使用 `xc7z020clg484-1`，100 MHz；早期仿真工程的 clg400 是历史选择，后续已依据板卡资料修正，不是仍缺少器件答案。
- 六位启动拨码组 `SW8=000000` 是用户实测可识别配置；不要与八位用户输入 `SW7..0` 混淆。
- S2/S3 在旧资料核对中属于 PS 复位网络，当前纯 PL 应用不把它们当普通确认键。计算器使用 S1 的短按/长按区分。
- UART 旧实测使用 J8 上方接口、CP2103/COM3；端口号可能随电脑改变。上传工具与游戏终端不可同时占用同一个串口。
- 看 CPU 指令机制，选重构工程的 `tb_cpu_core` 或五类指令工程；看某应用的交互，应选该应用自己的系统 TB。设计顶层不是产生测试激励的仿真顶层。
- 原版回归入口为 `sim/scripts/run_all.ps1`；各独立应用从本目录执行 `scripts/run.ps1 -Task Assemble/Regression/CreateProject/Bitstream`。本次未执行这些命令；具体参数看各自 README。
- 旧环境默认 `F:\vivado\2026.1\Vivado\bin`；可使用脚本支持的 `-VivadoBin` 覆盖。路径在文档中出现不等于当前重新验证安装可用。
- 给别人只下载硬件可提供对应 bit；要检查设计、复现构建应提供整个独立应用目录。单独发 RTL 和 TB 可能缺 MEM、XDC、脚本及波形配置。
- `instruction_waveforms` 使用外层重构 CPU RTL，不是完全自包含包；打包时要保留相对目录或同时提供依赖。
- `.Xil`、`sim_build`、`xsim.dir`、工程 runs/cache、`.jou/.log/.pb`、DMP 等是工具生成物；bugs 下的失败现场则承担可追溯证据作用。本次没有清理任何内容。

## 9. 已回答的问题和真正剩余事项

| 问题 | 现有答案 / 剩余边界 |
|---|---|
| 是否缺板卡信息或 XDC | 后续已有板卡资料、clg484 约束、100 MHz 与成功 bit，早期“等待资料”已经被后续工作解决 |
| 是否从未上板 | 否。基础演示与串口游戏/Runtime 有用户运行反馈；各 bit 的全部人工验收仍需逐项区分 |
| 计算器是否只有 7 位 | 旧版本是；最新版已是 8 位 + S1 确认 |
| Snake 是否由自研 CPU 运算 | 是，规则运行于 ASM/MEM，CPU 经 LDR/STR 和 I/O 操作数据与外设；HDMI 渲染由专门硬件执行 |
| 是否所有测试都已当前通过 | 否。历史 PASS、后续 MinGW/XSim 阻塞、工具崩溃和成功重试并存，需按构建版本读报告 |
| HDMI 是否完成 | 已有游戏 bit、多个诊断 bit，但板上显示无正常画面；最新待收集 SCL 驱动观察版反馈 |
| Vivado 是否一定损坏 | 无法确认。历史有间歇访问冲突和库加载异常，也有同机成功构建；根因不能仅凭聊天推断为系统版本或安装损坏 |
| 计算器项目是否还在 | 在，`refactored_design/calculator_system/` 是完整独立项目，RTL、程序、testbench、约束、脚本、报告、bitstream 和 Vivado 生成目录均存在。当前只是在 `vivado_project/` 根部没有找到 README 所列的 `.xpr` 文件；不能把这个情况说成“计算器项目不在” |
| 哪个目录是主要开发线 | 文件和聊天均指向 `MiniRISC-16-CPU/refactored_design`；`-main` 是早期工作副本，ZIP 未逐项比对，不擅自删除 |

建议后续工作顺序：先完成 HDMI 最新诊断的实板观测；按最终使用版本补实板照片与验收表；若继续计算器交付，核对完整八位版 XPR 与当前源码列表；答辩以 v2 PPT、讲解稿和五类指令波形为入口。16×16 地图、单步/寄存器监控、QSPI/SD 启动等曾出现在讨论或规划中，本文不将其列为现成成果。

## 10. 聊天记录来源和整理范围

本次通过对话接口读取以下 9 条 CPU 相关聊天，并对有更早内容的记录逐页读取至接口 `hasMore=false`；不依赖这些聊天是否显示在项目侧栏中：

| 聊天 ID | 主题 / 用途 |
|---|---|
| `01a085d5-29b3-78c0-b644-b75db7e6cb2c` | 初始资料、设计 md、基础实现、许可证、仿真与波形 |
| `01a09f14-488a-72e0-abc7-052178d8a36e` | Git 上传、结构分析、端口和模块框图 |
| `01a0a3b7-af27-7112-8df7-c19dca40394c` | 相关分支/延续记录，含结构与数据通路分析 |
| `01a0c234-04aa-72a2-8bb4-9ca5e3df4c75` | draw.io、层级、连接、datapath 内部展示 |
| `01a0c309-0db2-7201-93dc-8b3564a947b1` | 独立重构、ZNVC、上板、ISA、流水灯、计算器与八位输入改版 |
| `01a14289-1cd9-7e00-bdd5-62a4a8f3e11d` | 应用扩展、Snake、Runtime、HDMI 和最新诊断 |
| `01a148fe-1405-7c43-8825-77690a57b2c6` | 多项目汇总、演示材料和五类指令聚焦波形 |
| `01a149cf-51a6-75d3-af6d-541fbb504045` | 静态答辩 PPT v2 与详细讲解稿 |
| `01a14828-b7d5-7703-ae08-18ac943fa985` | Ross 技能、Vivado MCP 下载部署与历史冒烟测试 |

部分分支包含重复前史，不能把重复记录计作多次独立测试。读取接口可能截断单项长输出；本次主要核对用户文本、最终答复、文件路径和现存报告，未逐字复核每条工具输出。未读取已删除、不可见或未被本次近期列表暴露的其他旧聊天，因此不宣称覆盖账户里的所有历史。

Ross 旧聊天记录了插件和 Vivado MCP 成功部署、离线知识库未部署。当前 `tools/amd-ross` 有可执行文件和冒烟脚本，但这不等于本会话再次验证了全局 MCP 注册或当前启用状态；本次没有修改或检查全局配置。

本总览修正了之前仅看基础文件得出的不完整阶段判断。工程目前的核心问题是版本与证据分散，而非整体文件不可访问或从未完成板级工作。
