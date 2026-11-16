`timescale 1ns/1ps

module cpu_core (
    input  wire        clk,
    input  wire        rst,
    input  wire [15:0] instruction,
    input  wire [15:0] io_rdata,
    input  wire [15:0] data_rdata,
    output wire [7:0]  mem_addr,
    output wire [7:0]  io_addr,
    output wire [15:0] io_wdata,
    output wire        io_re,
    output wire        io_we,
    output wire [7:0]  data_addr,
    output wire [15:0] data_wdata,
    output wire        data_re,
    output wire        data_we,
    output wire        z_flag,
    output wire        n_flag,
    output wire        c_flag,
    output wire        v_flag
);
    wire [1:0] rd_addr;
    wire [1:0] rs_addr;
    wire [7:0] imm8;
    wire [2:0] alu_op;
    wire alu_src, reg_write, flags_write, branch_z, jump;
    wire [1:0] wb_sel;
    wire control_io_re, control_io_we, control_data_re, control_data_we;

    controller u_controller (
        .instruction(instruction), .rd_addr(rd_addr), .rs_addr(rs_addr),
        .imm8(imm8), .alu_op(alu_op), .alu_src(alu_src),
        .reg_write(reg_write), .flags_write(flags_write),
        .branch_z(branch_z), .jump(jump), .wb_sel(wb_sel),
        .io_re(control_io_re), .io_we(control_io_we),
        .data_re(control_data_re), .data_we(control_data_we)
    );
    datapath u_datapath (
        .clk(clk), .rst(rst), .io_rdata(io_rdata), .data_rdata(data_rdata),
        .rd_addr(rd_addr), .rs_addr(rs_addr), .imm8(imm8),
        .alu_op(alu_op), .alu_src(alu_src), .reg_write(reg_write),
        .flags_write(flags_write), .branch_z(branch_z), .jump(jump),
        .wb_sel(wb_sel), .control_io_re(control_io_re),
        .control_io_we(control_io_we), .control_data_re(control_data_re),
        .control_data_we(control_data_we), .mem_addr(mem_addr),
        .io_addr(io_addr), .io_wdata(io_wdata), .io_re(io_re), .io_we(io_we),
        .data_addr(data_addr), .data_wdata(data_wdata),
        .data_re(data_re), .data_we(data_we),
        .z_flag(z_flag), .n_flag(n_flag), .c_flag(c_flag), .v_flag(v_flag)
    );
endmodule
