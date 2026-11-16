`timescale 1ns/1ps

module datapath (
    input  wire        clk,
    input  wire        rst,
    input  wire [15:0] instruction,
    input  wire [15:0] io_rdata,
    input  wire [1:0]  rd_addr,
    input  wire [1:0]  rs_addr,
    input  wire [7:0]  imm8,
    input  wire [2:0]  alu_op,
    input  wire        alu_src,
    input  wire        reg_write,
    input  wire        z_write,
    input  wire        branch_z,
    input  wire        jump,
    input  wire        wb_sel,
    input  wire        control_io_re,
    input  wire        control_io_we,
    output wire [7:0]  mem_addr,
    output wire [7:0]  io_addr,
    output wire [15:0] io_wdata,
    output wire        io_re,
    output wire        io_we
);
    reg [7:0] pc;
    reg       z_flag;

    wire [15:0] rd_data;
    wire [15:0] rs_data;
    wire [15:0] immediate = {8'h00, imm8};
    wire [15:0] alu_b = alu_src ? immediate : rs_data;
    wire [15:0] alu_result;
    wire [15:0] writeback_data = wb_sel ? io_rdata : alu_result;
    wire        rf_write_enable = reg_write & ~rst;
    wire [7:0]  pc_plus_one = pc + 8'h01;
    wire [7:0]  pc_next = jump ? imm8 :
                          ((branch_z & z_flag) ? imm8 : pc_plus_one);

    assign mem_addr = pc;
    assign io_addr  = instruction[7:0];
    assign io_wdata = rs_data;
    assign io_re    = control_io_re & ~rst;
    assign io_we    = control_io_we & ~rst;

    register_file u_register_file (
        .clk          (clk),
        .rst          (rst),
        .write_enable (rf_write_enable),
        .write_addr   (rd_addr),
        .write_data   (writeback_data),
        .read_addr_a  (rd_addr),
        .read_addr_b  (rs_addr),
        .read_data_a  (rd_data),
        .read_data_b  (rs_data)
    );

    alu u_alu (
        .operand_a (rd_data),
        .operand_b (alu_b),
        .alu_op    (alu_op),
        .result    (alu_result)
    );

    always @(posedge clk) begin
        if (rst) begin
            pc     <= 8'h00;
            z_flag <= 1'b0;
        end else begin
            pc <= pc_next;
            if (z_write)
                z_flag <= (alu_result == 16'h0000);
        end
    end
endmodule
