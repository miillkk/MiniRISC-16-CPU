# MiniRISC-16 CPU 项目工作区

整理日期：2026-11-16。本目录汇集 CPU 设计、仿真、板级演示、扩展应用和答辩材料。**最终交付版本是 2026-11-12 的 4K Arcade 包**，包含六个游戏、4K bitstream、启动脚本、源码和验证记录。旧的 1K Runtime 保留为开发基线；HDMI 系统保留为独立扩展和实板诊断记录，尚无正常画面的验收结论。

## 从哪里开始

| 需要做什么 | 入口 |
| --- | --- |
| 看整个项目如何演进 | [项目分支图](PROJECT_BRANCH_MAP.md)（另有 [PNG](PROJECT_BRANCH_MAP.png) 和 [SVG](PROJECT_BRANCH_MAP.svg)） |
| 看基础单周期 CPU | [主工程说明](MiniRISC-16-CPU/README.md) |
| 运行最终版 4K Arcade | [最终版快速使用](MiniRISC16_Arcade_2026-11-12/START_HERE.md)；从该目录运行 `Start_Arcade.cmd` |
| 查看旧 1K Runtime 基线 | [Runtime 说明](MiniRISC-16-CPU/refactored_design/runtime_system/README.md) 与 [上板指南](MiniRISC-16-CPU/refactored_design/runtime_system/BOARD_TEST_GUIDE.md) |
| 看计算器或串口 Snake | [计算器目录](MiniRISC-16-CPU/refactored_design/calculator_system/)；[Snake V1 说明](MiniRISC-16-CPU/refactored_design/snake_system/README.md) |
| 继续 HDMI 故障定位 | [HDMI 交接说明](deliverables/handoffs/HDMI_TEST_HANDOFF_2026-11-05/README_HANDOFF.md) |
| 找报告和答辩材料 | [报告](deliverables/reports/)；[演示稿与讲稿](deliverables/presentations/)；[交接件](deliverables/handoffs/) |

## 目录分工

```text
CPU/
├─ MiniRISC16_Arcade_2026-11-12/  最终版 4K Arcade；独立可交付目录
├─ MiniRISC-16-CPU/       原主工程；应用工程路径保持原样
├─ deliverables/
│  ├─ reports/            可编辑报告与 PDF
│  ├─ presentations/      当前演示稿与讲稿
│  └─ handoffs/           Runtime 报告包、HDMI 诊断交接目录
├─ archive/
│  ├─ legacy/             早期工程副本与内容不同的历史 ZIP
│  ├─ authoring/          报告、PPT 的制作脚本、预览和参考材料
│  └─ presentation_drafts/ 早期演示稿版本
├─ ross-ai-assistant/     独立的 AMD Ross 工具仓库
├─ tools/amd-ross/        Vivado MCP 程序与冒烟测试脚本
└─ maintenance/          本次整理的清单、比较结果和操作记录
```

最终版使用包内 `bitstream/MiniRISC16_Arcade4K.bit` 和 `runtime_system/games/chess/hardware/` 中的 4K 覆盖模块。其内置国际象棋程序是早期双人版；要使用新版 CPU 人机模式，须从菜单上传包内 `chess.mem`。该包的说明写明尚未完成全部实板游戏验收。

主工程中的 `rtl/`、`sim/`、`docs/`、`refactored_design/` 是此前设计与验证入口。重构目录下的 board、calculator、snake、runtime 和 HDMI 子工程各自保留独立 RTL、脚本、报告和 bitstream，不要混用不同版本的 CPU 文件。主要旧版 XPR 与 bitstream 路径见[历史工作区总览](archive/README_workspace_2026-10-23.md)第 4 节；该文档写于 10 月，阶段状态应以本页和最终版使用说明为准。

## 当前状态

- 原始 CPU、模块化重构、基础上板、ISA 自检、流水灯、计算器、串口 Snake 和非 HDMI Runtime 均有相应的设计或验证记录；具体实板结论以各项目报告和上板指南为准。
- 最终版 4K Arcade 的程序空间为 4096×16，包内包含 Snake、2048、Running Light、数字华容道、五子棋和国际象棋；旧 1K Runtime 作为此前的开发基线保留。
- HDMI 分支已有 bitstream 和多轮 I²C 诊断，但显示链路仍未完成实板验收。继续排查时以交接目录的 `README_HANDOFF.md` 和对应诊断 bitstream 为准。

## 整理与版本说明

2026-11-16 清理了可再生的 Vivado/XSim 工作缓存、仿真构建目录和崩溃转储；保留了源码、约束、工程入口、bitstream、验证汇总及关键证据。HDMI 交接 ZIP 和 Runtime 报告 ZIP 与解压目录逐文件 SHA-256 一致，已删除 ZIP 并保留目录。最早的一份课程资料 ZIP 也已核对：八个文件与主工程完全相同，一个文本仅换行符不同，因此删除。其余三份历史工程 ZIP 含有当前目录缺失或不同版本的文件，保存在 `archive/legacy/`。

2026-11-12 最终版从用户提供的 ZIP 解压到独立目录，包内 130 个清单条目逐一通过 SHA-256 校验。校验后已按要求删除原 ZIP，只保留解压目录。现在 `CPU/` 是整个项目的 Git 根，沿用原主工程配置的 GitHub 远端；Ross 工具源码作为项目内的工具副本保存。整理记录见 [maintenance](maintenance/)；历史总览见 [归档 README](archive/README_workspace_2026-10-23.md)。
