`timescale 1ns/1ps

module runtime_board_top #(
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
    reg load_meta;
    reg load_mode;
    wire [15:0] display_low, display_high, display_control;

    reset_conditioner u_reset_conditioner (
        .clk(clk_100mhz), .resetn(resetn), .rst(rst)
    );
    always @(posedge clk_100mhz) begin
        if (rst) begin
            load_meta <= switches[7];
            load_mode <= switches[7];
        end else begin
            load_meta <= switches[7];
            load_mode <= load_meta;
        end
    end
    runtime_soc #(
        .UART_CLKS_PER_BIT(UART_CLKS_PER_BIT),
        .BASE_TICK_CYCLES(BASE_TICK_CYCLES)
    ) u_runtime_soc (
        .clk(clk_100mhz), .rst(rst), .load_mode(load_mode),
        .uart_rx(uart_rx), .uart_tx(uart_tx), .switches(switches),
        .led(led), .display_low(display_low), .display_high(display_high),
        .display_control(display_control)
    );
    seven_segment8_driver #(.SCAN_DIVIDER(SCAN_DIVIDER)) u_seven_segment8_driver (
        .clk(clk_100mhz), .rst(rst), .low_value(display_low),
        .high_value(display_high), .control_value(display_control),
        .seg_low(seg_low), .seg_high(seg_high), .digit_enable(digit_enable)
    );
endmodule
