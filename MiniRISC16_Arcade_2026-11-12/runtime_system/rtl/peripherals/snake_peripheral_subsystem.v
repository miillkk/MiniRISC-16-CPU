`timescale 1ns/1ps

module snake_peripheral_subsystem #(
    parameter integer UART_CLKS_PER_BIT = 868,
    parameter integer BASE_TICK_CYCLES = 50000000
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        uart_rx_i,
    output wire        uart_tx_o,
    input  wire [7:0]  switches,
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
    output wire [15:0] display_control
);
    wire [7:0] switch_value;
    wire [15:0] uart_data, uart_status, timer_data, rng_data, speed_data;
    wire [15:0] led_data, switch_data, flags_data, scratch_data;
    wire uart_data_read, uart_data_write, timer_read, rng_read, speed_write;
    wire display_low_write, display_high_write, display_control_write;
    wire led_write, scratch_write;
    reg [1:0] speed_boost;
    wire [2:0] speed_sum = {1'b0, switch_value[1:0]} + {1'b0, speed_boost};
    wire [1:0] selected_speed = speed_sum[2] ? 2'b11 : speed_sum[1:0];

    always @(posedge clk) begin
        if (rst) speed_boost <= 2'b00;
        else if (speed_write) speed_boost <= io_wdata[1:0];
    end
    assign speed_data = {14'h0000, speed_boost};

    switch8_sync u_switch8_sync (
        .clk(clk), .rst(rst), .switches(switches), .synchronized(switch_value)
    );
    uart_port #(.CLKS_PER_BIT(UART_CLKS_PER_BIT)) u_uart_port (
        .clk(clk), .rst(rst), .rx(uart_rx_i), .tx(uart_tx_o),
        .read_data(uart_data_read), .write_data(uart_data_write),
        .cpu_wdata(io_wdata[7:0]), .data_rdata(uart_data), .status_rdata(uart_status)
    );
    tick_timer #(.BASE_TICK_CYCLES(BASE_TICK_CYCLES)) u_tick_timer (
        .clk(clk), .rst(rst), .speed(selected_speed),
        .pause(switch_value[2]), .acknowledge(timer_read), .read_data(timer_data)
    );
    lfsr8 u_lfsr8 (
        .clk(clk), .rst(rst), .advance(rng_read),
        .seed_mix(switches), .read_data(rng_data)
    );
    display_registers u_display_registers (
        .clk(clk), .rst(rst), .write_low(display_low_write),
        .write_high(display_high_write), .write_control(display_control_write),
        .write_data(io_wdata), .low_value(display_low),
        .high_value(display_high), .control_value(display_control)
    );
    led8 u_led8 (
        .clk(clk), .rst(rst), .write_enable(led_write),
        .write_data(io_wdata[7:0]), .led(led), .read_data(led_data)
    );
    cpu_status_port u_cpu_status_port (
        .z_flag(z_flag), .n_flag(n_flag), .c_flag(c_flag), .v_flag(v_flag),
        .read_data(flags_data)
    );
    scratchpad16 u_scratchpad16 (
        .clk(clk), .rst(rst), .write_enable(scratch_write),
        .address(io_addr[3:0]), .write_data(io_wdata), .read_data(scratch_data)
    );
    assign switch_data = {8'h00, switch_value};

    io_decoder u_io_decoder (
        .address(io_addr), .read_enable(io_re), .write_enable(io_we),
        .uart_data(uart_data), .uart_status(uart_status),
        .timer_data(timer_data), .rng_data(rng_data), .speed_data(speed_data),
        .led_data(led_data),
        .switch_data(switch_data), .flags_data(flags_data),
        .scratch_data(scratch_data), .read_data(io_rdata),
        .uart_data_read(uart_data_read), .uart_data_write(uart_data_write),
        .timer_read(timer_read), .rng_read(rng_read), .speed_write(speed_write),
        .display_low_write(display_low_write), .display_high_write(display_high_write),
        .display_control_write(display_control_write), .led_write(led_write),
        .scratch_write(scratch_write)
    );
endmodule
