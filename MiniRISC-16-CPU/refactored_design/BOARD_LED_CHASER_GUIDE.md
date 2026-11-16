# EES331 CPU 流水灯测试指南

## 1. 功能

CPU 通过执行 ROM 中的 MiniRISC-16 指令控制 8 个板载 LED，循环显示：

```text
01 → 02 → 04 → 08 → 10 → 20 → 40 → 80 → 01
```

每一步约 0.5 秒，完整循环约 4 秒。程序使用 MOVI、OUP、SUB、JZ、JUMP、INP、ADDR 和 CMP，既是显示效果，也验证 CPU 持续执行、循环、分支、I/O 读写和算术功能。

数码管在这个测试中保持关闭。普通的 8 个输入拨码不参与测试。

## 2. 文件

- 指令程序：`sim/programs/board_led_chaser.mem`
- testbench：`sim/tb/tb_board_led_chaser.v`
- 独立 Vivado 工程：`board_led_vivado_project/MiniRISC16_EES331_LED_CHASER.xpr`
- 可直接下载的 bitstream：`reports/board_led/MiniRISC16_EES331_LED_CHASER.bit`
- 实现报告：`reports/board_led/`

## 3. 下载步骤

1. 保持实测可用的启动配置 `SW8=000000`。
2. 开发板上电，确认 D18 常亮。
3. 在 Vivado 打开 Hardware Manager。
4. 选择 `Open Target → Auto Connect`。
5. 确认能看到 `xc7z020`。
6. 右键 `xc7z020`，选择 `Program Device`。
7. Bitstream file 选择 `reports/board_led/MiniRISC16_EES331_LED_CHASER.bit`。
8. Debug probes file 留空。
9. 点击 `Program`。
10. 下载成功后按住 S1 约 0.5 秒，再松开。

## 4. 预期现象

松开 S1 后：

1. LED0 首先点亮，LED 值为 `01`。
2. 约 0.5 秒后移动到下一位，LED 值为 `02`。
3. 继续依次变为 `04、08、10、20、40、80`。
4. `80` 后直接回到 `01`，中间不应出现持续约 0.5 秒的全灭状态。
5. 任意时刻按下 S1，LED 应清零；松开后重新从 `01` 开始。
6. 数码管保持熄灭，这是正常现象。

板上 LED 的物理排列方向可能使视觉效果表现为从左向右或从右向左，但逻辑值顺序必须是上述序列。

## 5. 观察记录

建议录制至少 8 秒视频，视频应包含两个完整循环。检查：

- 每次只有一个 LED 点亮。
- 移动速度基本均匀。
- `80→01` 连续回卷，没有额外全灭节拍。
- 按 S1 后能重新从第一位开始。

## 6. 修改速度

程序使用三层 `0xFF` 倒计数延时。在 `board_led_chaser.mem` 中：

```text
03: 04FF  // 外层计数
04: 08FF  // 中层计数
05: 00FF  // 内层计数
```

三层均为 `FF` 时，每步约 0.5 秒。改变这些立即数可以改变速度，但延时近似与三个计数值的乘积成正比：

- 数值减小：流水更快。
- 数值增大：流水更慢。
- 8 位立即数最大为 `FF`，当前设置已经使用最大三层计数。

修改 `.mem` 后必须重新生成 bitstream，不能继续下载旧文件。

## 7. 重新生成

在 `MiniRISC-16-CPU` 根目录执行：

```powershell
.\refactored_design\sim\scripts\run_synthesis.ps1 -Task BoardLedProject -VivadoBin "F:\vivado\2026.1\Vivado\bin"
.\refactored_design\sim\scripts\run_synthesis.ps1 -Task BoardLedBitstream -VivadoBin "F:\vivado\2026.1\Vivado\bin"
```

## 8. 当前检查结果

- 独立指令模型得到 `01→02→04→08→10→20→40→80→01`。
- `xvlog` 成功解析 RTL 和 `tb_board_led_chaser.v`。
- Vivado 综合、布局布线和 bitstream 生成成功。
- 0 Error，0 未布通网络。
- 100 MHz 时序满足：WNS=`+0.683 ns`、TNS=`0.000 ns`。
- 资源：239 LUT、176 Register、42 bonded IOB、1 BUFG。
- DRC 仅保留纯 PL/JTAG 方案已知的 `ZPS7-1` 警告。
- BUG-010 记录并修复了 `80` 回卷时可能插入 `00` 的边界问题。
- 当前机器的 XSim 动态运行仍受 BUG-006 的 Vivado MinGW 环境问题阻塞，不声明虚假的 XSim PASS。
