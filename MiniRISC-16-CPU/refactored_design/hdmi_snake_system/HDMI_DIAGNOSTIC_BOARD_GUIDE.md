# HDMI 链路隔离诊断上板步骤

此版只运行 HDMI 彩条、时钟和 ADV7511 初始化，**不运行 CPU/贪吃蛇**。不会覆盖原游戏 bitstream 文件；下载到 FPGA 后会暂时替代当前运行的设计，重新下载原 `.bit` 即可恢复。

## 下载

1. 保持此前成功的外部 5V 供电、SW8=`000000`、J3 JTAG 连接。
2. 使用已经在电脑上验证过的同一根 HDMI 线和显示器同一个输入口，接到 EES331 HDMI 接口，并在显示器菜单手动选中该输入口。
3. Vivado **Open Hardware Manager → Open Target → Auto Connect**，右键 `xc7z020` → **Program Device**。
4. 选择下列**第二版总线诊断 bitstream**，不要误选原游戏或第一版诊断 `.bit`：

```text
C:\Users\xieke\Desktop\CPU\MiniRISC-16-CPU\refactored_design\hdmi_snake_system\reports\diagnostics\link_detail\MiniRISC16_HDMI_BusDiagnostic.bit
```

5. Program 完成后按下并松开 S1，等待 3 秒。数码管全灭是此诊断版的预期行为；SW6、SW7 不起作用。若链路正常，屏幕应显示彩条和 `HDMI TEST`。
6. **先设 SW0=0**，确认是否仍只有 L5 和 L2 亮；然后**拨 SW0=1，不需复位**，记录 LED7～LED0 的完整亮灭序列。最好拍摄 5 秒短视频，以免错过闪烁。

## 读取 LED

SW0=0 时，请记录 **LED7 到 LED0 的完整亮灭序列**，例如 `00100100`；最好拍一张能看清板上 LED 编号的照片。此版与原游戏版的 LED 含义不同：

| LED | 含义 |
|---|---|
| LED7..4 | ADV7511 控制器状态，按二进制读 0～9 |
| LED3 | 读到显示器热插拔 HPD |
| LED2 | I²C 主机正忙 |
| LED1 | 初始化故障 |
| LED0 | HDMI ready |

控制器状态码：`0` 启动等待；`1/2` 读热插拔状态；`3` 重试等待；`4/5` 写配置寄存器；`6` 等 PLL 稳定；`7/8` 读 PLL；`9` 就绪后周期检查。状态可能短暂跳变，优先记录等待 3 秒后的稳定值；必要时拍 5 秒视频。

- LED3=0、状态在 `3` 附近且 LED1=0：芯片可能应答了 I²C，但未报告 HPD。
- 状态长期为 `2` 且 LED2=1：I²C 事务可能停滞，需检查 SCL/SDA 或控制器。
- LED1=1：I²C NACK 或 PLL 检查失败；需要结合状态码区分。
- LED0=1 但仍无画面：初始化已完成，下一步检查视频时钟、格式或输出通道。

上述仅用于定位，不把实板现象预先标记为通过。

## SW0=1：I²C 细节页

| LED | 含义 |
|---|---|
| LED7..3 | I²C 主机内部状态，5 位二进制，范围 0～22 |
| LED2 | SCL 引脚实际读到的电平，亮=高 |
| LED1 | SDA 引脚实际读到的电平，亮=高 |
| LED0 | 本次事务曾收到 NACK |

重点观察的等待状态：`5`（发送位等待 SCL 变高）、`8`（应答等待 SCL）、`15`（读位等待 SCL）、`18`（NACK 时钟等待 SCL）、`21`（停止条件等待 SCL）。如果 LED7..3 长期保持这些状态之一且 LED2=0，说明 SCL 未能升高；仍需进一步区分是外部线路被拉低，还是 FPGA 自身输出异常。不要带电飞线或短接 I²C 引脚。

第二版诊断已完成静态实现检查：WNS `+4.268 ns`、TNS `0`、DRC `0 Error`；其实板测试尚未完成。构建详情和 SHA-256 见 `reports/diagnostics/STATUS.md`。
