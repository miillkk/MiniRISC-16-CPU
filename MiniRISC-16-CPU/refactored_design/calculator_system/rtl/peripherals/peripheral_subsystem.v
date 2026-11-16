`timescale 1ns/1ps

module peripheral_subsystem (
    input  wire        clk,
    input  wire        rst,
    input  wire [7:0]  switches,
    input  wire        confirm_toggle,
    input  wire        button_valid,
    input  wire [7:0]  io_addr,
    input  wire [15:0] io_wdata,
    input  wire        io_re,
    input  wire        io_we,
    input  wire        z_flag,
    input  wire        n_flag,
    input  wire        c_flag,
    input  wire        v_flag,
    output wire [15:0] io_rdata,
    output wire [7:0]  led,
    output wire [15:0] display_low,
    output wire [15:0] display_high,
    output wire [15:0] display_control,
    output wire        input_valid
);
    wire [15:0] led_rdata;
    wire [15:0] switch_rdata;
    wire [15:0] input_control_rdata;
    wire [15:0] status_rdata;
    wire [15:0] scratchpad_rdata;
    wire display_low_write;
    wire display_high_write;
    wire display_control_write;
    wire led_write;
    wire scratchpad_write;
    wire switch_valid;

    display_registers u_display_registers (
        .clk(clk), .rst(rst), .write_low(display_low_write),
        .write_high(display_high_write), .write_control(display_control_write),
        .write_data(io_wdata), .low_value(display_low),
        .high_value(display_high), .control_value(display_control)
    );

    led8 u_led8 (
        .clk(clk), .rst(rst), .write_enable(led_write),
        .write_data(io_wdata[7:0]), .led(led), .read_data(led_rdata)
    );

    assign input_valid = switch_valid & button_valid;
    assign input_control_rdata = {14'h0000, input_valid, confirm_toggle};

    switch8_input u_switch8_input (
        .clk(clk), .rst(rst), .switches(switches),
        .read_data(switch_rdata), .input_valid(switch_valid)
    );

    cpu_status_port u_cpu_status_port (
        .z_flag(z_flag), .n_flag(n_flag), .c_flag(c_flag), .v_flag(v_flag),
        .read_data(status_rdata)
    );

    scratchpad_ram u_scratchpad_ram (
        .clk(clk), .rst(rst), .write_enable(scratchpad_write),
        .address(io_addr[3:0]), .write_data(io_wdata),
        .read_data(scratchpad_rdata)
    );

    io_decoder u_io_decoder (
        .io_addr(io_addr), .io_re(io_re), .io_we(io_we),
        .display_low_rdata(display_low), .display_high_rdata(display_high),
        .display_control_rdata(display_control), .led_rdata(led_rdata),
        .switch_rdata(switch_rdata), .status_rdata(status_rdata),
        .input_control_rdata(input_control_rdata),
        .scratchpad_rdata(scratchpad_rdata), .io_rdata(io_rdata),
        .display_low_write(display_low_write),
        .display_high_write(display_high_write),
        .display_control_write(display_control_write), .led_write(led_write),
        .scratchpad_write(scratchpad_write)
    );
endmodule
