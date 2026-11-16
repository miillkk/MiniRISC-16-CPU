`timescale 1ns/1ps

module snake_board_top #(
    parameter INIT_FILE = "",
    parameter integer UART_CLKS_PER_BIT = 868,
    parameter integer BASE_TICK_CYCLES = 50000000,
    parameter integer SCAN_DIVIDER = 100000
) (
    input  wire       clk_100mhz,
    input  wire       resetn,
    input  wire       uart_rx,
    output wire       uart_tx,
    input  wire [7:0] switches,
    output wire [7:0] led,
    output wire [7:0] seg_low,
    output wire [7:0] seg_high,
    output wire [7:0] digit_enable
);
    wire rst;
    wire [15:0] display_low, display_high, display_control;

    reset_conditioner u_reset_conditioner (
        .clk(clk_100mhz), .resetn(resetn), .rst(rst)
    );
    snake_soc #(
        .INIT_FILE(INIT_FILE), .UART_CLKS_PER_BIT(UART_CLKS_PER_BIT),
        .BASE_TICK_CYCLES(BASE_TICK_CYCLES)
    ) u_snake_soc (
        .clk(clk_100mhz), .rst(rst), .uart_rx(uart_rx), .uart_tx(uart_tx),
        .switches(switches), .led(led), .display_low(display_low),
        .display_high(display_high), .display_control(display_control)
    );
    seven_segment8_driver #(.SCAN_DIVIDER(SCAN_DIVIDER)) u_seven_segment8_driver (
        .clk(clk_100mhz), .rst(rst), .low_value(display_low),
        .high_value(display_high), .control_value(display_control),
        .seg_low(seg_low), .seg_high(seg_high), .digit_enable(digit_enable)
    );
endmodule
