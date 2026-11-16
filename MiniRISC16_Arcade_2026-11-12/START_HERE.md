# MiniRISC-16 Arcade：快速使用

版本：2026-11-12，EES331 / XC7Z020。包括贪吃蛇、2048、流水灯、数字华容道、五子棋、国际象棋。

## 第一次使用
1. 完整解压到纯英文路径，例如 C:\Users\Mr.Untitled\Desktop\UESTC\MiniRISC16_Arcade。不要在压缩包内直接运行。
2. 开发板供电，J3 连接电脑用于 Vivado 下载；J8 上方 PL UART USB 连接电脑用于上位机。
3. Vivado → Open Hardware Manager → Open Target → Auto Connect → 右键 xc7z020 → Program Device。
4. Bitstream file 选择本包 bitstream/MiniRISC16_Arcade4K.bit；Debug probes 留空，然后 Program。
5. 设备管理器确认 CP210x/CP2103 已正确识别并显示 COM 编号。若代码28或黄色感叹号，先安装 Silicon Labs 官方 CP210x 驱动。本包不含驱动；不要误用 FTDI 或 STLink 的 COM 编号。
6. 双击 Start_Arcade.cmd，输入实际 CP210x 串口编号，如 COM6。
7. SW7=1，菜单数字键选游戏，Enter 上传；看到 UPLOAD PASS 后按终端提示将 SW7=0。

## 游戏菜单
1 贪吃蛇；2 2048；3 流水灯；4 数字华容道（3×3至6×6）；5 五子棋（双人/CPU人机）；6 国际象棋（双人/CPU人机）。
五子棋和国际象棋终端提示 SW7=0 后还需 Enter；选择1双人或2人机。方向键移动光标，空格确认。国际象棋需先选棋子，再选目标格；M选模式，R重开，Q回菜单。

## 国际象棋升级说明
本包的4K bitstream已通过50MHz时序检查，但内置默认程序仍为旧版双人国际象棋。必须从菜单6上传本包最新chess.mem，才有协议v7的人机模式。断电/重新配置后重新上传。AI全部在自制CPU执行；电脑只显示和输入。
AI为基础单步评分，非多层搜索。本阶段不裁定重复局面、50/75回合及死局和棋。详细说明位于 runtime_system/games/chess/README.md。

## 打开源代码工程
Vivado Tcl Console 执行 source {解压目录/runtime_system/games/chess/tools/create_project.tcl}。请用正斜杠并替换解压目录。
已经有bitstream时无需重新综合。构建和仿真脚本见 games/chess/tools/build.ps1；本机Vivado为2026.1，可用参数更改安装路径。
原始runtime_system/rtl与早期README保留为1K基线，4K工程使用games/chess/hardware覆盖模块。不要仅凭原始说明重新构建旧1K工程来运行国际象棋。

## 验证状态与目录
- bitstream：已生成的4K、50MHz硬件。
- runtime_system：完整游戏源码、汇编程序、上位机、约束、测试及重建脚本。
- games/chess/reports：硬件时序与AI/RTL验证记录；此前VERIFICATION为双人硬件记录，AI_VERIFICATION为新程序记录。
- SHA256SUMS.txt：包内每个文件的校验值（不含清单自身）。
已完成模型和RTL测试；尚未实板完成全部游戏验收。菜单编码已修复为Windows PowerShell兼容格式。
