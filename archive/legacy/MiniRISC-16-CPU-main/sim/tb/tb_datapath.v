`timescale 1ns/1ps

module tb_datapath;
    reg clk;
    reg rst;
    reg [15:0] instruction;
    reg [15:0] io_rdata;
    reg [2:0] alu_op;
    reg alu_src;
    reg reg_write;
    reg z_write;
    reg branch_z;
    reg jump;
    reg wb_sel;
    reg control_io_re;
    reg control_io_we;
    wire [1:0] rd_addr = instruction[11:10];
    wire [1:0] rs_addr = instruction[9:8];
    wire [7:0] imm8 = instruction[7:0];
    wire [7:0] mem_addr;
    wire [7:0] io_addr;
    wire [15:0] io_wdata;
    wire io_re;
    wire io_we;
    integer errors;

    datapath dut (
        .clk           (clk),
        .rst           (rst),
        .instruction   (instruction),
        .io_rdata      (io_rdata),
        .rd_addr       (rd_addr),
        .rs_addr       (rs_addr),
        .imm8          (imm8),
        .alu_op        (alu_op),
        .alu_src       (alu_src),
        .reg_write     (reg_write),
        .z_write       (z_write),
        .branch_z      (branch_z),
        .jump          (jump),
        .wb_sel        (wb_sel),
        .control_io_re (control_io_re),
        .control_io_we (control_io_we),
        .mem_addr      (mem_addr),
        .io_addr       (io_addr),
        .io_wdata      (io_wdata),
        .io_re         (io_re),
        .io_we         (io_we)
    );

    always #5 clk = ~clk;

    task step;
        input [15:0] test_instruction;
        input [2:0]  test_alu_op;
        input        test_alu_src;
        input        test_reg_write;
        input        test_z_write;
        input        test_branch_z;
        input        test_jump;
        input        test_wb_sel;
        begin
            @(negedge clk);
            instruction = test_instruction;
            alu_op       = test_alu_op;
            alu_src      = test_alu_src;
            reg_write    = test_reg_write;
            z_write      = test_z_write;
            branch_z     = test_branch_z;
            jump         = test_jump;
            wb_sel       = test_wb_sel;
            @(posedge clk);
            #1;
        end
    endtask

    task expect16;
        input [15:0] actual;
        input [15:0] expected;
        input [8*32-1:0] label_text;
        begin
            if (actual !== expected) begin
                $display("ERROR tb_datapath: %0s expected=%h actual=%h", label_text, expected, actual);
                errors = errors + 1;
            end
        end
    endtask

    task expect8;
        input [7:0] actual;
        input [7:0] expected;
        input [8*32-1:0] label_text;
        begin
            if (actual !== expected) begin
                $display("ERROR tb_datapath: %0s expected=%h actual=%h", label_text, expected, actual);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        instruction = 16'hC010;
        io_rdata = 16'hBEEF;
        alu_op = 3'b000;
        alu_src = 1'b0;
        reg_write = 1'b0;
        z_write = 1'b0;
        branch_z = 1'b0;
        jump = 1'b0;
        wb_sel = 1'b0;
        control_io_re = 1'b1;
        control_io_we = 1'b1;
        errors = 0;

        repeat (2) @(posedge clk);
        #1;
        expect8(mem_addr, 8'h00, "reset PC");
        if (io_re !== 1'b0 || io_we !== 1'b0) begin
            $display("ERROR tb_datapath: I/O enable active during reset");
            errors = errors + 1;
        end
        expect16(dut.u_register_file.registers[0], 16'h0000, "reset R0");
        expect16(dut.u_register_file.registers[1], 16'h0000, "reset R1");
        expect16(dut.u_register_file.registers[2], 16'h0000, "reset R2");
        expect16(dut.u_register_file.registers[3], 16'h0000, "reset R3");

        rst = 1'b0;
        control_io_re = 1'b0;
        control_io_we = 1'b0;

        step(16'h00FF, 3'b000, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0);
        step(16'h0401, 3'b000, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0);
        step(16'h1800, 3'b000, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0);
        step(16'h2801, 3'b001, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0);
        step(16'h3100, 3'b001, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0);
        step(16'h0C55, 3'b000, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0);

        expect16(dut.u_register_file.registers[0], 16'h0100, "R0 ADDR");
        expect16(dut.u_register_file.registers[1], 16'h0001, "R1 write");
        expect16(dut.u_register_file.registers[2], 16'h0100, "R2 ADDI");
        expect16(dut.u_register_file.registers[3], 16'h0055, "R3 write");

        step(16'h6200, 3'b010, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0);
        if (dut.z_flag !== 1'b1) begin
            $display("ERROR tb_datapath: equal CMP did not set Z");
            errors = errors + 1;
        end
        expect16(dut.u_register_file.registers[0], 16'h0100, "CMP no Rd write");

        step(16'h0000, 3'b000, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0);
        if (dut.z_flag !== 1'b1) begin
            $display("ERROR tb_datapath: non-CMP changed Z");
            errors = errors + 1;
        end
        step(16'h6100, 3'b010, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0);
        if (dut.z_flag !== 1'b0) begin
            $display("ERROR tb_datapath: unequal CMP did not clear Z");
            errors = errors + 1;
        end

        step(16'h8030, 3'b000, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0);
        expect8(mem_addr, 8'h0A, "JZ not taken");
        step(16'hA020, 3'b000, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0);
        expect8(mem_addr, 8'h20, "JUMP target");
        step(16'h6500, 3'b010, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0);
        step(16'h8040, 3'b000, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0);
        expect8(mem_addr, 8'h40, "JZ taken");
        step(16'hA0FF, 3'b000, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0);
        expect8(mem_addr, 8'hFF, "JUMP to FF");
        step(16'hF000, 3'b000, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);
        expect8(mem_addr, 8'h00, "PC wrap FF to 00");

        if ((^{mem_addr, dut.z_flag, dut.u_register_file.registers[0],
               dut.u_register_file.registers[1], dut.u_register_file.registers[2],
               dut.u_register_file.registers[3]}) === 1'bx) begin
            $display("ERROR tb_datapath: unknown state detected");
            errors = errors + 1;
        end

        if (errors == 0)
            $display("tb_datapath: TEST PASS");
        else
            $display("tb_datapath: TEST FAIL errors=%0d", errors);
        $finish;
    end
endmodule
