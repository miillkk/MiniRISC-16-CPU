# MiniRISC-16 RTL 模块层级与独立端口框

本文件只表示9个真实 Verilog 模块。每个模块单独画框，框内只写模块名；输入位于左侧，输出位于右侧。端口短线只表示端口属于该模块，不表示模块之间已经连线。

推荐使用的模块级单页版本见 [SYSTEM_TOP_LEVEL.drawio](SYSTEM_TOP_LEVEL.drawio)：沿用顶层版式，只展开到 `register_file` 和 `alu`，与本文件列出的9个真实模块层级一致，并以连续正交线连接全部模块端口。GPIO 三态驱动和 datapath 未展开逻辑均明确标为非 module。备选排版见 [SYSTEM_TOP_MODULE_HIERARCHY.drawio](SYSTEM_TOP_MODULE_HIERARCHY.drawio)。包含 datapath 推断逻辑的细化参考图见 [SYSTEM_TOP_WITH_DATAPATH_INTERNAL.drawio](SYSTEM_TOP_WITH_DATAPATH_INTERNAL.drawio)。较简化的 `cpu_core` 单页版本见 [SYSTEM_TOP_WITH_CPU_INTERNAL.drawio](SYSTEM_TOP_WITH_CPU_INTERNAL.drawio)。两页分层版本见 [SYSTEM_TOP_AND_CPU_CORE_CONNECTED.drawio](SYSTEM_TOP_AND_CPU_CORE_CONNECTED.drawio)：第1页连接 `system_top` 一级全部端口，第2页单独展开并连接 `cpu_core` 内的 `controller` 与 `datapath`。

## 1. 模块层级

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

共9个独立 Verilog 模块：`system_top`、`reset_conditioner`、`instruction_memory`、`cpu_core`、`controller`、`datapath`、`register_file`、`alu`、`gpio8`。

## 2. `system_top`

```mermaid
flowchart LR
    classDef port fill:none,stroke:none

    P["INIT_FILE（参数）"] -.- M["system_top"]
    I1["clk"] --- M
    I2["resetn"] --- M
    M --- IO1["gpio[7:0]（inout）"]

    class P,I1,I2,IO1 port
```

## 3. `reset_conditioner`

```mermaid
flowchart LR
    classDef port fill:none,stroke:none

    I1["clk"] --- M["reset_conditioner"]
    I2["resetn"] --- M
    M --- O1["rst"]

    class I1,I2,O1 port
```

## 4. `instruction_memory`

```mermaid
flowchart LR
    classDef port fill:none,stroke:none

    P["INIT_FILE（参数）"] -.- M["instruction_memory"]
    I1["addr[7:0]"] --- M
    M --- O1["instruction[15:0]"]

    class P,I1,O1 port
```

## 5. `cpu_core`

```mermaid
flowchart LR
    classDef port fill:none,stroke:none

    I1["clk"] --- M["cpu_core"]
    I2["rst"] --- M
    I3["instruction[15:0]"] --- M
    I4["io_rdata[15:0]"] --- M

    M --- O1["mem_addr[7:0]"]
    M --- O2["io_addr[7:0]"]
    M --- O3["io_wdata[15:0]"]
    M --- O4["io_re"]
    M --- O5["io_we"]

    class I1,I2,I3,I4,O1,O2,O3,O4,O5 port
```

## 6. `controller`

```mermaid
flowchart LR
    classDef port fill:none,stroke:none

    I1["instruction[15:0]"] --- M["controller"]

    M --- O1["rd_addr[1:0]"]
    M --- O2["rs_addr[1:0]"]
    M --- O3["imm8[7:0]"]
    M --- O4["alu_op[2:0]"]
    M --- O5["alu_src"]
    M --- O6["reg_write"]
    M --- O7["z_write"]
    M --- O8["branch_z"]
    M --- O9["jump"]
    M --- O10["wb_sel"]
    M --- O11["io_re"]
    M --- O12["io_we"]

    class I1,O1,O2,O3,O4,O5,O6,O7,O8,O9,O10,O11,O12 port
```

## 7. `datapath`

```mermaid
flowchart LR
    classDef port fill:none,stroke:none

    I1["clk"] --- M["datapath"]
    I2["rst"] --- M
    I3["instruction[15:0]"] --- M
    I4["io_rdata[15:0]"] --- M
    I5["rd_addr[1:0]"] --- M
    I6["rs_addr[1:0]"] --- M
    I7["imm8[7:0]"] --- M
    I8["alu_op[2:0]"] --- M
    I9["alu_src"] --- M
    I10["reg_write"] --- M
    I11["z_write"] --- M
    I12["branch_z"] --- M
    I13["jump"] --- M
    I14["wb_sel"] --- M
    I15["control_io_re"] --- M
    I16["control_io_we"] --- M

    M --- O1["mem_addr[7:0]"]
    M --- O2["io_addr[7:0]"]
    M --- O3["io_wdata[15:0]"]
    M --- O4["io_re"]
    M --- O5["io_we"]

    class I1,I2,I3,I4,I5,I6,I7,I8,I9,I10,I11,I12,I13,I14,I15,I16 port
    class O1,O2,O3,O4,O5 port
```

## 8. `register_file`

```mermaid
flowchart LR
    classDef port fill:none,stroke:none

    I1["clk"] --- M["register_file"]
    I2["rst"] --- M
    I3["write_enable"] --- M
    I4["write_addr[1:0]"] --- M
    I5["write_data[15:0]"] --- M
    I6["read_addr_a[1:0]"] --- M
    I7["read_addr_b[1:0]"] --- M

    M --- O1["read_data_a[15:0]"]
    M --- O2["read_data_b[15:0]"]

    class I1,I2,I3,I4,I5,I6,I7,O1,O2 port
```

## 9. `alu`

```mermaid
flowchart LR
    classDef port fill:none,stroke:none

    I1["operand_a[15:0]"] --- M["alu"]
    I2["operand_b[15:0]"] --- M
    I3["alu_op[2:0]"] --- M

    M --- O1["result[15:0]"]

    class I1,I2,I3,O1 port
```

## 10. `gpio8`

```mermaid
flowchart LR
    classDef port fill:none,stroke:none

    I1["clk"] --- M["gpio8"]
    I2["rst"] --- M
    I3["io_addr[7:0]"] --- M
    I4["io_wdata[15:0]"] --- M
    I5["io_re"] --- M
    I6["io_we"] --- M
    I7["gpio_i[7:0]"] --- M

    M --- O1["io_rdata[15:0]"]
    M --- O2["gpio_o[7:0]"]
    M --- O3["gpio_oe[7:0]"]

    class I1,I2,I3,I4,I5,I6,I7,O1,O2,O3 port
```

## 11. 端口数量核对

| 模块 | 输入 | 输出 | `inout` | 总端口 |
|---|---:|---:|---:|---:|
| `system_top` | 2 | 0 | 1 | 3 |
| `reset_conditioner` | 2 | 1 | 0 | 3 |
| `instruction_memory` | 1 | 1 | 0 | 2 |
| `cpu_core` | 4 | 5 | 0 | 9 |
| `controller` | 1 | 12 | 0 | 13 |
| `datapath` | 16 | 5 | 0 | 21 |
| `register_file` | 7 | 2 | 0 | 9 |
| `alu` | 3 | 1 | 0 | 4 |
| `gpio8` | 7 | 3 | 0 | 10 |
| **合计** | **43** | **30** | **1** | **74** |

`INIT_FILE` 是 elaboration 参数，不属于输入端口，因此不计入74个模块端口。
