`timescale 1ns/1ps

module calculator_soc #(
    parameter INIT_FILE = ""
) (
    input  wire        clk,
    input  wire        rst,
    input  wire [7:0]  switches,
    input  wire        confirm_toggle,
    input  wire        button_valid,
    output wire [7:0]  led,
    output wire [15:0] display_low,
    output wire [15:0] display_high,
    output wire [15:0] display_control
);
    wire [7:0] mem_addr;
    wire [15:0] instruction;
    wire [7:0] io_addr;
    wire [15:0] io_wdata;
    wire [15:0] io_rdata;
    wire io_re;
    wire io_we;
    wire z_flag;
    wire n_flag;
    wire c_flag;
    wire v_flag;
    wire input_valid;
    wire cpu_rst = rst | ~input_valid;

    instruction_memory #(.INIT_FILE(INIT_FILE)) u_instruction_memory (
        .addr(mem_addr), .instruction(instruction)
    );

    cpu_core u_cpu_core (
        .clk(clk), .rst(cpu_rst), .instruction(instruction),
        .io_rdata(io_rdata), .mem_addr(mem_addr), .io_addr(io_addr),
        .io_wdata(io_wdata), .io_re(io_re), .io_we(io_we),
        .z_flag(z_flag), .n_flag(n_flag), .c_flag(c_flag), .v_flag(v_flag)
    );

    peripheral_subsystem u_peripheral_subsystem (
        .clk(clk), .rst(rst), .switches(switches),
        .confirm_toggle(confirm_toggle), .button_valid(button_valid),
        .io_addr(io_addr), .io_wdata(io_wdata), .io_re(io_re), .io_we(io_we),
        .z_flag(z_flag), .n_flag(n_flag), .c_flag(c_flag), .v_flag(v_flag),
        .io_rdata(io_rdata), .led(led), .display_low(display_low),
        .display_high(display_high), .display_control(display_control),
        .input_valid(input_valid)
    );
endmodule
