# EES331 全指令板上自检指南

## 1. 测试目标

这套程序独立于原 `board_demo.mem`，不会覆盖已经通过的演示版本。它在实板上自动执行全部 16 个 opcode：

- 13 条有效指令：`MOVI`、`MOVR`、`ADDI`、`ADDR`、`XOR`、`SUB`、`CMP`、`AND`、`JZ`、`OR`、`JUMP`、`INP`、`OUP`。
- 3 个保留 opcode：`D`、`E`、`F`，检查它们不得修改寄存器、Flags 或 I/O。
- 检查 ADD/SUB/CMP 产生的 Z 和 JZ 响应。
- 检查 MOV、逻辑、I/O 和 JUMP 保持已有 Z。
- 检查 `FFFF+1=0000`、`7FFF+1=8000` 和 `8000-1=7FFF` 的结果边界。

CPU 程序无法直接读取 N/C/V，因此实板程序验证运算结果和 Z/JZ；N/C/V 的逐位判断仍由 RTL 的 ALU/status-register testbench 完成。

## 2. 测试文件

- 机器码和逐地址注释：`sim/programs/board_isa_test.mem`
- 板级 testbench：`sim/tb/tb_board_isa_test.v`
- 独立 Vivado 工程：`board_isa_vivado_project/MiniRISC16_EES331_ISA_TEST.xpr`
- 可直接下载的 bitstream：`reports/board_isa/MiniRISC16_EES331_ISA_TEST.bit`
- 综合、实现、时序和 DRC 报告：`reports/board_isa/`

## 3. 测试前设置拨码为 0x3C

自检程序会读取拨码并要求 `SW7..SW0 = 0011_1100`，即 `0x3C`。

最可靠的设置方法是不猜拨码的物理高低方向：

1. 先下载已经通过的 `reports/board/MiniRISC16_EES331.bit`。
2. 调整普通的 8 个输入拨码，直到数码管显示 `C0DE003D`。
3. 演示程序显示的是“拨码值 + 1”，因此此时 CPU 实际读到的拨码一定是 `0x3C`。
4. 保持这 8 个拨码不动，再下载 ISA 自检 bitstream。

启动配置 SW8 使用本机实测可识别器件的 `000000`，不要把 SW8 与 8 个 CPU 输入拨码混淆。

## 4. 下载步骤

1. 保持开发板通电，确认 Vivado Hardware Manager 中能看到 `xc7z020`。
2. 右键 `xc7z020`，选择 `Program Device`。
3. Bitstream file 选择 `reports/board_isa/MiniRISC16_EES331_ISA_TEST.bit`。
4. Debug probes file 留空。
5. 点击 `Program`，等待成功。
6. 按住 S1 约 0.5 秒，再松开。
7. 自检在数微秒内完成，直接观察最终 LED 和数码管。

## 5. 通过结果

全部指令通过时：

```text
LED      = A5
数码管   = 600D0000
```

程序随后停在 PASS 循环，显示保持不变。再次按 S1 应重新运行并回到同一通过结果。

## 6. 失败结果和错误码

失败时：

```text
LED      = xx
数码管   = E00000xx
```

`xx` 的含义如下：

| 错误码 | 测试阶段 |
|---|---|
| `E1` | MOVI / MOVR |
| `E2` | ADDI 基本结果 |
| `E3` | ADDR 基本结果 |
| `E4` | XOR |
| `E5` | SUB 结果或 SUB 产生 Z |
| `E6` | CMP 不写回、JZ 跳转或不跳转 |
| `E7` | AND |
| `E8` | OR |
| `E9` | JUMP |
| `EA` | OUP 写 LED及 INP 读回 |
| `EB` | 拨码 INP；最常见原因是拨码不是 `0x3C` |
| `EC` | MOV/逻辑/I/O/JUMP 错误修改 Z |
| `ED` | 保留 opcode D/E/F 产生了副作用 |
| `F1` | `FFFF + 1` 未得到零或 Z 未置位 |
| `F2` | `7FFF + 1` 未得到 `8000` |
| `F3` | `8000 - 1` 未得到 `7FFF` |

出现失败码后，程序会停在 FAIL 循环。修改拨码后必须按 S1 重新测试；仅改变拨码不会自动离开失败循环。

## 7. 建议的实板测试顺序

1. 使用原演示 bitstream 把拨码校准到 `0x3C`。
2. 下载 ISA 自检 bitstream，确认 `A5 / 600D0000`。
3. 故意改变一个普通输入拨码并按 S1，确认得到 `EB / E00000EB`。
4. 把拨码恢复为 `0x3C`，再次按 S1，确认恢复 `A5 / 600D0000`。
5. 连续按 S1 重跑 5 次，确认结果稳定。
6. 断电、重新上电、重新下载并再跑一次，检查下载和复位的可重复性。

## 8. 重新生成工程和 bitstream

在 `MiniRISC-16-CPU` 根目录运行：

```powershell
.\refactored_design\sim\scripts\run_synthesis.ps1 -Task BoardIsaProject
.\refactored_design\sim\scripts\run_synthesis.ps1 -Task BoardIsaBitstream
```

若未自动找到 Vivado：

```powershell
.\refactored_design\sim\scripts\run_synthesis.ps1 -Task BoardIsaProject -VivadoBin "F:\vivado\2026.1\Vivado\bin"
.\refactored_design\sim\scripts\run_synthesis.ps1 -Task BoardIsaBitstream -VivadoBin "F:\vivado\2026.1\Vivado\bin"
```

修改 `board_isa_test.mem` 后必须重新执行 `BoardIsaBitstream`；重新下载旧 `.bit` 不会包含新的机器码。

## 9. 当前自动检查结果

- 独立指令模型执行 166 个周期后到达 PC=`D2` 的 PASS 循环。
- opcode coverage=`FFFF`，全部 16 个 opcode 均执行。
- 最终 I/O 状态为 LED=`A5`、display high=`600D`、display low=`0000`、display enable=`1`。
- `xvlog` 成功解析全部 RTL 和 `tb_board_isa_test.v`。
- Vivado 综合、布局布线和 bitstream 写入完成，0 Error、0 未布通网络。
- 100 MHz 时序满足：WNS=`+0.928 ns`、TNS=`0.000 ns`。
- 实现资源：219 LUT、176 Register、42 bonded IOB、1 BUFG。
- DRC 仅保留纯 PL/JTAG 设计已知的 `ZPS7-1` 警告。
- 当前机器的 XSim 动态仿真仍受 `BUG-006` 的 Vivado MinGW 环境问题阻塞，因此不虚构 XSim PASS 结果。
