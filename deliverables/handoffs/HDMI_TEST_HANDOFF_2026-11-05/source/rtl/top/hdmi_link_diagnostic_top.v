`timescale 1ns/1ps

// Standalone link diagnostic: no CPU, instruction memory, or game state.
// All board pins retain the same names as the normal board top/XDC.
module hdmi_link_diagnostic_top (
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
    wire hdmi_ready, hdmi_fault, hdmi_hpd, hdmi_i2c_busy;
    wire [3:0] hdmi_state;
    wire [4:0] i2c_state;
    wire i2c_scl, i2c_sda, i2c_ack_error, i2c_scl_drive_low;
    reset_conditioner u_reset_conditioner(
        .clk(clk_100mhz), .resetn(resetn), .rst(rst)
    );
    hdmi_video_subsystem u_hdmi_video_subsystem(
        .clk_100mhz(clk_100mhz), .rst(rst),
        .frame_we(1'b0), .frame_addr(7'd0), .frame_wdata(8'd0),
        .load_mode(1'b0), .test_pattern(1'b1),
        .hdmi_int_n(hdmi_int_n),
        .hdmi_ready(hdmi_ready), .hdmi_fault(hdmi_fault), .hdmi_hpd(hdmi_hpd),
        .hdmi_debug_state(hdmi_state), .hdmi_debug_i2c_busy(hdmi_i2c_busy),
        .hdmi_debug_i2c_state(i2c_state),
        .hdmi_debug_i2c_scl(i2c_scl), .hdmi_debug_i2c_sda(i2c_sda),
        .hdmi_debug_i2c_ack_error(i2c_ack_error),
        .hdmi_debug_i2c_scl_drive_low(i2c_scl_drive_low),
        .hdmi_data(hdmi_data), .hdmi_hsync(hdmi_hsync),
        .hdmi_vsync(hdmi_vsync), .hdmi_de(hdmi_de), .hdmi_clk(hdmi_clk),
        .iic_scl_hdmi(iic_scl_hdmi), .iic_sda_hdmi(iic_sda_hdmi)
    );
    // SW1=1: I2C state [7:3], FPGA SCL drive-low [2], pad SCL [1], pad SDA [0].
    // Otherwise SW0=0 selects controller status; SW0=1 selects I2C bus status.
    assign led = switches[1] ?
                 {i2c_state, i2c_scl_drive_low, i2c_scl, i2c_sda} :
                 switches[0] ?
                 {i2c_state, i2c_scl, i2c_sda, i2c_ack_error} :
                 {hdmi_state, hdmi_hpd, hdmi_i2c_busy, hdmi_fault, hdmi_ready};
    assign uart_tx = 1'b1;
    assign seg_low = 8'hff;
    assign seg_high = 8'hff;
    assign digit_enable = 8'hff;
endmodule
