# EES331 上板测试指南

## 1. 本阶段的上板方案

本方案使用 EES331 板载资源完成可见、可交互的 CPU 验证：

- 8 位动态数码管：显示 32 位十六进制数据，是主要结果显示设备。
- 8 个 LED：显示 CPU 自检状态。
- 8 个拨码开关：作为 CPU 的 8 位输入。
- S1：CPU 复位按键。
- 100 MHz PL 晶振：CPU 和所有板级逻辑的唯一时钟。

HDMI、音频、DAC 和 PS 端外设不属于本次最小上板闭环。CPU Core 的接口、指令集和内部实现保持不变；新增内容只位于板级顶层和外设层。

## 2. 板级层级

```text
board_top
├─ reset_conditioner
├─ instruction_memory
├─ cpu_core                       # 原 CPU Core，不改接口
│  ├─ controller
│  └─ datapath
├─ io_interconnect                # 8 位地址译码和读数据选择
├─ seven_segment8
│  └─ hex_to_7seg
├─ led8
└─ switch8                        # 两级同步
```

`system_top` 仍作为原来的通用 GPIO 顶层保留；EES331 上板时必须选择 `board_top`，不能选择 `system_top`。

## 3. I/O 地址映射

| 地址 | 方向 | 功能 |
|---|---|---|
| `0x20` | 读/写 | 数码管低 4 位，16 位十六进制数 |
| `0x21` | 读/写 | 数码管高 4 位，16 位十六进制数 |
| `0x22` | 读/写 | 数码管控制；bit 0 为总使能，bits 15:8 为 8 位小数点掩码 |
| `0x30` | 读/写 | LED7..LED0，使用写数据低 8 位 |
| `0x31` | 读 | SW7..SW0，同步后的输入值位于低 8 位 |

CPU 使用现有 `INP` 和 `OUP` 指令访问这些地址，不需要增加新指令。

## 4. 数码管驱动约定

EES331 使用共阴极数码管。板卡位选由 2N5551 晶体管驱动，因此本设计采用：

- 段选高有效。
- 位选高有效。
- `seg_low[7:0] = {DP,G,F,E,D,C,B,A}`，驱动 DK0-DK3。
- `seg_high[7:0] = {DP,G,F,E,D,C,B,A}`，驱动 DK4-DK7。
- `digit_enable[0]` 到 `[7]` 对应 LED_BIT1 到 LED_BIT8。
- DK0 显示最低有效十六进制位，DK7 显示最高有效十六进制位。

100 MHz 时钟下默认 `SCAN_DIVIDER=100000`，每 1 ms 换一位，完整 8 位刷新率约 125 Hz。换位时插入一个时钟周期的消隐，降低鬼影。不创建额外的分频时钟，所有逻辑仍使用 100 MHz 主时钟和时钟使能。

## 5. EES331 管脚与电气约束

目标器件必须是 `xc7z020clg484-1`。不要使用旧工程中的 `xc7z020clg400-1` 设置，也不要把为其他封装生成的 bitstream 下载到本板。

| 功能 | FPGA 管脚 |
|---|---|
| 100 MHz PL 时钟 | M19 |
| S1 低有效复位 | L18 |
| SW0..SW7 | AB6, Y4, AA4, R6, T6, T4, U4, V5 |
| LED0..LED7 | V4, U6, U5, V7, W7, W6, W5, U7 |
| LED0_CA..DP | R21, P20, P21, N15, P15, P17, P18, T16 |
| LED1_CA..DP | T17, R19, T19, R18, T18, P16, R16, R15 |
| LED_BIT1..8 | M20, N19, N20, M21, M22, N22, P22, R20 |

所有本次使用的 PL I/O 均约束为 `LVCMOS33`。完整约束见 `constraints/EES331.xdc`。

## 6. 演示程序的预期行为

`sim/programs/board_demo.mem` 执行以下流程：

1. LED 写入 `0x55`，表示 CPU 已开始运行。该状态持续时间很短，肉眼通常看不到。
2. CPU 通过 8 次加法构造 `0xC0DE`，写入数码管高 4 位。
3. 写 `0x0001` 到显示控制寄存器，打开显示。
4. 执行 `5 + 3`，再用 `CMP` 和 `JZ` 检查结果是否为 8。
5. 自检通过时 LED 显示 `0xA5`；失败时显示 `0xFF` 并停在错误循环。
6. 进入交互循环：读取拨码开关，执行 `开关值 + 1`，把 16 位结果写到数码管低 4 位。

例如：

| SW7..SW0 | 数码管期望值 | LED |
|---|---|---|
| `0x00` | `C0DE0001` | `A5` |
| `0x01` | `C0DE0002` | `A5` |
| `0x0F` | `C0DE0010` | `A5` |
| `0x7F` | `C0DE0080` | `A5` |
| `0xFF` | `C0DE0100` | `A5` |

拨码经过两级同步，改变后只需几十纳秒即可更新；肉眼观察等同于立即更新。

## 7. 上板前检查

1. 核对板上主芯片丝印确实为 `XC7Z020-1CLG484` 或等价的 `xc7z020clg484-1` 标识。如果不同，停止下载并重新核对板卡版本。
2. 使用 EES331 板载下载器时，将启动配置 SW8 设置为 `000001`：手册定义向上/ON 为 0，向下为 1。
3. 若使用外部 JTAG，SW8 设置为 `000000`。
4. 仅驱动 LED、拨码和数码管时可使用 J3 USB 供电；如果连接其他大负载外设，改用外部 5 V 供电并按板上丝印调整供电跳线。
5. 上电后确认 D18 电源灯常亮。
6. 不要同时由 USB 和外部 5 V 以错误跳线方式供电。

## 8. 使用现成 Vivado 工程上板

1. 打开 `board_vivado_project/MiniRISC16_EES331.xpr`。
2. 在 Project Settings -> General 中确认 Part 为 `xc7z020clg484-1`。
3. 在 Sources 中确认：
   - Design Sources 顶层是 `board_top`。
   - Constraints 中启用了 `EES331.xdc`。
   - `board_demo.mem` 在源文件中，并通过 `INIT_FILE` 绑定到指令存储器。
4. 依次运行 Run Synthesis、Run Implementation、Generate Bitstream。
5. 检查 Messages 中不得出现 Error；Timing Summary 必须显示 timing constraints met。
6. 打开 Hardware Manager，选择 Open Target -> Auto Connect。
7. 选择检测到的 `xc7z020` 设备，执行 Program Device。
8. 选择生成的 `reports/board/MiniRISC16_EES331.bit`，点击 Program。
9. 下载完成后按住 S1 约 0.5 秒再松开，确保 CPU 从地址 0 重新启动。

本设计已生成一个可用 bitstream，但在更改 RTL、XDC 或 `board_demo.mem` 后必须重新综合、实现并生成 bitstream。

## 9. 使用脚本重新生成

在 `MiniRISC-16-CPU` 根目录打开 PowerShell：

```powershell
# 创建/刷新板级 Vivado 工程
.\refactored_design\sim\scripts\run_synthesis.ps1 -Task BoardProject

# 只做带 XDC 的板级综合
.\refactored_design\sim\scripts\run_synthesis.ps1 -Task BoardSynthesis

# 综合、布局布线、DRC、时序并生成 bitstream
.\refactored_design\sim\scripts\run_synthesis.ps1 -Task BoardBitstream
```

如果脚本未自动找到 Vivado，可追加：

```powershell
-VivadoBin "F:\vivado\2026.1\Vivado\bin"
```

## 10. 分阶段实板验证

### 阶段 A：下载链路和复位

1. Hardware Manager 应识别到 `xc7z020`。
2. 下载 bitstream 后，按下 S1 时 LED 和数码管应熄灭。
3. 松开 S1 后，LED 应恢复为 `A5`，数码管恢复显示。

如果按键行为相反，先检查是否误用了 PS 复位键；本设计使用的是 PL 按键 S1/L18。

### 阶段 B：CPU 自检和 LED

1. 松开复位后观察 8 个 LED。
2. `A5`（二进制 `1010_0101`）表示 MOVI、ADDI、CMP、JZ 和 OUP 组成的最小闭环通过。
3. `FF` 表示自检失败，CPU 已停在错误循环。
4. 全灭通常表示时钟、复位、顶层、ROM 初始化或下载步骤有问题。

### 阶段 C：动态数码管

1. 先把 SW0-SW7 全部拨到逻辑 0。
2. 期望显示 `C0DE0001`，无小数点。
3. 数码管应稳定、无明显闪烁；手机拍摄可能出现扫描条纹，这是动态扫描和相机快门的正常拍频现象。
4. 如果只有部分位亮，核对 LED_BIT1-8 管脚。
5. 如果位正确但字符错误，核对 A-G 段管脚和高有效逻辑。

### 阶段 D：拨码输入和 CPU 运算

依次测试 `00`、`01`、`0F`、`7F`、`FF`，对照第 6 节表格。这个步骤同时验证：

- 拨码物理管脚。
- 两级输入同步。
- `INP` 指令。
- 16 位加法和进位。
- `OUP` 指令。
- I/O 地址译码。
- 数码管寄存器和扫描驱动。

## 11. 结果判定

上板通过必须同时满足：

- LED 稳定显示 `A5`。
- S1 能清零并重新启动系统。
- 数码管高 4 位稳定显示 `C0DE`。
- 五组拨码输入均得到正确的“输入 + 1”结果。
- 没有异常发热、随机闪烁或下载后失控。

建议拍摄或保存以下证据：

- Vivado Program Device 成功界面。
- Timing Summary 中 WNS/TNS 截图。
- LED=`A5` 的板卡照片。
- 拨码 `0F`、显示 `C0DE0010` 的照片。
- 拨码 `FF`、显示 `C0DE0100` 的照片。
- 按下和松开 S1 的短视频。

## 12. 常见问题

### Hardware Manager 找不到器件

- 检查 D18、电源开关和供电跳线。
- 检查 J3 USB 数据线是否支持数据，不是仅充电线。
- 检查 SW8 启动配置和 Xilinx Cable Driver。
- 重新执行 Open Target -> Auto Connect。

### LED 和数码管全灭

- 确认顶层为 `board_top`，不是 `system_top`。
- 确认器件为 `xc7z020clg484-1`。
- 确认 `board_demo.mem` 已加入工程并绑定 `INIT_FILE`。
- 检查 S1/L18 是否一直为低。
- 检查 100 MHz M19 时钟约束。

### LED 为 A5，但数码管不亮

- CPU、ROM 和 LED 通路已工作，重点检查 `seg_low`、`seg_high`、`digit_enable` 和 XDC。
- 本板段选、位选均按高有效设计，不要直接把常见的低有效七段管代码复制进来。

### 数字顺序左右颠倒

这表示板上 DK0-DK7 的实际视觉顺序与预期相反。先记录现象，不要改物理管脚；在 `seven_segment8.v` 中交换 `scan_index` 对应的半字节顺序后重新生成 bitstream。

### 显示闪烁或亮度不合适

- 默认每位 1 ms、整屏约 125 Hz。
- 减小 `SCAN_DIVIDER` 可提高刷新率，增大则降低刷新率。
- 推荐保持整屏刷新率在约 100-200 Hz 范围。

### Vivado 报 ZPS7-1

当前是纯 PL、JTAG 易失性验证，不实例化 Zynq PS，Vivado 会给出 `ZPS7-1: PS7 block required` 警告。它不影响本次 bitstream 的生成和 JTAG 下载。若后续要求从 QSPI/SD 独立启动，则必须增加 PS7 配置、FSBL 和启动镜像流程，不能直接把本次 JTAG 步骤当作掉电保存方案。

### 修改程序后显示仍是旧结果

`board_demo.mem` 被综合进分布式 ROM。修改后要重新运行 BoardBitstream；只重新 Program 旧 `.bit` 不会更新程序。

## 13. 当前自动检查结果

- `xc7z020clg484-1` 综合通过。
- 实现后使用 218 LUT、144 个寄存器、42 个 IOB 和 1 个 BUFG。
- 100 MHz 时序收敛：WNS `+1.513 ns`、TNS `0.000 ns`。
- 布线完成：0 未布通网络。
- bitstream 生成成功。
- DRC 仅保留纯 PL 设计的 `ZPS7-1` 警告。
- 当前机器的 XSim 动态回归被 Vivado 自带 MinGW 的 Windows DLL 重定位问题阻塞；`xvlog` 已解析全部 15 个 testbench 和 RTL，详细证据见 `BUG_FIX_LOG.md` 的 BUG-006。
