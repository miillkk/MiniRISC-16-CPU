# EES331 HDMI 贪吃蛇上板步骤

## 0. 上板前确认

1. 开发板器件必须是 `xc7z020clg484-1`。
2. bitstream 必须来自本目录：`reports\board\MiniRISC16_HDMISnake.bit`。
3. 已验证的 bitstream 已在该路径。只有修改 RTL、程序或约束后才需要在本目录重建：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\run.ps1" -Task Bitstream
```

4. 只有命令结尾出现 `HDMI SNAKE BITSTREAM PASS`，并且实现报告中 WNS≥0、DRC=0 Error，才下载到板上。

## 1. 连接显示器、JTAG 和串口

先关闭/停止 Vivado 下载操作，然后按以下方式连接：

1. **J3 → 电脑**：保持此前已验证的 JTAG/PS-UART USB 数据线连接，用于 Vivado Hardware Manager 识别 FPGA。
2. **J8 的 CP2103 USB-UART → 电脑**：使用能够传输数据的 USB 线连接。当前电脑识别为 **COM3**；该口用于 W/A/S/D 控制和上传程序。
3. **开发板 HDMI OUT → 显示器 HDMI IN**：使用普通标准 HDMI 线，不是 USB 转 HDMI 线，也不需要另外飞线连接 FPGA 管脚。
4. 给显示器上电，在显示器菜单中手动选择实际插入的 HDMI 输入源，例如 HDMI1。
5. 按板卡原来已经成功的供电方式给板卡上电，启动配置拨码保持 `SW8=000000`。

板载 ADV7511 已经连接 FPGA 的 16 位视频总线、像素时钟、HSYNC、VSYNC、DE 和 I²C；显示器只需要一根 HDMI 线。

## 2. 下载 bitstream

1. 打开 Vivado。
2. 点击 **Open Hardware Manager**。
3. 点击 **Open Target → Auto Connect**。
4. 应看到 `xc7z020_1`；若没有，先检查 J3 数据线、板卡电源和 `SW8=000000`。
5. 右键器件选择 **Program Device**。
6. Bitstream file 选择：

```text
C:\Users\xieke\Desktop\CPU\MiniRISC-16-CPU\refactored_design\hdmi_snake_system\reports\board\MiniRISC16_HDMISnake.bit
```

7. 点击 **Program**，等待完成。

## 3. 先验证 HDMI 链路

下载前/下载后先设置：

```text
SW7 = 0   运行内置程序
SW6 = 1   强制 HDMI 彩条
SW2 = 0   不暂停
SW1..0 = 00  最慢速度
```

然后按下并松开 S1：

1. 等待约 1 秒让显示器完成握手。
2. 屏幕应识别为 640×480，并显示 8 条竖向彩条和 `HDMI TEST`。
3. LED6 应点亮，表示检测到 HPD、I²C 配置完成且 ADV7511 PLL 锁定。
4. LED5 应熄灭；若 LED5 点亮，表示 I²C NACK 或 PLL/热插拔检查失败。

### 没有画面时按顺序检查

1. 确认显示器输入源选对，不要停在“自动”或另一个 HDMI 口。
2. 重新插紧开发板和显示器两端 HDMI 线。
3. 确认使用普通 HDMI 数据线，不是只有供电能力的特殊线材。
4. 看 LED6：不亮通常表示显示器未产生 HPD，先换 HDMI 输入或线缆。
5. 看 LED5：亮时按 S1；仍亮则记录 LED 状态并检查 I²C/ADV7511。
6. 保持 SW6=1 再按 S1，排除 CPU 游戏程序造成的影响。
7. 换一台支持标准 640×480 HDMI 输入的显示器/电视测试。

## 4. 切换到 HDMI 游戏画面

1. 将 SW6 从 1 拨到 0。
2. 等待一个 CPU 状态帧更新；屏幕应显示 8×8 棋盘、蛇、食物、障碍物，以及 `SCORE / HIGH / LV`。
3. SW1..0 选择速度：

| SW1..0 | 大致基础移动间隔 |
|---|---:|
| 00 | 1.0 s |
| 01 | 0.5 s |
| 10 | 0.25 s |
| 11 | 0.125 s |

4. SW2=1 时屏幕出现 `PAUSE`；SW2=0 继续。
5. 撞墙、蛇身或障碍后屏幕出现 `GAME OVER`。

## 5. 用 COM3 控制

1. 确认 J8 对应设备管理器中的 `CP2103 USB to UART Bridge Controller`，端口为 COM3。
2. 在本目录打开 PowerShell：

```powershell
cd C:\Users\xieke\Desktop\CPU\MiniRISC-16-CPU\refactored_design\hdmi_snake_system
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\tools\snake_terminal.ps1" -PortName COM3
```

3. 出现 `Waiting for frames from COM3 at 115200 baud...` 后等待第一帧。
4. 控制键：

- `W/A/S/D` 或方向键：改变方向。
- `R`：重新开始。
- `Q`：退出终端。

终端和 HDMI 会同时显示同一个 CPU 游戏状态。HDMI 不依赖终端绘图；终端只负责把按键通过 UART 发给 CPU。

## 6. 是否需要上传程序

正常情况**不需要**。Snake 已经编进 bitstream，完成第 2 步后 SW7=0、按 S1 即可运行。

只有修改了 `program\snake.asm` 或希望不用重新生成 bitstream 更换程序时才上传：

1. 关闭 `snake_terminal.ps1`，避免 COM3 被占用。
2. SW7=1，按下并松开 S1；数码管显示 `10AD`，HDMI 显示 `LOAD MODE`。
3. 执行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\tools\upload_program.ps1" -PortName COM3
```

4. 看到 `UPLOAD PASS` 后，将 SW7 拨回 0。
5. 按下并松开 S1，再启动 Snake 终端。

## 7. 实板验收清单

- SW6=1 时稳定显示彩条，LED6=1、LED5=0。
- SW6=0 后显示棋盘、蛇、食物和障碍。
- W/A/S/D 有效，反方向输入被拒绝。
- 吃到食物后 Score/Level/蛇长变化。
- SW2 暂停和恢复有效。
- 四档速度都有效。
- GAME OVER 和 R 重开有效，High 保留。
- 拔下再插入 HDMI 后能够重新初始化并恢复画面。
- S1 在运行、暂停、结束和 Loader 状态均能复位。
- COM3 Loader 上传一次后能重新运行。
