# Runtime Arcade / Snake 与 2048 上板测试

## 1. 接线

1. J3 连接电脑，用于 JTAG 下载。
2. J8 上方 PL UART USB 连接电脑；已安装 CP210x VCP 驱动后，本机识别为 COM3。
3. 板卡上电，启动拨码保持此前已验证的 `SW8=000000`。

J3 的 COM8 是 PS UART，不是本工程使用的 PL UART；终端和程序上传均使用 J8 对应的 COM3。

## 2. 下载 bitstream

bitstream：

```text
reports\board\MiniRISC16_Runtime.bit
```

在 Vivado Hardware Manager 中 Open Target、Auto Connect、Program Device，选择该 `.bit`。下载前建议令 SW7=0。

## 3. 运行 16×8 Snake V2

当前预生成 bitstream 内置的是旧 8×8 程序。第一次使用 16×8 版本时，先按第 4 节的方法上传当前 `program\snake.mem`，然后：

1. SW7=0。
2. 按下并松开 S1。
3. 在本目录运行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\tools\snake_terminal.ps1" -PortName COM3
```

控制：

- `W/A/S/D` 或方向键：移动。
- `R`：游戏重新开始。
- `Q`：退出终端。
- SW1..0：基础速度；`00/01/10/11` 对应约 `1.0/0.5/0.25/0.125 秒`，得分带来的软件加速会在此基础上提高档位。
- SW2：暂停。
- SW4..3：下次重新开始时选择地图；`00=Open`、`01=Maze`、`10/11=Hard`。
- SW6..5：参与随机种子。
- SW7：0 为运行，1 为程序加载模式。

彩色终端中的灰色连线是障碍墙，`▲/▶/▼/◀` 是随移动方向变化的默认蛇头，绿色粗线、无圆圈尾端和拐角组成蛇身，红色菱形是食物。每吃两个食物提升一级，Score `0..1/2..3/4..5/6+` 对应 Level `0/1/2/3`；High 显示本次硬件复位以来的最高分。改变 SW4..3 后按 `R` 或 `S1` 才会载入新地图。

新版终端使用彩色双栏面板和 140 字节协议 v3，帧尾包含版本、长度、序号和 XOR 校验。不上板时可先预览界面：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\tools\snake_terminal.ps1" -Demo
```

地图预览：增加 `-DemoMap Open`、`-DemoMap Maze` 或 `-DemoMap Hard`；状态预览增加 `-DemoState Paused` 或 `-DemoState GameOver`。默认头部为 `-HeadStyle Arrow`，实验性的带眼睛头部可使用 `-HeadStyle Face`。兼容选项：`-NoColor` 关闭 ANSI 颜色，`-Ascii` 改用纯 ASCII 边框和棋盘字符。

若终端提示 `FRAME VERSION / CHECKSUM ERROR`，说明板上仍在运行旧程序或串口帧损坏；关闭终端，按第 4 节重新上传当前 `program\snake.mem`。

也可以直接启动统一游戏菜单，在 Snake、2048 和 Running Light 之间选择：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\tools\arcade_launcher.ps1" -PortName COM3
```

方向键或 `W/S` 选择，`Enter` 启动，`Q` 退出。数字键 `1/2/3` 可快速选择。切换到另一款程序前先将 `SW7` 拨到 1；菜单会直接上传并进入对应终端，不再显示中间确认页面。终端出现等待画面后将 `SW7` 拨回 0，画面会自动出现；按 `Q` 会回到选择菜单。

## 4. 通过 UART 更换程序

加载时不要同时运行 Snake 终端，COM3 只能被一个程序占用。

1. 关闭 Snake 终端。
2. 将 SW7 置 1。CPU 被复位保持，数码管显示 `10AD`。
3. LED5 表示 Loader Busy，LED6 表示上传成功，LED7 表示校验或协议错误。
4. 上传默认 `program\snake.mem`：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\tools\upload_program.ps1" -PortName COM3
```

5. 看到 `UPLOAD PASS` 后，LED6 应点亮。
6. 将 SW7 置 0，CPU 从地址 `0x000` 执行刚上传的程序。
7. 再次启动 `snake_terminal.ps1`。

上传其他程序：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\tools\upload_program.ps1" -PortName COM3 -Program ".\program\other.mem"
```

上传内容在断电或重新下载 bitstream 前保持；S1 只复位 CPU/外设，不擦除已上传程序。重新配置 FPGA 后恢复 bitstream 内置的 Snake V2。

## 5. Snake V2 验收项目

1. SW4..3 分别选择 Open、Maze、Hard；每张地图的所有空格区域都相互连通，右侧没有孤立的突兀墙段。
2. 方向键能够控制，蛇头符号随方向正确切换；蛇身使用粗线、收细尾端和拐角，横向和纵向粗细一致；反方向输入被拒绝。
3. 撞墙、撞蛇身或撞障碍物均进入 GAME OVER，棋盘中央显示重新开始提示。
4. 吃食物后长度和 Score 增加；每吃两个食物 Level 增加一级，Level 到 3 后继续得分也保持为 3。
5. 得分过程不会增加、删除或移动墙体。
6. 地图接近占满时，食物查找仍能在有限时间内完成；SW1..0 仍可叠加基础速度。
7. 游戏结束后 High 更新；按 R 后 High 保留。
8. SW2 暂停期间不移动，棋盘变暗并显示暂停提示；解除后恢复。
9. 终端持续显示帧序号，正常运行时不出现版本或校验错误。
10. S1 能在任意状态恢复初始游戏。
11. 执行一次 UART 上传，SW7 返回 0 后程序重新正常运行。

## 6. 运行 2048

2048 和 Snake 使用同一个 Runtime bitstream，只更换 Loader 中的程序镜像：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\tools\upload_program.ps1" -PortName COM3 -Program ".\games\2048\program\game_2048.mem"
```

上传时保持 `SW7=1`；看到 `UPLOAD PASS` 后将 `SW7=0`，再运行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\games\2048\tools\game_2048_terminal.ps1" -PortName COM3
```

方向键或 `W/A/S/D` 移动，`R` 重新开始，`Q` 退出。详细说明见 `games\2048\README.md`。

## 7. 常见问题

- 一直显示 `Waiting for frames`：确认 SW7=0、使用 COM3、J8 已连接且 CP2103 驱动正常。
- COM3 被占用：关闭另一个 PowerShell 串口脚本或串口助手。
- 数码管显示 `10AD`：当前 SW7=1，属于 Loader 模式。
- LED7 点亮：上传包长度/校验失败，保持 SW7=1 后重新运行上传脚本。
- 上传后无运行：确认出现 `UPLOAD PASS`，然后把 SW7 从 1 切回 0。
