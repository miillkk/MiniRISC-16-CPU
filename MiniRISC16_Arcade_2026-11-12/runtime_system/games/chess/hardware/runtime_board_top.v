`timescale 1ns/1ps

module runtime_board_top #(
    parameter integer UART_CLKS_PER_BIT = 434,
    parameter integer BASE_TICK_CYCLES = 25000000,
    parameter integer SCAN_DIVIDER = 50000
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
    // 4K combinational instruction memory needs a longer single-cycle period.
    wire clk_50mhz, clock_locked, feedback_raw, feedback, clock_raw;
    MMCME2_BASE #(.CLKIN1_PERIOD(10.0), .DIVCLK_DIVIDE(1),
        .CLKFBOUT_MULT_F(10.0), .CLKOUT0_DIVIDE_F(20.0)) u_clock (
        .CLKIN1(clk_100mhz), .CLKFBIN(feedback), .RST(~resetn), .PWRDWN(1'b0),
        .CLKFBOUT(feedback_raw), .CLKOUT0(clock_raw), .LOCKED(clock_locked));
    BUFG u_feedback (.I(feedback_raw), .O(feedback));
    BUFG u_system_clock (.I(clock_raw), .O(clk_50mhz));
    wire rst;
    reg load_meta;
    reg load_mode;
    wire [15:0] display_low, display_high, display_control;

    reset_conditioner u_reset_conditioner (
        .clk(clk_50mhz), .resetn(resetn & clock_locked), .rst(rst)
    );
    always @(posedge clk_50mhz) begin
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
        .clk(clk_50mhz), .rst(rst), .load_mode(load_mode),
        .uart_rx(uart_rx), .uart_tx(uart_tx), .switches(switches),
        .led(led), .display_low(display_low), .display_high(display_high),
        .display_control(display_control)
    );
    seven_segment8_driver #(.SCAN_DIVIDER(SCAN_DIVIDER)) u_seven_segment8_driver (
        .clk(clk_50mhz), .rst(rst), .low_value(display_low),
        .high_value(display_high), .control_value(display_control),
        .seg_low(seg_low), .seg_high(seg_high), .digit_enable(digit_enable)
    );
endmodule

