# MiniRISC-16 2048

这是多游戏计划中的第一个独立游戏。它复用现有 Runtime bitstream 和 UART Loader，不覆盖贪吃蛇源程序，也不需要重新生成 bitstream。

推荐从统一选择界面进入 Snake 或 2048：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\tools\arcade_launcher.ps1" -PortName COM3
```

菜单用方向键或 `W/S` 选择，`Enter` 启动。切换游戏前先将 `SW7=1`；菜单直接上传并进入游戏终端，不显示中间确认页面。进入等待画面后将 `SW7=0`，退出游戏后自动回到菜单。

## 已实现

- 标准 `4×4` 2048：压缩、相同数字合并、每个方块一次移动最多参与一次合并。
- 有效移动后随机生成 `2`，小概率生成 `4`；无效移动不会生成新方块。
- 支持上下左右、重新开始、2048 胜利提示和无路可走判断。
- 16 位分数、27 字节协议 v4、帧序号及 XOR 校验。
- 彩色终端界面，支持方向键和 `W/A/S/D`。

## 先预览界面

在 `runtime_system` 目录打开 PowerShell：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\games\2048\tools\game_2048_terminal.ps1" -Demo
```

## 构建和验证

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\games\2048\tools\build.ps1"
```

该命令生成 `program\game_2048.mem` 和 `.lst`，随后用 CPU 参考模型执行机器码测试。测试覆盖四方向移动、连续方块的单次合并规则、生成新方块、16 位分数、胜利、失败和通信校验。

## 上传到板卡

1. 关闭所有正在使用板卡串口的终端。
2. 把 `SW7` 拨到 `1`，数码管应显示 `10AD`。
3. 在 `runtime_system` 目录执行（按实际串口修改 `COM3`）：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\tools\upload_program.ps1" -PortName COM3 -Program ".\games\2048\program\game_2048.mem"
```

4. 看到 `UPLOAD PASS` 后，把 `SW7` 拨回 `0`。
5. 启动 2048 终端：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\games\2048\tools\game_2048_terminal.ps1" -PortName COM3
```

操作：方向键或 `W/A/S/D` 移动，`R` 重新开始，`Q` 退出电脑端终端。若电脑只连接了一个串口，可以省略 `-PortName COM3` 自动选择。

要切回贪吃蛇，重新进入 `SW7=1`，上传 `program\snake.mem`，再将 `SW7` 置 `0` 并运行 `tools\snake_terminal.ps1`。

## 文件

- `program\game_2048.asm`：MiniRISC-16 汇编源程序。
- `program\game_2048.mem`：Loader 使用的 1024 字镜像。
- `tools\game_2048_terminal.ps1`：电脑端彩色界面和控制器。
- `tools\reference_model.ps1`：执行真实机器码的独立 CPU 参考模型。
- `reports\reference-model.log`：最近一次验证结果。
