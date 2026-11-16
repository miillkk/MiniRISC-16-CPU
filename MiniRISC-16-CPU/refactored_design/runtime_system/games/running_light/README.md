# MiniRISC-16 Running Light

流水灯是统一菜单中的第三个板级程序。LED位置、方向、边界回绕、帧生成和校验均由MiniRISC-16汇编程序执行，电脑终端只发送按键并显示FPGA返回状态。

## 功能

- LED0至LED7单灯循环，左右边界自动回绕。
- `A`/左方向键向LED0移动，`D`/右方向键向LED7移动。
- `SW1..0`选择四档速度，`SW2`暂停硬件定时器。
- `R`重新开始，`Q`返回统一菜单。
- 英文终端显示当前LED、方向、速度、按键、序号、原始FPGA返回帧和XOR校验。

## 构建和验证

在 `runtime_system` 目录执行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\games\running_light\tools\build.ps1"
```

## 菜单运行

切换程序前将 `SW7=1`，然后启动统一菜单：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\tools\arcade_launcher.ps1" -PortName COM3
```

选择 `RUNNING LIGHT` 并按 `Enter`。上传后进入等待画面，将 `SW7=0` 即可运行。

## 终端预览

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\games\running_light\tools\running_light_terminal.ps1" -Demo
```

协议为12字节：

```text
A5 version length game-id sequence pattern position direction
speed switches last-key checksum
```
