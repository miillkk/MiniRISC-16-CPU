`timescale 1ns/1ps

module snake_soc #(
    parameter INIT_FILE = "",
    parameter integer UART_CLKS_PER_BIT = 868,
    parameter integer BASE_TICK_CYCLES = 50000000
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        uart_rx,
    output wire        uart_tx,
    input  wire [7:0]  switches,
    output wire [7:0]  led,
    output wire [15:0] display_low,
    output wire [15:0] display_high,
    output wire [15:0] display_control
);
    wire [7:0] mem_addr;
    wire [15:0] instruction;
    wire [7:0] io_addr;
    wire [15:0] io_wdata, io_rdata;
    wire io_re, io_we;
    wire [7:0] data_addr;
    wire [15:0] data_wdata, data_rdata;
    wire data_re, data_we;
    wire z_flag, n_flag, c_flag, v_flag;

    // INIT_FILE remains in the public parameter list for testbench/project
    // compatibility. The assembler-generated ROM avoids Bitgen's external
    // MEM parser while keeping program/snake.mem for the reference model.
    snake_program_rom u_instruction_memory (
        .addr(mem_addr), .instruction(instruction)
    );
    data_memory u_data_memory (
        .clk(clk), .write_enable(data_we), .address(data_addr),
        .write_data(data_wdata), .read_data(data_rdata)
    );
    cpu_core u_cpu_core (
        .clk(clk), .rst(rst), .instruction(instruction),
        .io_rdata(io_rdata), .data_rdata(data_rdata),
        .mem_addr(mem_addr), .io_addr(io_addr), .io_wdata(io_wdata),
        .io_re(io_re), .io_we(io_we), .data_addr(data_addr),
        .data_wdata(data_wdata), .data_re(data_re), .data_we(data_we),
        .z_flag(z_flag), .n_flag(n_flag), .c_flag(c_flag), .v_flag(v_flag)
    );
    snake_peripheral_subsystem #(
        .UART_CLKS_PER_BIT(UART_CLKS_PER_BIT),
        .BASE_TICK_CYCLES(BASE_TICK_CYCLES)
    ) u_snake_peripheral_subsystem (
        .clk(clk), .rst(rst), .uart_rx_i(uart_rx), .uart_tx_o(uart_tx),
        .switches(switches), .io_addr(io_addr), .io_wdata(io_wdata),
        .io_re(io_re), .io_we(io_we), .z_flag(z_flag), .n_flag(n_flag),
        .c_flag(c_flag), .v_flag(v_flag), .io_rdata(io_rdata), .led(led),
        .display_low(display_low), .display_high(display_high),
        .display_control(display_control)
    );
endmodule
