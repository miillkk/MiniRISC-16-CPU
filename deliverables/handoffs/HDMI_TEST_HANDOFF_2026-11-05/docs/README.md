# MiniRISC-16 HDMI Snake System

本目录是独立的 HDMI 贪吃蛇系统，不修改、也不依赖原来的 `runtime_system/`。系统在 EES331 的 XC7Z020 PL 中运行 MiniRISC-16 程序，由 CPU 维护 8×8 游戏状态，再由独立视频硬件把 72 字节状态帧转换为 640×480 HDMI 画面。

## 主要功能

- MiniRISC-16 CPU、1K×16 可加载程序 RAM、256×16 数据 RAM。
- Snake V2：8×8 地图、蛇身、食物、固定障碍、碰撞、分数、最高分、等级和暂停。
- 640×480、约 59.94 Hz 视频时序，25.175 MHz 像素时钟。
- 16 位 YCbCr 4:2:2 并行视频送入板载 ADV7511。
- ADV7511 I²C 自动初始化、HPD 轮询、PLL 锁定检查和热插拔重初始化。
- HDMI 画面显示棋盘、蛇头、蛇身、食物、障碍、Score/High/Level，以及 PAUSE、GAME OVER、LOAD MODE、HDMI TEST 提示。
- SW6 可强制显示彩条，便于把 HDMI 链路和 CPU 游戏问题分开诊断。
- J8/COM3 继续用于方向控制和程序上传；bitstream 内已经内置 Snake 程序，正常运行时无需再次上传。

## 顶层结构

```text
hdmi_snake_board_top
├─ reset_conditioner
├─ runtime_soc
│  ├─ runtime_program_memory
│  ├─ program_loader
│  ├─ cpu_core
│  ├─ data_memory
│  └─ snake_peripheral_subsystem
├─ seven_segment8_driver
└─ hdmi_video_subsystem
   ├─ pixel_clock_generator
   ├─ video_timing_640x480
   ├─ video_frame_bridge
   ├─ snake_renderer
   │  └─ font5x7
   ├─ hdmi_output_registers
   └─ adv7511_controller
      └─ i2c_master
```

`video_frame_bridge` 在系统时钟域观察 CPU 对数据 RAM `0x00..0x47` 的写入。地址 `0x47` 是帧提交标记；完整帧稳定后通过 toggle CDC 一次性交给像素时钟域，避免屏幕撕裂和半帧数据。

## 板级控制

| 控件 | 功能 |
|---|---|
| S1 | 全系统复位 |
| SW1..0 | 游戏基础速度：`00/01/10/11` 约为 `1.0/0.5/0.25/0.125 s` |
| SW2 | 暂停 |
| SW3..5 | 随机种子扰动 |
| SW6 | HDMI 彩条测试；1=彩条，0=游戏 |
| SW7 | 1=UART Loader，0=运行 CPU |
| LED5 | HDMI 初始化/通信故障 |
| LED6 | HDMI 已检测显示器且 ADV7511 PLL 锁定 |
| LED7 | 游戏/Loader 错误 |

## 构建

在本目录打开 PowerShell：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\run.ps1" -Task Assemble
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\run.ps1" -Task Regression
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\run.ps1" -Task CreateProject
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\run.ps1" -Task Bitstream
```

`Bitstream` 会先在独立 Vivado 进程生成综合检查点，再用第二个进程完成布局布线、布线后物理优化和 bitstream。

最终文件路径：

```text
reports\board\MiniRISC16_HDMISnake.bit
vivado_project\MiniRISC16_HDMISnake.xpr
```

## 当前验证状态（2026-10-16）

- 汇编 PASS：294 个有效程序字，剩余 730 字。
- 独立指令参考模型 PASS：执行 13964 条指令。
- XSim 回归 PASS：10/10，包括 CPU、Loader、UART、游戏、VGA 时序、帧桥、渲染器和 I²C。
- Vivado 综合通过：0 Error、0 Critical Warning；实现完全布通。
- 标准 `-Task Bitstream` 从头复跑通过：WNS=+0.073 ns、TNS=0；bitstream 生成成功，DRC=0 Error。保留 `ZPS7-1` 与两条时钟缓冲优化 Warning，详见实现报告。
- 早期构建曾遇到 Vivado 2026.1 偶发访问冲突；完整记录见 `BUG_FIX_LOG.md`。本次成功构建无需关闭已打开的空闲 Vivado 工程窗口。

详细接线和测试见 `BOARD_TEST_GUIDE.md`；问题证据见 `BUG_FIX_LOG.md` 和 `reports/bugs/`。

ADV7511 配置依据：

- [ADV7511 Hardware User Guide](https://www.analog.com/media/en/technical-documentation/user-guides/ADV7511_Hardware_Users_Guide.pdf)
- [ADV7511 Programming Guide](https://www.analog.com/media/en/technical-documentation/user-guides/ADV7511_Programming_Guide.pdf)
