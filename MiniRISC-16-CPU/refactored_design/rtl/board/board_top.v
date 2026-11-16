`timescale 1ns/1ps

module board_top #(
    parameter INIT_FILE = "",
    parameter integer SCAN_DIVIDER = 100000
) (
    input  wire       clk_100mhz,
    input  wire       resetn,
    input  wire [7:0] switches,
    output wire [7:0] led,
    output wire [7:0] seg_low,
    output wire [7:0] seg_high,
    output wire [7:0] digit_enable
);
    wire rst;
    wire [7:0] mem_addr;
    wire [15:0] instruction;
    wire [7:0] io_addr;
    wire [15:0] io_wdata;
    wire [15:0] io_rdata;
    wire io_re;
    wire io_we;

    wire [15:0] display_low_rdata;
    wire [15:0] display_high_rdata;
    wire [15:0] display_control_rdata;
    wire [15:0] led_rdata;
    wire [15:0] switch_rdata;
    wire display_low_write;
    wire display_high_write;
    wire display_control_write;
    wire led_write;

    reset_conditioner u_reset_conditioner (
        .clk    (clk_100mhz),
        .resetn (resetn),
        .rst    (rst)
    );

    instruction_memory #(
        .INIT_FILE (INIT_FILE)
    ) u_instruction_memory (
        .addr        (mem_addr),
        .instruction (instruction)
    );

    cpu_core u_cpu_core (
        .clk         (clk_100mhz),
        .rst         (rst),
        .instruction (instruction),
        .io_rdata    (io_rdata),
        .mem_addr    (mem_addr),
        .io_addr     (io_addr),
        .io_wdata    (io_wdata),
        .io_re       (io_re),
        .io_we       (io_we)
    );

    io_interconnect u_io_interconnect (
        .io_addr               (io_addr),
        .io_re                 (io_re),
        .io_we                 (io_we),
        .display_low_rdata     (display_low_rdata),
        .display_high_rdata    (display_high_rdata),
        .display_control_rdata (display_control_rdata),
        .led_rdata             (led_rdata),
        .switch_rdata          (switch_rdata),
        .io_rdata              (io_rdata),
        .display_low_write     (display_low_write),
        .display_high_write    (display_high_write),
        .display_control_write (display_control_write),
        .led_write             (led_write)
    );

    seven_segment8 #(
        .SCAN_DIVIDER (SCAN_DIVIDER)
    ) u_seven_segment8 (
        .clk           (clk_100mhz),
        .rst           (rst),
        .write_low     (display_low_write),
        .write_high    (display_high_write),
        .write_control (display_control_write),
        .write_data    (io_wdata),
        .read_low      (display_low_rdata),
        .read_high     (display_high_rdata),
        .read_control  (display_control_rdata),
        .seg_low       (seg_low),
        .seg_high      (seg_high),
        .digit_enable  (digit_enable)
    );

    led8 u_led8 (
        .clk          (clk_100mhz),
        .rst          (rst),
        .write_enable (led_write),
        .write_data   (io_wdata[7:0]),
        .read_data    (led_rdata),
        .led          (led)
    );

    switch8 u_switch8 (
        .clk      (clk_100mhz),
        .rst      (rst),
        .switches (switches),
        .read_data(switch_rdata)
    );
endmodule
