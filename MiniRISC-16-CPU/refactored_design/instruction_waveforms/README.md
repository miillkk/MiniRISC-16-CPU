# MiniRISC-16 五类指令聚焦波形

本目录使用原始 `refactored_design/rtl/core` CPU RTL，未修改设计逻辑。
`tb/tb_instruction_classes.v` 提供五个独立、自检且有 watchdog 的仿真顶层。

| 类别 | 仿真顶层 | 图片 | Vivado 波形配置 |
|---|---|---|---|
| 数据传送 MOVI/MOVR | `tb_class_move` | `output/move.png` | `output/move.wdb` + `output/move.wcfg` |
| 算术比较 ADDI/ADDR/SUB/CMP | `tb_class_arithmetic` | `output/arithmetic.png` | `output/arithmetic.wdb` + `output/arithmetic.wcfg` |
| 逻辑运算 AND/OR/XOR | `tb_class_logic` | `output/logic.png` | `output/logic.wdb` + `output/logic.wcfg` |
| 控制转移 JZ/JUMP | `tb_class_branch` | `output/branch.png` | `output/branch.wdb` + `output/branch.wcfg` |
| 输入输出 INP/OUP | `tb_class_io` | `output/io.png` | `output/io.wdb` + `output/io.wcfg` |

Vivado 工程：`project/instruction_waveforms_project.xpr`

重新运行全部五类仿真：

```powershell
& 'F:\vivado\2026.1\Vivado\bin\vivado.bat' -mode batch `
  -source '.\scripts\run_five_waveforms.tcl'
```

所有类别必须在各自的 `output/*_simulate.log` 中出现 `TEST_PASS`。
