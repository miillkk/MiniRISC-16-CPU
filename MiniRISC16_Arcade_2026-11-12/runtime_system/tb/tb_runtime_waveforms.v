`timescale 1ns/1ps

// Focused waveform testbenches for the current non-HDMI Runtime Arcade RTL.
// These are verification-only modules; no design RTL is changed.

module tb_runtime_running_light_wave;
    reg clk = 1'b0;
    reg resetn = 1'b0;
    reg uart_rx = 1'b1;
    reg [7:0] switches = 8'h00;
    wire uart_tx;
    wire [7:0] led;
    wire [7:0] seg_low;
    wire [7:0] seg_high;
    wire [7:0] digit_enable;

    integer index;
    integer cycle = 0;
    reg seen_led_01 = 1'b0;
    reg seen_led_02 = 1'b0;
    reg [8*1024-1:0] running_light_mem;

    runtime_board_top #(
        .UART_CLKS_PER_BIT(2),
        .BASE_TICK_CYCLES(6),
        .SCAN_DIVIDER(4)
    ) dut (
        .clk_100mhz(clk),
        .resetn(resetn),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .switches(switches),
        .led(led),
        .seg_low(seg_low),
        .seg_high(seg_high),
        .digit_enable(digit_enable)
    );

    always #5 clk = ~clk;

    // Stable aliases make the required Vivado waveform easy to read.
    wire        rst         = dut.rst;
    wire [9:0]  pc          = dut.u_runtime_soc.program_addr;
    wire [15:0] instruction = dut.u_runtime_soc.instruction;
    wire        io_we       = dut.u_runtime_soc.io_we;
    wire [7:0]  io_addr     = dut.u_runtime_soc.io_addr;
    wire [15:0] io_wdata    = dut.u_runtime_soc.io_wdata;

    always @(posedge clk) begin
        cycle <= cycle + 1;
        if (!rst && io_we && io_addr == 8'h30) begin
            if (!seen_led_01 && io_wdata[7:0] == 8'h01) begin
                seen_led_01 <= 1'b1;
                $display("RUNNING_LIGHT_LED_WRITE cycle=%0d pc=%03h instruction=%04h value=01",
                         cycle, pc, instruction);
            end
            if (seen_led_01 && io_wdata[7:0] == 8'h02) begin
                seen_led_02 <= 1'b1;
                $display("RUNNING_LIGHT_LED_WRITE cycle=%0d pc=%03h instruction=%04h value=02",
                         cycle, pc, instruction);
            end
        end
    end

    initial begin
        if (!$test$plusargs("NO_TB_VCD")) begin
            $dumpfile("reports/waveforms/current_terminal/runtime_running_light_io.vcd");
            $dumpvars(0, clk, rst, pc, instruction, io_we, io_addr, io_wdata, led);
        end

        // The synthesizable program RAM defaults to Snake. For this focused
        // test, load the current Runtime Arcade Running Light program while the
        // full board design remains in reset.
        #1;
        for (index = 0; index < 1024; index = index + 1)
            dut.u_runtime_soc.u_program_memory.memory[index] = 16'hFFFF;
        if (!$value$plusargs("RUNNING_LIGHT_MEM=%s", running_light_mem))
            running_light_mem = "games/running_light/program/running_light.mem";
        $readmemh(running_light_mem, dut.u_runtime_soc.u_program_memory.memory);

        repeat (4) @(posedge clk);
        @(negedge clk);
        resetn = 1'b1;

        wait (seen_led_02);
        @(posedge clk);
        #1;
        if (led !== 8'h02)
            $fatal(1, "Running Light LED output mismatch: expected=02 actual=%h", led);
        $display("tb_runtime_running_light_wave: TEST PASS");
        $finish;
    end

    initial begin
        #200000;
        $fatal(1, "tb_runtime_running_light_wave: WATCHDOG TIMEOUT");
    end
endmodule


module tb_runtime_extended_isa_wave;
    reg clk = 1'b0;
    reg rst = 1'b1;
    reg [15:0] rom [0:1023];
    wire [9:0] pc;
    wire [15:0] instruction = rom[pc];
    wire [7:0] io_addr;
    wire [15:0] io_wdata;
    wire io_re;
    wire io_we;
    wire [7:0] data_addr;
    wire [15:0] data_wdata;
    wire [15:0] data_rdata;
    wire data_re;
    wire data_we;
    wire z_flag;
    wire n_flag;
    wire c_flag;
    wire v_flag;
    wire [3:0] opcode = instruction[15:12];
    wire long_jump = dut.long_jump;
    wire [9:0] pc_next = dut.u_datapath.pc_next;
    wire [15:0] r0 = dut.u_datapath.u_register_file.registers[0];
    wire [15:0] r1 = dut.u_datapath.u_register_file.registers[1];
    wire [15:0] r2 = dut.u_datapath.u_register_file.registers[2];
    wire [15:0] r3 = dut.u_datapath.u_register_file.registers[3];
    wire        reg_write = dut.reg_write;
    wire        flags_write = dut.flags_write;
    wire        branch_z = dut.branch_z;
    wire        jump = dut.jump;
    wire        branch_taken = dut.u_datapath.branch_taken;
    wire [15:0] rd_data = dut.u_datapath.rd_data;
    wire [15:0] rs_data = dut.u_datapath.rs_data;
    wire [15:0] alu_result = dut.u_datapath.alu_result;
    wire [15:0] writeback_data = dut.u_datapath.writeback_data;

    integer index;
    integer io_write_count = 0;
    reg [7:0] captured_io_addr = 8'h00;
    reg [15:0] captured_io_data = 16'h0000;

    always #5 clk = ~clk;

    cpu_core dut (
        .clk(clk),
        .rst(rst),
        .instruction(instruction),
        .io_rdata(16'h0000),
        .data_rdata(data_rdata),
        .mem_addr(pc),
        .io_addr(io_addr),
        .io_wdata(io_wdata),
        .io_re(io_re),
        .io_we(io_we),
        .data_addr(data_addr),
        .data_wdata(data_wdata),
        .data_re(data_re),
        .data_we(data_we),
        .z_flag(z_flag),
        .n_flag(n_flag),
        .c_flag(c_flag),
        .v_flag(v_flag)
    );

    data_memory ram (
        .clk(clk),
        .write_enable(data_we),
        .address(data_addr),
        .write_data(data_wdata),
        .read_data(data_rdata)
    );

    always @(posedge clk) begin
        if (io_we) begin
            io_write_count <= io_write_count + 1;
            captured_io_addr <= io_addr;
            captured_io_data <= io_wdata;
        end
    end

    initial begin
        if (!$test$plusargs("NO_TB_VCD")) begin
            $dumpfile("reports/waveforms/current_terminal/runtime_extended_isa.vcd");
            $dumpvars(0, clk, rst, pc, pc_next, instruction, opcode,
                         data_we, data_re, data_addr, data_wdata, data_rdata,
                         reg_write, flags_write, branch_z, branch_taken,
                         jump, long_jump, io_we, io_addr, io_wdata,
                         z_flag, rd_data, rs_data, alu_result, writeback_data,
                         r0, r1, r2, r3);
        end

        for (index = 0; index < 1024; index = index + 1)
            rom[index] = 16'hF202;

        // New Runtime ISA sequence:
        // STR [0x22] <- 0x005A, LDR R2 <- [0x22], conditional branch,
        // then JMPA from page 0 to page 2 and produce a visible I/O write.
        rom[10'h000] = 16'h0022; // MOVI R0, 0x22
        rom[10'h001] = 16'h045A; // MOVI R1, 0x5A
        rom[10'h002] = 16'hE100; // STR  R0, R1
        rom[10'h003] = 16'hD800; // LDR  R2, R0
        rom[10'h004] = 16'h6600; // CMP  R1, R2 -> Z=1
        rom[10'h005] = 16'h8008; // JZ   0x008
        rom[10'h006] = 16'h0CEE; // skipped
        rom[10'h008] = 16'hA00A; // JUMP 0x00A (same 256-word page)
        rom[10'h00A] = 16'hF200; // JMPA 0x200 (10-bit absolute target)
        rom[10'h200] = 16'h0CA5; // MOVI R3, 0xA5
        rom[10'h201] = 16'hC330; // OUP  0x30, R3
        rom[10'h202] = 16'hF202; // JMPA 0x202

        repeat (3) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;
        repeat (14) @(posedge clk);
        #1;

        if (ram.memory[8'h22] !== 16'h005A)
            $fatal(1, "STR failed: memory[22]=%h", ram.memory[8'h22]);
        if (r2 !== 16'h005A)
            $fatal(1, "LDR failed: R2=%h", r2);
        if (r3 !== 16'h00A5)
            $fatal(1, "JMPA target execution failed: R3=%h", r3);
        if (pc !== 10'h202)
            $fatal(1, "10-bit JMPA final PC mismatch: pc=%h", pc);
        if (io_write_count !== 1 || captured_io_addr !== 8'h30 ||
            captured_io_data !== 16'h00A5)
            $fatal(1, "I/O proof write mismatch: count=%0d addr=%h data=%h",
                   io_write_count, captured_io_addr, captured_io_data);

        $display("tb_runtime_extended_isa_wave: TEST PASS");
        $finish;
    end

    initial begin
        #1000;
        $fatal(1, "tb_runtime_extended_isa_wave: WATCHDOG TIMEOUT");
    end
endmodule
