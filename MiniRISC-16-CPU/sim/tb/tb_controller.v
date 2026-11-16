`timescale 1ns/1ps

module tb_controller;
    reg  [15:0] instruction;
    wire [1:0] rd_addr;
    wire [1:0] rs_addr;
    wire [7:0] imm8;
    wire [2:0] alu_op;
    wire alu_src;
    wire reg_write;
    wire z_write;
    wire branch_z;
    wire jump;
    wire wb_sel;
    wire io_re;
    wire io_we;
    wire [10:0] controls = {alu_op, alu_src, reg_write, z_write,
                            branch_z, jump, wb_sel, io_re, io_we};
    integer errors;

    controller dut (
        .instruction (instruction),
        .rd_addr     (rd_addr),
        .rs_addr     (rs_addr),
        .imm8        (imm8),
        .alu_op      (alu_op),
        .alu_src     (alu_src),
        .reg_write   (reg_write),
        .z_write     (z_write),
        .branch_z    (branch_z),
        .jump        (jump),
        .wb_sel      (wb_sel),
        .io_re       (io_re),
        .io_we       (io_we)
    );

    task check_opcode;
        input [3:0]  opcode;
        input [10:0] expected_controls;
        begin
            instruction = {opcode, 2'b10, 2'b01, 8'hA5};
            #1;
            if (rd_addr !== 2'b10 || rs_addr !== 2'b01 || imm8 !== 8'hA5) begin
                $display("ERROR tb_controller: field extraction opcode=%h rd=%b rs=%b imm=%h",
                         opcode, rd_addr, rs_addr, imm8);
                errors = errors + 1;
            end
            if (controls !== expected_controls) begin
                $display("ERROR tb_controller: opcode=%h expected=%b actual=%b",
                         opcode, expected_controls, controls);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        check_opcode(4'h0, {3'b000,1'b1,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0});
        check_opcode(4'h1, {3'b000,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0});
        check_opcode(4'h2, {3'b001,1'b1,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0});
        check_opcode(4'h3, {3'b001,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0});
        check_opcode(4'h4, {3'b101,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0});
        check_opcode(4'h5, {3'b010,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0});
        check_opcode(4'h6, {3'b010,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0});
        check_opcode(4'h7, {3'b011,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0});
        check_opcode(4'h8, {3'b000,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0});
        check_opcode(4'h9, {3'b100,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0});
        check_opcode(4'hA, {3'b000,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0});
        check_opcode(4'hB, {3'b000,1'b0,1'b1,1'b0,1'b0,1'b0,1'b1,1'b1,1'b0});
        check_opcode(4'hC, {3'b000,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1});
        check_opcode(4'hD, 11'b000_0_0_0_0_0_0_0_0);
        check_opcode(4'hE, 11'b000_0_0_0_0_0_0_0_0);
        check_opcode(4'hF, 11'b000_0_0_0_0_0_0_0_0);

        if (errors == 0)
            $display("tb_controller: TEST PASS");
        else
            $display("tb_controller: TEST FAIL errors=%0d", errors);
        $finish;
    end
endmodule
