# 文件分类与依赖关系

## 目录用途

| 路径 | 内容 | 版本控制策略 |
|---|---|---|
| `docs/requirements/` | 原始项目描述 | 提交，原文件名保留 |
| `docs/design/` | 权威设计 md、现有 drawio、接口与控制表 | 提交 |
| `docs/courseware/` | Topic 与 lab1～lab5 课件 | 提交，作为背景资料而非最终规格 |
| `docs/templates/` | 原始报告和答辩模板 | 提交，本阶段不填充 |
| `docs/verification/` | 测试方法、结果和限制 | 提交 |
| `docs/CPU设计与验证讲解稿.md` | 可转成答辩 PPT 或课堂讲解的设计与验证整合说明 | 提交 |
| `rtl/core/` | ALU、寄存器组、控制器、数据通路、CPU 核 | 提交 |
| `rtl/peripherals/` | 指令 ROM、GPIO、复位处理 | 提交 |
| `rtl/top/` | 可用于后续板级集成的系统顶层 | 提交 |
| `sim/tb/` | 六个自检 testbench | 提交 |
| `sim/programs/` | 机器码、反汇编注释、预期终态 | 提交 |
| `sim/scripts/` | Vivado XSim 回归、VCD/WCFG 和波形渲染入口 | 提交 |
| `sim/build/` | 每次回归的临时编译目录 | 忽略，可删除重建 |
| `reports/simulation/` | 选定的最终文本日志和汇总 | 提交 |
| `reports/waveforms/` | 选定 VCD、WCFG、SVG 和 PNG | 提交 |
| `vivado_project/MiniRISC16_CPU.xpr` | 已创建的 Vivado GUI 项目入口，part 为 `xc7z020clg400-1` | 可提交 `.xpr`；缓存和 run 目录忽略 |
| `fpga/` | 后续约束、时钟、ILA 和上板工作说明 | 提交说明；生成 run 忽略 |

## RTL 调用关系

```text
system_top
├─ reset_conditioner
├─ instruction_memory
├─ cpu_core
│  ├─ controller
│  └─ datapath
│     ├─ register_file
│     └─ alu
└─ gpio8
```

指令路径为 `PC -> instruction_memory -> controller/datapath`；写回路径为 `register_file -> ALU 或 gpio8 读数据 -> register_file`；控制流路径为 `PC+1 / JZ / JUMP -> PC`。GPIO 三态只出现在 `system_top`，便于在核心和外设级仿真中使用分离的 `gpio_i/gpio_o/gpio_oe`。

## 仿真入口

从工程根目录运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\sim\scripts\run_all.ps1
```

也可用 `-VivadoBin <Vivado/bin>` 指定安装目录。脚本为每个 testbench 建立隔离构建目录，运行 `xvlog -> xelab -> xsim`，并要求日志中出现该测试唯一的 `TEST PASS`；仅有进程返回码为零不足以判定通过。

## 规格优先级与缺失资料

用户指令高于附加文档；`CPU项目说明_8位GPIO_单周期.md` 高于旧课件和旧示例。当前只收到 `CPU_Five_Step_Dataflow_GPIO8.drawio`。硬件结构 drawio、硬件结构 SVG、五步数据流 SVG 的源文件未提供，已在设计 md 中明确标为“源文件缺失”，没有伪造替代文件。

## 源文件与生成物

RTL、testbench、机器码、脚本和手写文档是源文件。`.Xil`、`xsim.dir`、`*.jou`、普通 `*.log`、`*.wdb`、Vivado cache/run 和 `sim/build` 是可再生临时物，由 `.gitignore` 排除。最终审查使用的 `.txt` 日志、选定 VCD/WCFG 与 SVG/PNG 波形是交付物，明确保留。
