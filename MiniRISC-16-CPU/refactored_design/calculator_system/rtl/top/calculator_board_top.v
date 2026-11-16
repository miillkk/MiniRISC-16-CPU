`timescale 1ns/1ps

module calculator_board_top #(
    parameter INIT_FILE = "",
    parameter integer SCAN_DIVIDER = 100000,
    parameter integer DEBOUNCE_CYCLES = 1000000,
    parameter integer LONG_PRESS_CYCLES = 100000000,
    parameter integer POWER_ON_RESET_CYCLES = 16
) (
    input  wire       clk_100mhz,
    input  wire       resetn,
    input  wire [7:0] switches,
    output wire [7:0] led,
    output wire [7:0] seg_low,
    output wire [7:0] seg_high,
    output wire [7:0] digit_enable
);
    wire por_rst;
    wire long_reset;
    wire confirm_toggle;
    wire button_valid;
    wire rst = por_rst | long_reset;
    wire [15:0] display_low;
    wire [15:0] display_high;
    wire [15:0] display_control;

    power_on_reset #(.RESET_CYCLES(POWER_ON_RESET_CYCLES)) u_power_on_reset (
        .clk(clk_100mhz), .rst(por_rst)
    );

    button_s1_controller #(
        .DEBOUNCE_CYCLES(DEBOUNCE_CYCLES),
        .LONG_PRESS_CYCLES(LONG_PRESS_CYCLES)
    ) u_button_s1_controller (
        .clk(clk_100mhz), .por_rst(por_rst), .button_n(resetn),
        .confirm_toggle(confirm_toggle), .long_reset(long_reset),
        .input_valid(button_valid)
    );

    calculator_soc #(.INIT_FILE(INIT_FILE)) u_calculator_soc (
        .clk(clk_100mhz), .rst(rst), .switches(switches),
        .confirm_toggle(confirm_toggle), .button_valid(button_valid), .led(led),
        .display_low(display_low), .display_high(display_high),
        .display_control(display_control)
    );

    seven_segment8_driver #(.SCAN_DIVIDER(SCAN_DIVIDER)) u_seven_segment8_driver (
        .clk(clk_100mhz), .rst(rst), .low_value(display_low),
        .high_value(display_high), .control_value(display_control),
        .seg_low(seg_low), .seg_high(seg_high), .digit_enable(digit_enable)
    );
endmodule
