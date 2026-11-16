`timescale 1ns/1ps

module instruction_class_tb #(
    parameter integer CLASS_ID = 1
);
    reg clk = 1'b0;
    reg rst = 1'b1;
    reg [15:0] program [0:255];
    wire [7:0] mem_addr;
    wire [15:0] instruction = program[mem_addr];
    wire [7:0] io_addr;
    wire [15:0] io_wdata;
    wire io_re;
    wire io_we;
    wire [15:0] io_rdata = (io_re && io_addr == 8'h31) ? 16'hBEEF : 16'h0000;

    integer index;
    integer errors = 0;
    integer expected_cycles = 0;
    integer io_write_count = 0;
    reg [7:0] captured_io_addr = 8'h00;
    reg [15:0] captured_io_data = 16'h0000;

    cpu_core dut (
        .clk(clk),
        .rst(rst),
        .instruction(instruction),
        .io_rdata(io_rdata),
        .mem_addr(mem_addr),
        .io_addr(io_addr),
        .io_wdata(io_wdata),
        .io_re(io_re),
        .io_we(io_we)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (io_we) begin
            io_write_count <= io_write_count + 1;
            captured_io_addr <= io_addr;
            captured_io_data <= io_wdata;
        end
    end

    // Stable aliases make each focused waveform easy to read and export.
    wire [3:0] opcode = instruction[15:12];
    wire [1:0] rd_addr = dut.rd_addr;
    wire [1:0] rs_addr = dut.rs_addr;
    wire [7:0] imm8 = dut.imm8;
    wire [2:0] alu_op = dut.alu_op;
    wire alu_src = dut.alu_src;
    wire reg_write = dut.reg_write;
    wire flags_write = dut.flags_write;
    wire branch_z = dut.branch_z;
    wire jump = dut.jump;
    wire wb_sel = dut.wb_sel;
    wire [7:0] pc_plus_one = dut.u_datapath.pc_plus_one;
    wire [7:0] pc_next = dut.u_datapath.pc_next;
    wire branch_taken = dut.u_datapath.branch_taken;
    wire [15:0] rd_data = dut.u_datapath.rd_data;
    wire [15:0] rs_data = dut.u_datapath.rs_data;
    wire [15:0] alu_b = dut.u_datapath.alu_b;
    wire [15:0] alu_result = dut.u_datapath.alu_result;
    wire [15:0] writeback_data = dut.u_datapath.writeback_data;
    wire z_flag = dut.u_datapath.z_flag;
    wire n_flag = dut.u_datapath.n_flag;
    wire c_flag = dut.u_datapath.c_flag;
    wire v_flag = dut.u_datapath.v_flag;
    wire [15:0] r0 = dut.u_datapath.u_register_file.registers[0];
    wire [15:0] r1 = dut.u_datapath.u_register_file.registers[1];
    wire [15:0] r2 = dut.u_datapath.u_register_file.registers[2];
    wire [15:0] r3 = dut.u_datapath.u_register_file.registers[3];

    task expect16;
        input [15:0] actual;
        input [15:0] expected;
        input [8*32-1:0] label;
        begin
            if (actual !== expected) begin
                $display("ERROR class=%0d %0s expected=%h actual=%h", CLASS_ID, label, expected, actual);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        for (index = 0; index < 256; index = index + 1)
            program[index] = 16'hF000;

        case (CLASS_ID)
            1: begin
                // Data movement: MOVI and MOVR.
                program[8'h00] = 16'h0012; // MOVI R0, 0x12
                program[8'h01] = 16'h0434; // MOVI R1, 0x34
                program[8'h02] = 16'h1800; // MOVR R2, R0
                program[8'h03] = 16'h1D00; // MOVR R3, R1
                program[8'h04] = 16'hA004; // JUMP 0x04
                expected_cycles = 4;
            end
            2: begin
                // Arithmetic and compare: ADDI, ADDR, SUB, CMP.
                program[8'h00] = 16'h0005; // MOVI R0, 0x05
                program[8'h01] = 16'h0403; // MOVI R1, 0x03
                program[8'h02] = 16'h2002; // ADDI R0, 0x02
                program[8'h03] = 16'h3100; // ADDR R0, R1
                program[8'h04] = 16'h5100; // SUB  R0, R1
                program[8'h05] = 16'h6000; // CMP  R0, R0 -> Z=1, no register write
                program[8'h06] = 16'hA006; // JUMP 0x06
                expected_cycles = 6;
            end
            3: begin
                // Logic: AND, OR, XOR.
                program[8'h00] = 16'h00AA; // MOVI R0, 0xAA
                program[8'h01] = 16'h040F; // MOVI R1, 0x0F
                program[8'h02] = 16'h7100; // AND R0, R1
                program[8'h03] = 16'h9100; // OR  R0, R1
                program[8'h04] = 16'h4100; // XOR R0, R1
                program[8'h05] = 16'hA005; // JUMP 0x05
                expected_cycles = 5;
            end
            4: begin
                // Control flow: JZ not taken, JZ taken, and JUMP.
                program[8'h00] = 16'h0001; // MOVI R0, 0x01
                program[8'h01] = 16'h0402; // MOVI R1, 0x02
                program[8'h02] = 16'h6100; // CMP R0, R1 -> Z=0
                program[8'h03] = 16'h8005; // JZ  0x05, not taken
                program[8'h04] = 16'h0811; // MOVI R2, 0x11
                program[8'h05] = 16'h6000; // CMP R0, R0 -> Z=1
                program[8'h06] = 16'h8008; // JZ  0x08, taken
                program[8'h07] = 16'h0822; // skipped
                program[8'h08] = 16'hA00A; // JUMP 0x0A
                program[8'h09] = 16'h0833; // skipped
                program[8'h0A] = 16'h0C44; // MOVI R3, 0x44
                program[8'h0B] = 16'hA00B; // JUMP 0x0B
                expected_cycles = 9;
            end
            5: begin
                // External IO: INP then OUP.
                program[8'h00] = 16'hB031; // INP R0, 0x31
                program[8'h01] = 16'hC030; // OUP 0x30, R0
                program[8'h02] = 16'hA002; // JUMP 0x02
                expected_cycles = 2;
            end
            default: begin
                $fatal(1, "Unsupported CLASS_ID=%0d", CLASS_ID);
            end
        endcase

        repeat (2) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;
        repeat (expected_cycles) @(posedge clk);
        #1;

        case (CLASS_ID)
            1: begin
                expect16(r0, 16'h0012, "MOVI R0");
                expect16(r1, 16'h0034, "MOVI R1");
                expect16(r2, 16'h0012, "MOVR R2,R0");
                expect16(r3, 16'h0034, "MOVR R3,R1");
            end
            2: begin
                expect16(r0, 16'h0007, "arithmetic R0");
                expect16(r1, 16'h0003, "arithmetic R1");
                if ({z_flag,n_flag,c_flag,v_flag} !== 4'b1010) begin
                    $display("ERROR arithmetic flags expected ZNCV=1010 actual=%b",
                             {z_flag,n_flag,c_flag,v_flag});
                    errors = errors + 1;
                end
            end
            3: begin
                expect16(r0, 16'h0000, "logic R0");
                expect16(r1, 16'h000F, "logic R1");
            end
            4: begin
                expect16(r2, 16'h0011, "JZ not-taken path");
                expect16(r3, 16'h0044, "JZ/JUMP target path");
                if (mem_addr !== 8'h0B) begin
                    $display("ERROR branch final PC expected=0B actual=%h", mem_addr);
                    errors = errors + 1;
                end
            end
            5: begin
                expect16(r0, 16'hBEEF, "INP result");
                if (io_write_count !== 1 || captured_io_addr !== 8'h30 ||
                    captured_io_data !== 16'hBEEF) begin
                    $display("ERROR IO write count=%0d addr=%h data=%h",
                             io_write_count, captured_io_addr, captured_io_data);
                    errors = errors + 1;
                end
            end
        endcase

        if (errors == 0)
            $display("INSTRUCTION_CLASS_%0d: TEST_PASS", CLASS_ID);
        else
            $fatal(1, "INSTRUCTION_CLASS_%0d: TEST_FAIL errors=%0d", CLASS_ID, errors);
        $finish;
    end

    initial begin
        #500;
        $fatal(1, "INSTRUCTION_CLASS_%0d: WATCHDOG_TIMEOUT", CLASS_ID);
    end
endmodule

module tb_class_move;
    instruction_class_tb #(.CLASS_ID(1)) u_test();
endmodule

module tb_class_arithmetic;
    instruction_class_tb #(.CLASS_ID(2)) u_test();
endmodule

module tb_class_logic;
    instruction_class_tb #(.CLASS_ID(3)) u_test();
endmodule

module tb_class_branch;
    instruction_class_tb #(.CLASS_ID(4)) u_test();
endmodule

module tb_class_io;
    instruction_class_tb #(.CLASS_ID(5)) u_test();
endmodule
