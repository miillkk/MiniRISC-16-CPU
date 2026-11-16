# MiniRISC-16 接口与控制真值表

本文把设计说明转换为可逐项审查的 RTL 约定。若旧课件或示例与本文及 `CPU项目说明_8位GPIO_单周期.md` 冲突，以设计说明和本文为准。

## 指令字段

| 位段 | 名称 | 含义 |
|---|---|---|
| `[15:12]` | opcode | 操作码 |
| `[11:10]` | Rd | 目的寄存器，也是二元 ALU 的 A 操作数 |
| `[9:8]` | Rs | 源寄存器，也是寄存器型 ALU 的 B 操作数和 OUP 数据源 |
| `[7:0]` | imm8/port | 零扩展立即数、绝对跳转目标或 I/O 地址 |

R0～R3 均为普通可写 16 位寄存器。PC 为 8 位字地址；顺序执行按模 256 加一。立即数零扩展，加减仅保留低 16 位。

## 外部接口

### `cpu_core`

| 方向 | 信号 | 宽度 | 说明 |
|---|---|---:|---|
| 输入 | `clk` | 1 | 状态在上升沿提交 |
| 输入 | `rst` | 1 | 同步、高有效 |
| 输入 | `instruction` | 16 | 当前 PC 对应的组合指令字 |
| 输入 | `io_rdata` | 16 | 组合 I/O 读数据 |
| 输出 | `mem_addr` | 8 | 当前 PC，连接指令 ROM |
| 输出 | `io_addr` | 8 | 指令低 8 位 |
| 输出 | `io_wdata` | 16 | `R[Rs]` |
| 输出 | `io_re` | 1 | I/O 读使能，复位时强制为 0 |
| 输出 | `io_we` | 1 | I/O 写使能，复位时强制为 0 |

### `system_top`

外部端口固定为 `clk`、低有效 `resetn` 和 `gpio[7:0]`。每个 GPIO 位单独三态控制；`gpio_oe[i]=1` 时由 `gpio_o[i]` 驱动，否则为高阻并可由外部输入。

## ALU 编码

| `alu_op` | 运算 | 结果 |
|---|---|---|
| `000` | PASS_B | B |
| `001` | ADD | A + B，截断至 16 位 |
| `010` | SUB | A - B，截断至 16 位 |
| `011` | AND | A & B |
| `100` | OR | A \| B |
| `101` | XOR | A ^ B |
| `110`、`111` | 安全默认 | `16'h0000` |

`alu_src=0` 时 B=`R[Rs]`，`alu_src=1` 时 B=`{8'h00, imm8}`。`wb_sel=0` 写回 ALU，`wb_sel=1` 写回 `io_rdata`。

## 逐 opcode 控制表

| opcode | 指令 | alu_op | alu_src | reg_write | z_write | branch_z | jump | wb_sel | io_re | io_we |
|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `0` | MOVI Rd,#imm8 | PASS_B | 1 | 1 | 0 | 0 | 0 | ALU | 0 | 0 |
| `1` | MOVR Rd,Rs | PASS_B | 0 | 1 | 0 | 0 | 0 | ALU | 0 | 0 |
| `2` | ADDI Rd,#imm8 | ADD | 1 | 1 | 0 | 0 | 0 | ALU | 0 | 0 |
| `3` | ADDR Rd,Rs | ADD | 0 | 1 | 0 | 0 | 0 | ALU | 0 | 0 |
| `4` | XOR Rd,Rs | XOR | 0 | 1 | 0 | 0 | 0 | ALU | 0 | 0 |
| `5` | SUB Rd,Rs | SUB | 0 | 1 | 0 | 0 | 0 | ALU | 0 | 0 |
| `6` | CMP Rd,Rs | SUB | 0 | 0 | 1 | 0 | 0 | ALU | 0 | 0 |
| `7` | AND Rd,Rs | AND | 0 | 1 | 0 | 0 | 0 | ALU | 0 | 0 |
| `8` | JZ #imm8 | PASS_B | 0 | 0 | 0 | 1 | 0 | ALU | 0 | 0 |
| `9` | OR Rd,Rs | OR | 0 | 1 | 0 | 0 | 0 | ALU | 0 | 0 |
| `A` | JUMP #imm8 | PASS_B | 0 | 0 | 0 | 0 | 1 | ALU | 0 | 0 |
| `B` | INP Rd,port | PASS_B | 0 | 1 | 0 | 0 | 0 | I/O | 1 | 0 |
| `C` | OUP port,Rs | PASS_B | 0 | 0 | 0 | 0 | 0 | ALU | 0 | 1 |
| `D`～`F` | 保留 | PASS_B | 0 | 0 | 0 | 0 | 0 | ALU | 0 | 0 |

注意：`1010` 才是 JUMP；Lab 5 中把 `0111` 标为 jump 的内容属于旧版本错误，`0111` 在本设计中固定为 AND。

## 状态提交和复位

取指、译码、寄存器读取、ALU、I/O 读取、写回和下一 PC 选择全为组合路径。每个非复位上升沿同时提交 PC、可选 Rd、可选 Z 和可选 GPIO 写入。CMP 是唯一能改变 Z 的指令；JZ 读取此前保存的 Z。

板级 `resetn` 异步拉低两级释放同步器，两次有效上升沿后解除内部 `rst`。CPU 和 GPIO 状态寄存器均使用同步高有效 `rst`，复位清零 PC、R0～R3、Z、GPIO_OUT、GPIO_DIR 和输入同步器。

## GPIO 地址表

| 地址 | 名称 | 访问 | 读数据 | 写副作用 |
|---:|---|---|---|---|
| `0x10` | GPIO_OUT | 读写 | `{8'h00,gpio_out}` | `gpio_out<=io_wdata[7:0]` |
| `0x11` | GPIO_IN | 只读 | `{8'h00,input_sync_2}` | 无 |
| `0x12` | GPIO_DIR | 读写 | `{8'h00,gpio_dir}` | `gpio_dir<=io_wdata[7:0]` |
| 其他 | 未映射 | 无 | 0 | 无 |

GPIO 输入经过两级同步器；该同步器降低亚稳态传播风险，但不提供按键消抖或 8 位总线原子采样保证。
