# MiniRISC-16 层级输入输出表

本表严格按照结构图层级排列。类型为“Verilog模块”的行对应独立 `module`；类型为“内部功能块”的行对应寄存器、ROM、MUX、译码器或连续赋值推断出的硬件。

| 层级结构 | 类型 | 输入（数据、控制、时钟和复位） | 输出 | `inout` / 参数 / 说明 |
|---|---|---|---|---|
| `system_top` | Verilog模块 | `clk`<br>`resetn` | — | `inout gpio[7:0]`<br>参数 `INIT_FILE` |
| ├─ `reset_conditioner` | Verilog模块 | `clk`<br>`resetn` | `rst` | — |
| │　└─ `release_sync` 寄存器 | 内部功能块 | 数据：`release_sync[0]`、`1'b1`<br>时钟：`clk`<br>异步清零：`resetn` | `release_sync[1:0]` | `rst=~release_sync[1]` |
| ├─ `instruction_memory` | Verilog模块 | `addr[7:0]` | `instruction[15:0]` | 参数 `INIT_FILE` |
| │　└─ 256×16 指令 ROM | 内部功能块 | 地址：`addr[7:0]` | 数据：`memory[addr][15:0]` | 状态：`memory[0:255]` |
| ├─ `cpu_core` | Verilog模块 | `clk`<br>`rst`<br>`instruction[15:0]`<br>`io_rdata[15:0]` | `mem_addr[7:0]`<br>`io_addr[7:0]`<br>`io_wdata[15:0]`<br>`io_re`<br>`io_we` | — |
| │　├─ `controller` | Verilog模块 | `instruction[15:0]` | `rd_addr[1:0]`<br>`rs_addr[1:0]`<br>`imm8[7:0]`<br>`alu_op[2:0]`<br>`alu_src`<br>`reg_write`<br>`z_write`<br>`branch_z`<br>`jump`<br>`wb_sel`<br>`io_re`<br>`io_we` | — |
| │　│　├─ 指令字段拆分 | 内部功能块 | `instruction[15:0]` | `opcode[3:0]`<br>`rd_addr[1:0]`<br>`rs_addr[1:0]`<br>`imm8[7:0]` | 固定位段直接拆分 |
| │　│　└─ opcode控制译码 | 内部功能块 | `opcode[3:0]` | `alu_op[2:0]`<br>`alu_src`<br>`reg_write`<br>`z_write`<br>`branch_z`<br>`jump`<br>`wb_sel`<br>`io_re`<br>`io_we` | 组合 `case` 译码 |
| │　└─ `datapath` | Verilog模块 | `clk`<br>`rst`<br>`instruction[15:0]`<br>`io_rdata[15:0]`<br>`rd_addr[1:0]`<br>`rs_addr[1:0]`<br>`imm8[7:0]`<br>`alu_op[2:0]`<br>`alu_src`<br>`reg_write`<br>`z_write`<br>`branch_z`<br>`jump`<br>`wb_sel`<br>`control_io_re`<br>`control_io_we` | `mem_addr[7:0]`<br>`io_addr[7:0]`<br>`io_wdata[15:0]`<br>`io_re`<br>`io_we` | — |
| │　　　├─ PC寄存器 | 内部功能块 | 数据：`pc_next[7:0]`<br>时钟：`clk`<br>同步复位：`rst` | `pc[7:0]` | 每个非复位上升沿更新 |
| │　　　├─ Z寄存器 | 内部功能块 | 数据：`alu_result==16'h0000`<br>时钟：`clk`<br>同步复位：`rst`<br>写使能：`z_write` | `z_flag` | 仅 CMP 写入 |
| │　　　├─ `register_file` | Verilog模块 | `clk`<br>`rst`<br>`write_enable`<br>`write_addr[1:0]`<br>`write_data[15:0]`<br>`read_addr_a[1:0]`<br>`read_addr_b[1:0]` | `read_data_a[15:0]`<br>`read_data_b[15:0]` | 4×16位寄存器组 |
| │　　　├─ 立即数零扩展 | 内部功能块 | `imm8[7:0]` | `immediate[15:0]` | `{8'h00,imm8}` |
| │　　　├─ ALU-B MUX | 内部功能块 | 输入0：`rs_data[15:0]`<br>输入1：`immediate[15:0]`<br>选择：`alu_src` | `alu_b[15:0]` | 16位2:1 MUX |
| │　　　├─ `alu` | Verilog模块 | `operand_a[15:0]`<br>`operand_b[15:0]`<br>`alu_op[2:0]` | `result[15:0]` | 组合逻辑 |
| │　　　├─ Writeback MUX | 内部功能块 | 输入0：`alu_result[15:0]`<br>输入1：`io_rdata[15:0]`<br>选择：`wb_sel` | `writeback_data[15:0]` | 16位2:1 MUX |
| │　　　├─ PC+1加法器 | 内部功能块 | `pc[7:0]`<br>常数 `8'h01` | `pc_plus_one[7:0]` | 8位自然回绕 |
| │　　　├─ Branch MUX | 内部功能块 | 输入0：`pc_plus_one[7:0]`<br>输入1：`imm8[7:0]`<br>选择：`branch_z & z_flag` | `branch_result[7:0]` | `branch_result` 是画图用等价信号名 |
| │　　　└─ Jump MUX | 内部功能块 | 输入0：`branch_result[7:0]`<br>输入1：`imm8[7:0]`<br>选择：`jump` | `pc_next[7:0]` | 8位2:1 MUX |
| ├─ `gpio8` | Verilog模块 | `clk`<br>`rst`<br>`io_addr[7:0]`<br>`io_wdata[15:0]`<br>`io_re`<br>`io_we`<br>`gpio_i[7:0]` | `io_rdata[15:0]`<br>`gpio_o[7:0]`<br>`gpio_oe[7:0]` | — |
| │　├─ GPIO_OUT寄存器 | 内部功能块 | 数据：`io_wdata[7:0]`<br>时钟：`clk`<br>复位：`rst`<br>写控制：`io_we`、`io_addr==8'h10` | `gpio_out[7:0]` | 复位清零 |
| │　├─ GPIO_DIR寄存器 | 内部功能块 | 数据：`io_wdata[7:0]`<br>时钟：`clk`<br>复位：`rst`<br>写控制：`io_we`、`io_addr==8'h12` | `gpio_dir[7:0]` | 复位清零 |
| │　├─ 两级输入同步器 | 内部功能块 | 数据：`gpio_i[7:0]`<br>时钟：`clk`<br>复位：`rst` | `input_sync_2[7:0]` | 内部一级状态 `input_sync_1[7:0]` |
| │　└─ GPIO Read MUX | 内部功能块 | 数据0：`{8'h00,gpio_out}`<br>数据1：`{8'h00,input_sync_2}`<br>数据2：`{8'h00,gpio_dir}`<br>默认：`16'h0000`<br>选择：`io_re`、`io_addr[7:0]` | `io_rdata[15:0]` | 地址 `0x10/0x11/0x12` |
| └─ GPIO三态驱动 ×8 | 内部功能块 | 数据：`gpio_o[7:0]`<br>输出使能：`gpio_oe[7:0]` | 采样：`gpio_i[7:0]` | `inout gpio[7:0]` |

## 层级关系

```text
system_top
├─ reset_conditioner
│  └─ release_sync寄存器
├─ instruction_memory
│  └─ 256×16指令ROM
├─ cpu_core
│  ├─ controller
│  │  ├─ 指令字段拆分
│  │  └─ opcode控制译码
│  └─ datapath
│     ├─ PC寄存器
│     ├─ Z寄存器
│     ├─ register_file
│     ├─ 立即数零扩展
│     ├─ ALU-B MUX
│     ├─ alu
│     ├─ Writeback MUX
│     ├─ PC+1加法器
│     ├─ Branch MUX
│     └─ Jump MUX
├─ gpio8
│  ├─ GPIO_OUT寄存器
│  ├─ GPIO_DIR寄存器
│  ├─ 两级输入同步器
│  └─ GPIO Read MUX
└─ GPIO三态驱动 ×8
```

其中 `branch_result` 是将原 Verilog 的嵌套 `pc_next` 条件表达式拆成两个 MUX 后使用的画图信号名，不是新增 RTL 端口。`INIT_FILE` 是 elaboration 参数，不是运行时输入。
