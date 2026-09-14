`timescale 1ns/1ps

module cpu_core (
    input  wire        clk,
    input  wire        rst,
    input  wire [15:0] instruction,
    input  wire [15:0] io_rdata,
    output wire [7:0]  mem_addr,
    output wire [7:0]  io_addr,
    output wire [15:0] io_wdata,
    output wire        io_re,
    output wire        io_we
);
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
    wire control_io_re;
    wire control_io_we;

    controller u_controller (
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
        .io_re       (control_io_re),
        .io_we       (control_io_we)
    );

    datapath u_datapath (
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
endmodule
