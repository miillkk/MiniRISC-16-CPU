# 2026-11-16 文件整理记录

- `inventory_before_2026-11-16.csv` 与 `inventory_after_2026-11-16.csv`：整理前后文件路径、大小和修改时间。
- `actions_2026-11-16.csv`：首次批量移动和删除清单；`followup_actions_2026-11-16.csv`：按“源文件在则删 ZIP”的后续调整。
- `archive_comparison_2026-11-16.csv`：六份 ZIP 与对应目录的逐文件 SHA-256 比较。它记录比较时的状态；其中三份 ZIP 后来已删除。
- `organize_2026-11-16.ps1` 是一次性整理脚本，**不能在已整理的目录上重复运行**。`compare_archives_2026-11-16.ps1` 用于记录当时的 ZIP 比较方法。

删除的 ZIP：HDMI 交接包与 Runtime 报告包的所有条目均与解压目录逐文件相同；最早的 `MiniRISC-16-CPU-main.zip` 中八个文件与主工程完全相同，`项目描述.txt` 仅换行符不同、文字内容相同。

保留的三份 ZIP：`MiniRISC-16-CPU-main (2).zip`、`refactored_design.zip`、`refactored_design (2).zip` 各有现存目录缺失或内容不同的历史文件。比较表中的“缺失”也包括已清理的可再生缓存；差异文件中同时有课程资料、说明文档或报告，不能仅据目录名称删除整包。

未改动主工程内各应用目录的相对路径，未对 Git 工作区执行重置或提交。此次没有重新综合、仿真或实板验证；验收范围是文件归档、完整性和导航路径。
