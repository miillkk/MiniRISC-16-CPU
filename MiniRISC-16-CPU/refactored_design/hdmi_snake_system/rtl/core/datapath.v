`timescale 1ns/1ps

module datapath (
    input  wire        clk,
    input  wire        rst,
    input  wire [15:0] io_rdata,
    input  wire [15:0] data_rdata,
    input  wire [1:0]  rd_addr,
    input  wire [1:0]  rs_addr,
    input  wire [7:0]  imm8,
    input  wire [2:0]  alu_op,
    input  wire        alu_src,
    input  wire        reg_write,
    input  wire        flags_write,
    input  wire        branch_z,
    input  wire        jump,
    input  wire        long_jump,
    input  wire [1:0]  wb_sel,
    input  wire        control_io_re,
    input  wire        control_io_we,
    input  wire        control_data_re,
    input  wire        control_data_we,
    output wire [9:0]  mem_addr,
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
    wire [9:0] pc;
    wire [9:0] pc_plus_one;
    wire [9:0] pc_next;
    wire branch_taken;
    wire [15:0] rd_data;
    wire [15:0] rs_data;
    wire [15:0] immediate;
    wire [15:0] alu_b;
    wire [15:0] alu_result;
    wire alu_zero;
    wire alu_negative;
    wire alu_carry;
    wire alu_overflow;
    wire [15:0] writeback_data;

    assign branch_taken = branch_z & z_flag;
    assign mem_addr = pc;
    assign io_addr = imm8;
    assign io_wdata = rs_data;
    assign io_re = control_io_re & ~rst;
    assign io_we = control_io_we & ~rst;
    assign data_addr = control_data_we ? rd_data[7:0] : rs_data[7:0];
    assign data_wdata = rs_data;
    assign data_re = control_data_re & ~rst;
    assign data_we = control_data_we & ~rst;

    program_counter u_program_counter (
        .clk(clk), .rst(rst), .next_pc(pc_next), .pc(pc), .pc_plus_one(pc_plus_one)
    );
    next_pc_mux u_next_pc_mux (
        .pc_plus_one(pc_plus_one), .current_page(pc[9:8]),
        .target_addr(imm8), .absolute_target({rs_addr, imm8}),
        .branch_taken(branch_taken), .jump(jump), .long_jump(long_jump),
        .next_pc(pc_next)
    );
    register_file u_register_file (
        .clk(clk), .rst(rst), .write_enable(reg_write & ~rst),
        .write_addr(rd_addr), .write_data(writeback_data),
        .read_addr_a(rd_addr), .read_addr_b(rs_addr),
        .read_data_a(rd_data), .read_data_b(rs_data)
    );
    zero_extender_8_to_16 u_zero_extender (
        .value_in(imm8), .value_out(immediate)
    );
    alu_operand_mux u_alu_operand_mux (
        .register_value(rs_data), .immediate_value(immediate),
        .select_immediate(alu_src), .operand(alu_b)
    );
    alu u_alu (
        .operand_a(rd_data), .operand_b(alu_b), .alu_op(alu_op),
        .result(alu_result), .zero(alu_zero), .negative(alu_negative),
        .carry(alu_carry), .overflow(alu_overflow)
    );
    status_register u_status_register (
        .clk(clk), .rst(rst), .write_enable(flags_write),
        .zero_in(alu_zero), .negative_in(alu_negative),
        .carry_in(alu_carry), .overflow_in(alu_overflow),
        .z_flag(z_flag), .n_flag(n_flag), .c_flag(c_flag), .v_flag(v_flag)
    );
    writeback_mux u_writeback_mux (
        .alu_value(alu_result), .io_value(io_rdata), .data_value(data_rdata),
        .select_source(wb_sel), .writeback_value(writeback_data)
    );
endmodule
