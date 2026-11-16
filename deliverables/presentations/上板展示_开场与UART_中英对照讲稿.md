# MiniRISC-16 上板展示讲稿：开场与 UART（中英对照）

> 中文与英文按段对应。代码只展示一次，供两种语言的讲解共同引用。方括号中的内容是演示提示，不必照读。
>
> The Chinese and English passages correspond paragraph by paragraph. Code appears once for both versions. Text in brackets is a presentation cue and need not be spoken.

## 1. 开场：上板运行的整体成果 / Opening: What Runs on the Board

**中文：** 前面已经介绍了 MiniRISC-16 CPU 的结构和指令执行过程。接下来我介绍这颗 CPU 放到 FPGA 开发板上之后，实际运行了哪些程序，以及程序如何与板上的外设交互。

**English:** We have already covered the architecture of the MiniRISC-16 CPU and how it executes instructions. I will now show what programs run on this CPU after it is deployed on the FPGA board, and how those programs interact with the board's peripherals.

**中文：** 目前我们在同一套 Runtime 硬件系统上实现了三个项目：流水灯、2048 和贪吃蛇。它们共用 CPU、程序存储器、数据存储器、UART、定时器和其他外设。切换项目时，我们通过串口上传不同的机器码程序，不需要重新设计 CPU 或重新生成一套游戏专用硬件。

**English:** We have implemented three projects on the same runtime hardware system: running lights, 2048, and Snake. They share the CPU, program memory, data memory, UART, timer, and other peripherals. To switch projects, we upload a different machine-code program over UART. We do not redesign the CPU or generate separate game-specific hardware.

**中文：** 这里有一个容易混淆的地方：统一选择菜单运行在电脑端。电脑端菜单负责选择程序、调用 UART Loader 上传程序，并打开对应的显示终端。板上的 CPU 在一个时刻执行其中一个程序，并不同时执行三个游戏，也不负责绘制电脑端菜单。

**English:** One distinction is important here: the unified selection menu runs on the PC. It lets us choose a program, invokes the UART Loader to upload it, and opens the corresponding display terminal. The CPU on the board runs one program at a time. It does not run all three applications simultaneously, and it does not draw the menu on the PC.

**演示提示 / Presentation cue:** 展示三个项目的效果图；只简要指出 LED、2048 棋盘和贪吃蛇地图，后面逐项讲解。 / Show the three projects briefly: point out the LEDs, the 2048 board, and the Snake map. Explain each one later.

## 2. UART：程序上传与运行交互 / UART: Program Upload and Runtime I/O

**中文：** 这一页用一张模式对照图讲完整个 UART 的用途，口头讲解可分为“上传程序”和“运行时交互”两段：

**English:** This slide uses a mode comparison to explain both roles of UART. I will discuss them in two parts: program upload and runtime communication.

| 模式 / Mode | SW7 | UART 接管者 / UART owner | 电脑发送 / PC sends | 板端发送 / Board sends | CPU 状态 / CPU state |
|---|---:|---|---|---|---|
| 程序加载 / Program upload | 1 | UART Loader | 机器码程序 / Machine-code program | 上传应答 / Upload response | 保持复位 / Held in reset |
| 程序运行 / Program execution | 0 | CPU 的 UART 外设 / CPU UART peripheral | 按键命令 / Key commands | 运行状态帧 / Runtime state frames | 执行程序 / Executing the program |

### 2.1 程序如何上传、切换和启动 / How Programs Are Uploaded, Switched, and Started

**中文：** 三个项目能复用同一套硬件，关键在于程序存储器是可写的。它的容量为 1K×16 位，每个地址存一条 16 位机器码。我们先把汇编程序转换为机器码镜像，再通过 UART Loader 将镜像写入程序存储器。

**English:** The reason these three projects can share one hardware system is that the program memory is writable. Its capacity is 1K by 16 bits, so each address holds one 16-bit machine instruction. We first assemble the programs into machine-code images, and then use the UART Loader to write those images into program memory.

**中文：** 上板操作中，SW7 是加载与运行模式开关。SW7 为 1 时，CPU 保持复位，Loader 接收电脑发送的机器码；上传完成后，把 SW7 拨回 0，CPU 解除复位，从程序地址 `0x000` 开始执行刚上传的程序。

**English:** On the board, SW7 selects upload mode or execution mode. When SW7 is 1, the CPU is held in reset while the Loader receives machine code from the PC. Once the upload is complete, we switch SW7 back to 0. The CPU leaves reset and starts executing the newly uploaded program from address `0x000`.

**中文：** 顶层 RTL 中，与这个过程直接相关的代码是：

**English:** The following top-level RTL directly controls this process:

```verilog
wire cpu_rst = rst | load_mode;

assign uart_tx = load_mode ? loader_uart_tx : cpu_uart_tx;
```

**中文：** 第一行把加载模式并入 CPU 复位条件，所以写程序期间 CPU 不会一边运行、一边读取正在修改的指令。第二行选择 UART 的发送端：加载模式时发送 Loader 的应答；运行模式时发送 CPU 程序的输出。两种模式共用开发板上的同一组串口引脚。

**English:** The first line includes upload mode in the CPU reset condition. This prevents the CPU from running while its instructions are being modified. The second line selects the UART transmitter: in upload mode, it sends responses from the Loader; in execution mode, it sends output from the CPU program. Both modes use the same UART pins on the board.

**中文：** 程序存储器的读写路径也很直观：

**English:** The read and write paths of program memory are straightforward:

```verilog
always @(posedge clk)
    if (loader_we) memory[loader_addr] <= loader_wdata;

assign instruction = memory[cpu_addr];
```

**中文：** `loader_we` 为 1 时，Loader 按 `loader_addr` 写入一条 16 位机器码；CPU 运行时则按 `cpu_addr` 取出指令。这里的 `instruction` 最终送到 CPU 核心执行。

**English:** When `loader_we` is 1, the Loader writes a 16-bit instruction to `loader_addr`. During execution, the CPU reads the instruction at `cpu_addr`. The resulting `instruction` is then passed to the CPU core for execution.

**中文：** UART 每次传送一个 8 位字节，而程序字是 16 位，因此 Loader 把高、低两个字节拼成一个程序字。以下为 `program_loader.v` 中的连续代码：

**English:** UART transfers one 8-bit byte at a time, whereas each program word is 16 bits. The Loader therefore combines a high byte and a low byte into one program word. This is a continuous excerpt from `program_loader.v`:

```verilog
ST_DATA_L: begin
    program_addr <= word_index[9:0];
    program_wdata <= {data_high, rx_data};
    program_we <= 1;
    checksum <= checksum + {data_high, rx_data};
    word_index <= word_index + 1'b1;
    if (word_index + 1'b1 == word_count)
        state <= ST_SUM_H;
    else
        state <= ST_DATA_H;
end
```

**中文：** `data_high` 是上一个收到的高字节，`rx_data` 是当前收到的低字节。两者拼接后写到程序存储器，同时累加校验和。接收完全部程序字后，Loader 检查电脑发送的校验和，并回传成功或失败应答。

**English:** `data_high` is the high byte received previously, and `rx_data` is the current low byte. The Loader concatenates them, writes the word to program memory, and adds it to the checksum. After receiving all program words, the Loader checks the checksum sent by the PC and returns a success or failure response.

**现场操作 / Live demonstration:** SW7 拨到 1，观察数码管 `10AD`；电脑端选择项目并等待 `UPLOAD PASS`；SW7 拨回 0，展示程序运行。切换下一项目时重复这一过程。 / Set SW7 to 1 and point out `10AD` on the seven-segment display. Select a project on the PC and wait for `UPLOAD PASS`. Set SW7 back to 0 and show the program running. Repeat these steps when switching projects.

> 代码位置 / Code locations: [顶层模式切换 / Top-level mode selection](../MiniRISC-16-CPU/refactored_design/runtime_system/rtl/top/runtime_soc.v)、[程序存储器 / Program memory](../MiniRISC-16-CPU/refactored_design/runtime_system/rtl/memory/runtime_program_memory.v)、[UART Loader](../MiniRISC-16-CPU/refactored_design/runtime_system/rtl/peripherals/program_loader.v)。

### 2.2 运行时电脑与 CPU 如何交换数据 / How the PC and CPU Communicate During Execution

**中文：** UART 在当前系统中有两种用途。第一种是刚才介绍的程序上传。第二种是程序运行时的输入输出：电脑把按键发给 CPU，CPU 把游戏状态发给电脑，电脑端终端根据状态数据绘制画面。

**English:** UART has two roles in this system. The first is the program upload just described. The second is runtime input and output: the PC sends key presses to the CPU, and the CPU sends game-state data back to the PC. The PC terminal draws the display from that data.

**中文：** 开发板上的 CP2103 是现成的 USB 转串口芯片，负责电脑 USB 与 UART 信号之间的转换。FPGA 内部的接收模块 `uart_rx`、发送模块 `uart_tx` 和 CPU 访问接口 `uart_port` 是工程中的 Verilog 实现。串口参数是 115200 波特率、8 位数据、无校验、1 位停止位，也就是 115200、8N1。

**English:** The board's CP2103 is an off-the-shelf USB-to-UART chip that converts between the PC's USB connection and UART signals. Inside the FPGA, the receive module `uart_rx`, transmit module `uart_tx`, and CPU interface `uart_port` are implemented in Verilog in our project. The serial configuration is 115200 baud, eight data bits, no parity, and one stop bit: 115200, 8N1.

**中文：** 接收器的核心是四状态状态机：

**English:** The receiver is built around a four-state machine:

```verilog
localparam IDLE = 2'd0, START = 2'd1,
           DATA = 2'd2, STOP = 2'd3;
```

**中文：** 空闲状态等待起始位；检测到起始位后，在位周期的中间确认它，再依次采样 8 个数据位；最后检查停止位。如果帧有效，就把收到的字节放到 `data` 输出，并产生一个 `valid` 脉冲。`uart_rx` 还用两级寄存器同步外部输入，降低异步输入直接进入状态机的风险。

**English:** The idle state waits for a start bit. After detecting one, the receiver confirms it near the middle of the bit period, samples the eight data bits in order, and finally checks the stop bit. If the frame is valid, it places the received byte on `data` and produces a `valid` pulse. `uart_rx` also synchronizes the external input with two registers to reduce the risk of feeding an asynchronous signal directly into the state machine.

**中文：** 发送器则在 CPU 写入一个字节后，将起始位、8 个数据位和停止位按位送出：

**English:** Once the CPU writes a byte, the transmitter sends its start bit, eight data bits, and stop bit in sequence:

```verilog
assign ready = ~busy;

if (write_enable) begin
    shift <= {1'b1, write_data, 1'b0};
    tx <= 1'b0;
    busy <= 1'b1;
end
```

**中文：** `ready` 表示可以接收下一个待发送字节。发送器忙时，CPU 程序需要等待，避免连续写入导致数据丢失。

**English:** `ready` means the transmitter can accept the next byte. While it is busy, the CPU program must wait before writing again to avoid losing data.

**中文：** CPU 访问 UART 时不需要直接控制起始位和停止位，而是使用输入输出端口。`0x10` 是 UART 数据端口，读这个地址取得收到的字节，写这个地址发送字节；`0x11` 是状态端口。地址译码 RTL 如下：

**English:** The CPU does not control start and stop bits directly. Instead, it accesses UART through I/O ports. `0x10` is the UART data port: reading it retrieves a received byte, and writing it sends a byte. `0x11` is the status port. The address-decoding RTL is:

```verilog
assign uart_data_read = read_enable && address == 8'h10;
assign uart_data_write = write_enable && address == 8'h10;
```

**中文：** `uart_port` 里的状态寄存器组织为：

**English:** The status register in `uart_port` is organized as follows:

```verilog
assign status_rdata = {13'h0000, overrun, tx_ready, rx_valid};
```

**中文：** 其中最低位 `rx_valid` 表示已有一个接收字节，下一位 `tx_ready` 表示发送器空闲，`overrun` 表示前一个字节尚未读取时又收到新字节。

**English:** The least significant bit, `rx_valid`, indicates that a received byte is available. The next bit, `tx_ready`, indicates that the transmitter is idle. `overrun` means a new byte arrived before the previous one was read.

**中文：** CPU 程序接收按键时，先读取状态，再用按位与检查最低位：

**English:** To receive a key press, the CPU program first reads the status port and then uses a bitwise AND to check its least significant bit:

```asm
    INP  R0, 0x11
    MOVI R1, 0x01
    AND  R0, R1
    CMP  R0, R1
    JZ   READ_KEY
```

**中文：** 如果 `rx_valid` 为 1，程序再通过 `INP R0, 0x10` 取出按键。发送状态帧时则检查 `tx_ready` 对应的 `0x02` 位，准备好之后执行 `OUP 0x10, R0`。这就是 CPU 指令与 UART 外设之间的连接。

**English:** If `rx_valid` is 1, the program reads the key with `INP R0, 0x10`. To send a state frame, it checks the `0x02` bit corresponding to `tx_ready`, and then executes `OUP 0x10, R0` when the transmitter is ready. This is how CPU instructions connect to the UART peripheral.

**中文：** 电脑端的作用是发送控制字节、接收状态帧和绘制界面。2048 的合并规则、贪吃蛇的碰撞判断以及流水灯的下一灯位置，均由 FPGA 上的程序计算。

**English:** The PC sends control bytes, receives state frames, and draws the interface. The 2048 merge rules, Snake collision checks, and next LED position in the running-lights program are all computed by programs running on the FPGA CPU.

> 代码位置 / Code locations: [UART 接收 / UART receiver](../MiniRISC-16-CPU/refactored_design/runtime_system/rtl/peripherals/uart_rx.v)、[UART 发送 / UART transmitter](../MiniRISC-16-CPU/refactored_design/runtime_system/rtl/peripherals/uart_tx.v)、[CPU 端口封装 / CPU port interface](../MiniRISC-16-CPU/refactored_design/runtime_system/rtl/peripherals/uart_port.v)、[地址译码 / Address decoder](../MiniRISC-16-CPU/refactored_design/runtime_system/rtl/peripherals/io_decoder.v)。
