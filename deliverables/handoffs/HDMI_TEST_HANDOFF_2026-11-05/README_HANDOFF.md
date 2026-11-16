# EES331 HDMI 故障诊断交接说明

## 1. 交接目标

本包用于继续定位 EES331 板卡上 ADV7511 HDMI 输出无画面的问题。CPU、贪吃蛇程序、UART 和数码管此前均可工作；当前问题集中在 FPGA 与 ADV7511 之间的 I2C 配置链路，而不是 CPU 算力不足。

目标器件：`xc7z020clg484-1`，Vivado 版本：2026.1。

板级关键信号：

| 信号 | FPGA 管脚 | 说明 |
|---|---|---|
| `clk_100mhz` | M19 | 100 MHz 时钟 |
| `resetn` | L18 | S1，低有效 |
| HDMI I2C SCL | AB10 | ADV7511 配置时钟 |
| HDMI I2C SDA | AB9 | ADV7511 配置数据 |

ADV7511 的 7 位 I2C 地址为 `0x39`。板卡原理图显示 SCL/SDA 分别通过 R110/R140（2.2 kΩ）上拉到 VADJ。原始依据在 `board_reference/EES331_UserManual_v1.0_1220.pdf`。

## 2. 当前最重要结论

最后一次已完成的独立电气测试使用 `bitstreams/05_i2c_electrical.bit`：

- FPGA 每 0.5 秒主动拉低/释放 SCL。
- FPGA 始终释放 SDA。
- LED3..0 显示 `{SCL拉低命令, SDA实际电平, SCL实际电平, SCL释放命令}`。
- 正常预期在 `0111` 与 `1100` 间交替。
- 实板实际观察为 `0111` 与 `1000` 间交替。

解释：

- `0111` 证明释放状态下 SCL 和 SDA 都能上升，SCL FPGA 管脚不是永久失效或永久短路到地。
- `1000` 表明 FPGA 拉低 SCL 时，SDA 也被读为低；但该测试从未主动拉低 SDA。
- 当前最可疑的是 SCL/SDA 板级耦合或短接、ADV7511 异常驱动 SDA，或器件仍停留在异常 I2C 总线状态。
- 仅凭这一组结果还不能断言板卡物理损坏；需要完成第 6 节的反向交叉测试。

## 3. 已完成测试的时间顺序

### 3.1 基准完整系统

文件：`bitstreams/00_baseline_HDMISnake.bit`

- 数码管能够显示 `10AD`，说明 FPGA、时钟、复位和主要 PL 逻辑已运行。
- LED/数码管有响应，但 HDMI 显示器无信号。
- 同一显示器、同一 HDMI 线、同一输入口连接电脑时可以工作。

### 3.2 HDMI-only 链路测试

文件：`bitstreams/01_link_only.bit`

- 去掉 CPU 和游戏，只持续输出彩条并初始化 ADV7511。
- 屏幕仍无信号。
- 初始实板观察只有 L5、L2 亮，对应控制器停在第一次 I2C 读取等待状态。

### 3.3 详细总线状态测试

文件：`bitstreams/02_bus_detail.bit`

SW0=1 时：LED7..3 为 I2C 状态，L2=SCL，L1=SDA，L0=ACK 错误。

实板观察：L5、L3 亮，L2 灭，即控制器状态 5（`S_TX_HIGH`），但采样 SCL 为低。按住 S1 时 SCL/SDA 可上升，松开后再次停在状态 5。

### 3.4 FPGA SCL 三态控制测试

文件：`bitstreams/03_scl_drive_eco.bit`

L0 显示 SCL IOBUF 三态控制（1=FPGA 已释放），L2 显示实际 SCL。

实板观察：状态 5 时 L0=1、L2=0，说明 FPGA 控制逻辑已经要求释放 SCL，但管脚仍未上升。

### 3.5 内部上拉测试

文件：`bitstreams/04_internal_pullup_eco.bit`

在 SCL/SDA IOB 中增加弱上拉。实板结果与 3.4 相同。由于板上已有更强的 2.2 kΩ 外部上拉，这一结果不能单独证明外部上拉损坏。

### 3.6 独立电气测试

文件：`bitstreams/05_i2c_electrical.bit`

该 bit 不包含 CPU、游戏、视频输出或 I2C 事务。屏幕无画面属于正常现象。静态验证：

- 55/55 可布线网络完全布通，路由错误 0。
- DRC 0 Error。
- WNS `+5.601 ns`，TNS `0`，100 MHz 时序通过。
- 实板结果：`0111` / `1000` 交替；预期应为 `0111` / `1100`。

详细说明见 `docs/I2C_ELECTRICAL_TEST.md`。

## 4. 文件结构

```text
HDMI_TEST_HANDOFF_2026-11-05/
├─ README_HANDOFF.md                  # 本文件
├─ bitstreams/                        # 已生成、可直接下载的 bit
├─ source/
│  ├─ rtl/                            # 完整 HDMI Snake RTL 副本
│  ├─ constraints/                    # 板级 XDC 和 CDC 约束
│  ├─ scripts/                        # 构建、诊断和 ECO Tcl/PowerShell
│  ├─ tb/                             # 仿真 testbench
│  └─ program/                        # CPU 程序
├─ evidence/                          # 每个诊断版的 DCP/DRC/时序/路由报告
├─ docs/                              # 原 README、测试指南、Bug 日志和状态记录
├─ board_reference/                   # EES331 用户手册
└─ unfinished_next_test/              # 下一步交叉测试源码，尚无 bit
```

## 5. 下载 bit 的方法

无需打开 XPR：

1. Vivado → Open Hardware Manager。
2. Open target / Auto Connect。
3. 选择 `xc7z020_1` → Program Device。
4. 选择 `bitstreams/` 下对应 `.bit`。
5. Program 后按下并松开 S1。

注意：`01`～`05` 均为诊断图像，不应作为最终贪吃蛇系统交付。

## 6. 下一步必须完成：SCL/SDA 反向交叉测试

源码已经准备好，但上一轮在启动 Vivado 构建时被中断，因此 **尚未生成 bitstream**：

- `unfinished_next_test/hdmi_i2c_cross_test_top.v`
- `unfinished_next_test/build_hdmi_i2c_cross_test.tcl`
- `unfinished_next_test/route_hdmi_i2c_cross_test.tcl`

完整副本也在 `source/rtl/top/` 和 `source/scripts/`。

进入本包的 `source/` 目录即可运行；该目录已经保留脚本所需的原工程相对路径：

```powershell
cd .\source
& 'F:\vivado\2026.1\Vivado\bin\vivado.bat' -mode batch -source .\scripts\build_hdmi_i2c_cross_test.tcl
& 'F:\vivado\2026.1\Vivado\bin\vivado.bat' -mode batch -source .\scripts\route_hdmi_i2c_cross_test.tcl
```

生成目标：

```text
reports/diagnostics/i2c_cross_test/MiniRISC16_HDMI_I2C_CrossTest.bit
```

交叉测试每 0.5 秒切换一个阶段。LED7..6 为阶段号，LED3..0 为：

```text
{SDA实际电平, SDA释放命令, SCL实际电平, SCL释放命令}
```

正常预期：

| LED7..6 | 操作 | LED3..0 正常值 |
|---:|---|---:|
| `00` | 两线都释放 | `1111` |
| `01` | 只拉低 SCL | `1100` |
| `10` | 两线都释放 | `1111` |
| `11` | 只拉低 SDA | `0011` |

判定：

- 阶段 `01` 若为 `0100`：拉低 SCL 时 SDA 也下降。
- 阶段 `11` 若为 `0001`：拉低 SDA 时 SCL 也下降。
- 两种现象都出现：高度怀疑 SCL/SDA 板级短接或强耦合。
- 只有阶段 `01` 异常、阶段 `11` 正常：更像 ADV7511/总线状态在 SCL 动作时驱动 SDA，而不是简单的两线短接。
- 两个方向都正常：需回到 `i2c_master.v`、`adv7511_controller.v` 和 ADV7511 供电/复位/地址响应继续排查。

## 7. Vivado 2026.1 已知环境问题

本机 Vivado 许可证有效至 2027-09-03，问题不是许可证不足。Vivado 2026.1 曾间歇出现：

- `EXCEPTION_ACCESS_VIOLATION`
- `ProcHandler::InvalidParam`
- `Device 21-9324 Out of range request for wires in node template`
- DCP binary timing archive 恢复失败

这些错误在只有少量寄存器的最小设计上也出现过，因此与 CPU/HDMI RTL 无直接因果关系。当前稳定规避方式：

1. `general.maxThreads=1`。
2. 综合、优化、布局后分别保存 DCP。
3. 从 placed DCP 重开后执行 `reset_timing` 并重新读 XDC。
4. 使用 `route_design -directive Quick`。
5. 在生成报告前先保存 routed DCP 和 bitstream。

若工具崩溃，可重跑同一脚本；只有 Bitgen、DRC 和 route status 均通过后才使用生成的 bit。

## 8. 建议的硬件检查

若交叉测试确认两线相互影响：

1. 断电后用万用表电阻/蜂鸣档测 AB10 网络与 AB9 网络之间是否短接。
2. 分别检查 R110、R140 两端及 VADJ 是否正常。
3. 检查 ADV7511 对应 SCL/SDA 引脚附近是否有焊锡桥或污染。
4. 上电后用示波器或逻辑分析仪同时观察 SCL/SDA；不要只看 LED 平均状态。
5. 若可以隔离 ADV7511 或上拉电阻，再重复独立电气测试以区分 FPGA 侧与外设侧。

不要在上电状态使用蜂鸣档，也不要让外部仪器向 FPGA/ADV7511 引脚注入超过板卡 I/O 电压的信号。

