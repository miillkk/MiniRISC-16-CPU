# 五子棋：双人 / 自制 CPU 人机

15×15，自由规则，任意方向连续五子或更多获胜，不设禁手。黑棋先行；人机模式玩家执黑、CPU 执白。

## 使用

沿用 `reports/board/MiniRISC16_Runtime.bit`。从 runtime_system 目录启动：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\arcade_launcher.ps1 -PortName COM3
```

COM3 替换成 J8 上方 PL UART 的实际串口。选择菜单 5 / GOMOKU，上传前 SW7=1。上位机提示后，切换 SW7=0 并按 Enter。选择 1 双人或 2 人机。方向键/WASD 移动光标，空格/Enter 落子，R 重开当前模式，Esc 返回模式选择，Q 返回总菜单。上传和游戏终端不能同时占用串口。

## 运算分工

MiniRISC-16 汇编负责棋盘、回合、合法落子、四方向胜负、满盘和棋和 AI 决策。上位机仅选择模式、发送格子编号、接收状态和绘制界面，没有 AI 或胜负判断。

AI 分两轮枚举空格：先试白棋是否立即获胜，再试黑棋是否构成下一步胜利并阻挡。否则选择距离中心曼哈顿距离最小的空格，相同距离按格子编号选择。此版本是确定性的基础战术 AI，不含活三评分、多步搜索或随机落子。

棋盘使用数据 RAM 0..224，一个格子一个字；变量使用 225..248。程序当前 642/1024 字，无需扩展硬件。试落子由 CPU 执行并撤回，决策后才提交实际落子。对手同时有多个必胜点时不保证防住。

## 协议

115200 8N1。单字节命令：0..224 为格子编号（row*15+col）；240 双人重开；241 人机重开；242 当前模式重开；243 查询。其他命令返回当前状态。

回复固定 231 字节：A5、模式(0/1)、当前方(1黑/2白)、结果(0进行/1黑胜/2白胜/3和棋)、落子总数、225 个棋盘字节、前230字节异或校验。棋盘值 0空/1黑/2白。人机模式在 CPU 落子后返回一帧；终局保留最终落子方。

## 构建与验证

从 runtime_system 目录运行：

```powershell
node .\games\gomoku\tools\build.cjs
.\tools\assemble.ps1 -Source .\games\gomoku\program\gomoku.asm -Output .\games\gomoku\program\gomoku.mem -SkipRom
node .\games\gomoku\tools\verify.cjs
```

build.cjs 生成跨页安全的汇编；修改应在生成器中进行。verify.cjs 执行实际生成的机器码，并通过模拟串口验证四方向获胜、不跨行误判、占位拒绝、保留指令拒绝、终局锁定、和棋、AI 合法落子/取胜/阻挡和帧校验。战术测试包含直接初始化数据 RAM 的局面夹具。

已通过汇编、软件指令模型测试、PowerShell 语法解析和菜单 Demo。未进行本次 RTL 仿真、实板或真实串口测试。包内原有 SHA256SUMS 是原始交接包清单，不包含本次新增文件，菜单修改也会导致其原哈希不匹配。
