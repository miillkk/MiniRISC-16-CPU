# MiniRISC-16 Runtime Arcade

这是完全独立于原 RTL、`calculator_system` 和已验证 `snake_system` 的新版工程。旧目录没有被修改。本目录包含可综合 RTL、1024 字程序镜像、UART 程序加载器、Snake V2、testbench、Vivado 工程脚本、约束、报告和 bitstream。

## 已实现功能

- 程序空间由 `256×16` 扩充为 `1024×16`，PC 由 8 位扩充为 10 位。
- 原 `JUMP/JZ` 保持兼容，定义为当前 256 字页内跳转。
- opcode `0xF` 新增 `JMPA addr10`，可跨 4 个程序页绝对跳转。
- 程序存储器为可写 `1K×16` 分布式 RAM，配置后默认含 Snake V2。
- SW7=1 时 CPU 停止并进入 UART Loader；SW7=0 时 CPU 从 `0x000` 运行。
- `upload_program.ps1` 可通过 J8/COM3 上传新的 1024 字程序，不重新生成 bitstream。
- Snake V2 使用 `16×8` 逻辑棋盘（128 格），提供 Open、Maze、Hard 三套固定且全连通的地图、两食物一级的速度增长、高分记录、140 字节校验帧和终端状态显示。
- 电脑端终端采用彩色双栏界面，同时显示棋盘、地图名、运行状态、方向、分数、速度、拨码、Flags 和帧序号；默认蛇头使用原来的纯方向箭头 `▲/▶/▼/◀`，蛇身使用粗线直段、无圆圈的收细尾端和拐角，相邻障碍自动绘制成墙和折线，不依赖 HDMI 或 Vivado GUI。
- 串口协议 v3 在帧尾增加版本、长度、序号和 XOR 校验；暂停时棋盘变暗并显示恢复提示，游戏结束时在棋盘中央显示重新开始提示。
- 食物先进行最多 16 次随机查找，失败后确定性扫描整张地图，避免地图较满时无限随机循环；三套地图均没有封闭的不可达区域。
- 保留自碰撞、墙碰撞、食物、增长、暂停、方向保护和硬件复位。
- 新增首个独立扩展游戏 2048：标准 `4×4` 合并规则、随机新方块、胜负判断、16 位分数和专用彩色终端；通过同一个 UART Loader 与 Snake 按需切换。
- `arcade_launcher.ps1` 提供统一游戏选择界面：方向键选择 Snake、2048 或 Running Light，自动调用对应 Loader 镜像和游戏终端，退出后回到菜单。
- 统一菜单新增 Running Light：CPU通过 `OUP 0x30` 驱动8位板载LED，支持方向、四档速度、暂停、边界回绕，并在终端显示原始FPGA返回帧和校验结果。

## 顶层结构

```text
runtime_board_top
├─ reset_conditioner
├─ runtime_soc
│  ├─ runtime_program_memory      1024×16，可由 Loader 写入
│  ├─ program_loader             UART 二进制加载器
│  ├─ cpu_core
│  │  ├─ controller
│  │  └─ datapath
│  ├─ data_memory                256×16
│  └─ snake_peripheral_subsystem
│     ├─ uart_port
│     ├─ tick_timer
│     ├─ lfsr8
│     ├─ display_registers
│     ├─ led8
│     ├─ scratchpad16
│     └─ io_decoder
└─ seven_segment8_driver
```

Vivado 综合顶层为 `runtime_board_top`，器件为 `xc7z020clg484-1`。

## ISA 地址扩充

```text
JUMP target8 : PC_next = {PC[9:8], target8}
JZ target8   : Z=1 时 PC_next = {PC[9:8], target8}
JMPA addr10  : PC_next = addr10
```

`JMPA` 编码：`1111_00aa_aaaaaaaa`，低 10 位为绝对地址。汇编器会拒绝跨页 `JUMP/JZ`，并提示使用本页 trampoline 与 `JMPA`。

## I/O 映射

| 地址 | 方向 | 功能 |
|---|---|---|
| `0x10` | R/W | CPU UART 数据 |
| `0x11` | R | UART 状态 |
| `0x12` | R | 游戏 Tick/读取确认 |
| `0x13` | R | LFSR 随机数 |
| `0x14` | R/W | 软件速度增量 `0..3` |
| `0x20` | R/W | 数码管低 4 位 |
| `0x21` | R/W | 数码管高 4 位 |
| `0x22` | R/W | 数码管控制 |
| `0x30` | R/W | LED |
| `0x31` | R | 同步后的拨码 |
| `0x32` | R | CPU Flags |
| `0x40..0x4F` | R/W | Scratchpad |

硬件速度等于 `SW1..0 + 软件等级`，饱和到 3。每吃两个食物提升一级：Score `0..1/2..3/4..5/6+` 分别对应 Level `0/1/2/3`，Level 3 不再回绕。SW2 暂停；SW4..3 在重新开始时选择 Open/Maze/Hard（`00/01/10或11`）；SW6..5 仍可参与随机种子；SW7 专用于 Loader/Run 模式。100 MHz 下四档移动间隔约为 `1.0 / 0.5 / 0.25 / 0.125 秒`。

## 构建与验证

在本目录打开 PowerShell：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\run.ps1" -Task Assemble
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\run.ps1" -Task Regression
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\run.ps1" -Task CreateProject
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\run.ps1" -Task Bitstream
```

Vivado 默认位置为 `F:\vivado\2026.1\Vivado\bin`；其他安装位置可增加 `-VivadoBin`。

主要交付物：

- `vivado_project/MiniRISC16_Runtime.xpr`
- `reports/board/MiniRISC16_Runtime.bit`
- `program/snake.asm`、`snake.mem`、`snake.lst`
- `tools/upload_program.ps1`
- `tools/snake_terminal.ps1`
- `tools/arcade_launcher.ps1`
- `games/2048/program/game_2048.asm`、`game_2048.mem`
- `games/2048/tools/game_2048_terminal.ps1`
- `games/running_light/program/running_light.asm`、`running_light.mem`
- `games/running_light/tools/running_light_terminal.ps1`

统一游戏菜单无需板卡即可预览：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\tools\arcade_launcher.ps1" -Demo
```

连接板卡后运行选择界面（按实际串口修改 `COM3`）：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\tools\arcade_launcher.ps1" -PortName COM3
```

2048 的独立界面、构建、上传和运行步骤见 `games/2048/README.md`。预览命令：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\games\2048\tools\game_2048_terminal.ps1" -Demo
```

终端界面无需连接板卡即可预览：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\tools\snake_terminal.ps1" -Demo
```

可用 `-DemoMap Open/Maze/Hard` 预览三套地图，增加 `-DemoState Paused` 或 `-DemoState GameOver` 预览中央状态提示。默认头部风格为 `-HeadStyle Arrow`；如需带眼睛的实验风格可改用 `-HeadStyle Face`。若旧式控制台不能正确显示颜色或 Unicode，可分别增加 `-NoColor`、`-Ascii`；两者可以同时使用。

## 已验证结果

- 当前 `16×8` 程序汇编：477 条有效指令，跨 Page 0/Page 1，剩余 547 字。
- 当前独立参考模型：PASS，执行 38592 条指令；覆盖三地图选择与全图连通性、随机食物的有界回退、每两食物升级、Level 3 饱和、确认得分不改变墙体、墙/障碍碰撞，以及协议 v3 的 140 字节帧、序号和 XOR 校验。
- 当前终端：彩色 Unicode 与纯 ASCII 两种预览均 PASS。
- 2048 程序：534 条有效指令；独立 CPU 参考模型 PASS，覆盖四方向、单次合并、生成规则、16 位分数、胜利、失败和协议 v4 校验。
- Running Light 程序：174 条有效指令；独立 CPU 参考模型 PASS，覆盖单灯移动、左右方向、双向回绕、速度/暂停拨码元数据、重启和12字节协议校验。
- 本机 XSim 环境已修复：根因是 Vivado 2026.1 自带的旧 MinGW `gcc.exe` 无法在本机启动；项目仿真脚本现在通过 Vivado 支持的 `-gcc_install_path` 使用 `E:/mingw64/bin`，无需替换 Vivado 安装文件。
- 2026-11-04 重新验证当前非 HDMI 终端版：两项波形测试均完整通过 Vivado 2026.1 的 `xvlog → xelab → xsim`，原生 XSim 2/2 `TEST PASS`，并生成非空 WDB、VCD 和 WCFG。最终按旧版分图方式生成 5 张 Vivado Wave 风格图片，数据取自原生 XSim VCD，覆盖单周期提交、`CMP/JZ/JUMP/JMPA`、寄存器/ALU/回写、Running Light 的 `PC/instruction/io_we/io_addr/io_wdata/LED`（`01→02`），以及新增 `STR/LDR` 数据 RAM 访问。证据见 `reports/waveforms/current_terminal/README.md`。
- 实现后时序：WNS `+0.157 ns`，TNS `0`；WHS `+0.049 ns`，THS `0`。
- 布线：0 条未布通网络；DRC 0 Error。
- 资源：1204 LUT、750 FF、44 IOB、程序 RAM 为 `1K×16` 分布式 RAM。
- bitstream SHA-256：`B0F2813099A7713DAD040DA765B50DF3B8DE8BBA3C6BAF7E2D49E1FF0DA15F71`。

上述实现、资源、时序与 bitstream 数据属于修改前的已验证构建。无需重新生成 bitstream 即可用 SW7 Loader 上传当前 `program/snake.mem`；若要让重新配置 FPGA 后默认直接进入 16×8 版本，则需在 Vivado 环境恢复后重新生成 bitstream。

实板步骤见 `BOARD_TEST_GUIDE.md`，问题与修复证据见 `BUG_FIX_LOG.md`。
