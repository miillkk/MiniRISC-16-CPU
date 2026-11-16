`timescale 1ns/1ps

module hdmi_snake_board_top #(
    parameter integer UART_CLKS_PER_BIT = 868,
    parameter integer BASE_TICK_CYCLES = 50000000,
    parameter integer SCAN_DIVIDER = 100000,
    parameter integer HDMI_STARTUP_DELAY_CYCLES = 1000000,
    parameter integer HDMI_POLL_DELAY_CYCLES = 1000000,
    parameter integer I2C_CLOCK_DIVIDER = 250,
    parameter integer HDMI_DIAGNOSTIC_LEDS = 0
) (
    input  wire        clk_100mhz,
    input  wire        resetn,
    input  wire        uart_rx,
    output wire        uart_tx,
    input  wire [7:0]  switches,
    output wire [7:0]  led,
    output wire [7:0]  seg_low,
    output wire [7:0]  seg_high,
    output wire [7:0]  digit_enable,
    output wire [15:0] hdmi_data,
    output wire        hdmi_hsync,
    output wire        hdmi_vsync,
    output wire        hdmi_de,
    output wire        hdmi_clk,
    input  wire        hdmi_int_n,
    inout  wire        iic_scl_hdmi,
    inout  wire        iic_sda_hdmi
);
    wire rst;
    reg load_meta;
    reg load_mode;
    wire [15:0] display_low, display_high, display_control;
    wire [7:0] game_led;
    wire frame_we;
    wire [6:0] frame_addr;
    wire [7:0] frame_wdata;
    wire hdmi_ready, hdmi_fault, hdmi_hpd;
    wire [3:0] hdmi_debug_state;
    wire hdmi_debug_i2c_busy;

    reset_conditioner u_reset_conditioner(.clk(clk_100mhz),.resetn(resetn),.rst(rst));
    always @(posedge clk_100mhz) begin
        if (rst) begin load_meta<=switches[7]; load_mode<=switches[7]; end
        else begin load_meta<=switches[7]; load_mode<=load_meta; end
    end

    runtime_soc #(
        .UART_CLKS_PER_BIT(UART_CLKS_PER_BIT),.BASE_TICK_CYCLES(BASE_TICK_CYCLES)
    ) u_runtime_soc (
        .clk(clk_100mhz),.rst(rst),.load_mode(load_mode),.uart_rx(uart_rx),.uart_tx(uart_tx),
        .switches(switches),.led(game_led),.display_low(display_low),.display_high(display_high),
        .display_control(display_control),.frame_we(frame_we),.frame_addr(frame_addr),.frame_wdata(frame_wdata)
    );

    seven_segment8_driver #(.SCAN_DIVIDER(SCAN_DIVIDER)) u_seven_segment8_driver(
        .clk(clk_100mhz),.rst(rst),.low_value(display_low),.high_value(display_high),
        .control_value(display_control),.seg_low(seg_low),.seg_high(seg_high),.digit_enable(digit_enable)
    );

    hdmi_video_subsystem #(
        .HDMI_STARTUP_DELAY_CYCLES(HDMI_STARTUP_DELAY_CYCLES),
        .HDMI_POLL_DELAY_CYCLES(HDMI_POLL_DELAY_CYCLES),
        .I2C_CLOCK_DIVIDER(I2C_CLOCK_DIVIDER)
    ) u_hdmi_video_subsystem(
        .clk_100mhz(clk_100mhz),.rst(rst),.frame_we(frame_we),.frame_addr(frame_addr),
        .frame_wdata(frame_wdata),.load_mode(load_mode),.test_pattern(switches[6]),
        .hdmi_int_n(hdmi_int_n),.hdmi_ready(hdmi_ready),.hdmi_fault(hdmi_fault),
        .hdmi_hpd(hdmi_hpd),.hdmi_debug_state(hdmi_debug_state),
        .hdmi_debug_i2c_busy(hdmi_debug_i2c_busy),
        .hdmi_data(hdmi_data),.hdmi_hsync(hdmi_hsync),
        .hdmi_vsync(hdmi_vsync),.hdmi_de(hdmi_de),.hdmi_clk(hdmi_clk),
        .iic_scl_hdmi(iic_scl_hdmi),.iic_sda_hdmi(iic_sda_hdmi)
    );

    // The diagnostic build reuses the existing LED pins without changing the
    // normal game build. LED[7:4]=controller state, 3=HPD, 2=I2C busy,
    // 1=fault, 0=ready.
    assign led = HDMI_DIAGNOSTIC_LEDS ?
                 {hdmi_debug_state,hdmi_hpd,hdmi_debug_i2c_busy,hdmi_fault,hdmi_ready} :
                 {game_led[7],hdmi_ready,hdmi_fault,game_led[4:0]};
endmodule
