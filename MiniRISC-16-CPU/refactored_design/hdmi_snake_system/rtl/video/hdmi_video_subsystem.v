`timescale 1ns/1ps

module hdmi_video_subsystem #(
    parameter integer HDMI_STARTUP_DELAY_CYCLES = 1000000,
    parameter integer HDMI_POLL_DELAY_CYCLES = 1000000,
    parameter integer I2C_CLOCK_DIVIDER = 250
) (
    input  wire        clk_100mhz,
    input  wire        rst,
    input  wire        frame_we,
    input  wire [6:0]  frame_addr,
    input  wire [7:0]  frame_wdata,
    input  wire        load_mode,
    input  wire        test_pattern,
    input  wire        hdmi_int_n,
    output wire        hdmi_ready,
    output wire        hdmi_fault,
    output wire        hdmi_hpd,
    output wire [3:0]  hdmi_debug_state,
    output wire        hdmi_debug_i2c_busy,
    output wire [4:0]  hdmi_debug_i2c_state,
    output wire        hdmi_debug_i2c_scl,
    output wire        hdmi_debug_i2c_sda,
    output wire        hdmi_debug_i2c_ack_error,
    output wire        hdmi_debug_i2c_scl_drive_low,
    output wire [15:0] hdmi_data,
    output wire        hdmi_hsync,
    output wire        hdmi_vsync,
    output wire        hdmi_de,
    output wire        hdmi_clk,
    inout  wire        iic_scl_hdmi,
    inout  wire        iic_sda_hdmi
);
    wire pixel_clk, pixel_rst, pixel_locked;
    wire [9:0] pixel_x, pixel_y;
    wire active_video, timing_hsync, timing_vsync, frame_start;
    wire [575:0] pixel_frame;
    wire [5:0] pixel_head;
    wire pixel_frame_valid;
    wire [7:0] y_value, cb_value, cr_value;
    reg load_meta, load_sync, test_meta, test_sync;
    reg [7:0] y_pipe, cb_pipe, cr_pipe;
    reg hsync_pipe, vsync_pipe, de_pipe, pixel_odd_pipe;

    pixel_clock_generator u_pixel_clock_generator(
        .clk_100mhz(clk_100mhz),.rst(rst),.pixel_clk(pixel_clk),
        .pixel_rst(pixel_rst),.locked(pixel_locked)
    );
    video_timing_640x480 u_video_timing(
        .pixel_clk(pixel_clk),.rst(pixel_rst),.pixel_x(pixel_x),.pixel_y(pixel_y),
        .active_video(active_video),.hsync(timing_hsync),.vsync(timing_vsync),.frame_start(frame_start)
    );
    video_frame_bridge u_video_frame_bridge(
        .sys_clk(clk_100mhz),.sys_rst(rst),.frame_we(frame_we),.frame_addr(frame_addr),
        .frame_wdata(frame_wdata),.pixel_clk(pixel_clk),.pixel_rst(pixel_rst),
        .pixel_frame(pixel_frame),.pixel_head(pixel_head),.pixel_frame_valid(pixel_frame_valid)
    );
    always @(posedge pixel_clk) begin
        if(pixel_rst) begin load_meta<=0;load_sync<=0;test_meta<=0;test_sync<=0;end
        else begin load_meta<=load_mode;load_sync<=load_meta;test_meta<=test_pattern;test_sync<=test_meta;end
    end
    snake_renderer u_snake_renderer(
        .pixel_x(pixel_x),.pixel_y(pixel_y),.active_video(active_video),
        .frame_data(pixel_frame),.head_position(pixel_head),.frame_valid(pixel_frame_valid),
        .load_mode(load_sync),.test_pattern(test_sync),.y_value(y_value),.cb_value(cb_value),.cr_value(cr_value)
    );
    // Capture one complete pixel at the rising edge. The output registers use
    // the falling edge, leaving a full pixel period for renderer logic.
    always @(posedge pixel_clk) begin
        if (pixel_rst) begin
            y_pipe <= 8'd16;
            cb_pipe <= 8'd128;
            cr_pipe <= 8'd128;
            hsync_pipe <= 1'b1;
            vsync_pipe <= 1'b1;
            de_pipe <= 1'b0;
            pixel_odd_pipe <= 1'b0;
        end else begin
            y_pipe <= y_value;
            cb_pipe <= cb_value;
            cr_pipe <= cr_value;
            hsync_pipe <= timing_hsync;
            vsync_pipe <= timing_vsync;
            de_pipe <= active_video;
            pixel_odd_pipe <= pixel_x[0];
        end
    end
    hdmi_output_registers u_output_registers(
        .pixel_clk(pixel_clk),.rst(pixel_rst),.pixel_x({9'd0,pixel_odd_pipe}),
        .y_value(y_pipe),.cb_value(cb_pipe),.cr_value(cr_pipe),
        .hsync_i(hsync_pipe),.vsync_i(vsync_pipe),.de_i(de_pipe),
        .hdmi_data(hdmi_data),.hdmi_hsync(hdmi_hsync),.hdmi_vsync(hdmi_vsync),
        .hdmi_de(hdmi_de),.hdmi_clk(hdmi_clk)
    );
    adv7511_controller #(
        .STARTUP_DELAY_CYCLES(HDMI_STARTUP_DELAY_CYCLES),
        .POLL_DELAY_CYCLES(HDMI_POLL_DELAY_CYCLES),
        .I2C_CLOCK_DIVIDER(I2C_CLOCK_DIVIDER)
    ) u_adv7511_controller(
        .clk(clk_100mhz),.rst(rst),.hdmi_int_n(hdmi_int_n),
        .ready(hdmi_ready),.fault(hdmi_fault),.hpd_present(hdmi_hpd),
        .debug_state(hdmi_debug_state),.debug_i2c_busy(hdmi_debug_i2c_busy),
        .debug_i2c_state(hdmi_debug_i2c_state),
        .debug_i2c_scl(hdmi_debug_i2c_scl),.debug_i2c_sda(hdmi_debug_i2c_sda),
        .debug_i2c_ack_error(hdmi_debug_i2c_ack_error),
        .debug_i2c_scl_drive_low(hdmi_debug_i2c_scl_drive_low),
        .iic_scl_hdmi(iic_scl_hdmi),.iic_sda_hdmi(iic_sda_hdmi)
    );
endmodule
