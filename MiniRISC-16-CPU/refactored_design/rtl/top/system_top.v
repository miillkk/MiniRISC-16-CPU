`timescale 1ns/1ps

module system_top #(
    parameter INIT_FILE = ""
) (
    input  wire       clk,
    input  wire       resetn,
    inout  wire [7:0] gpio
);
    wire rst;
    wire [7:0] mem_addr;
    wire [15:0] instruction;
    wire [7:0] io_addr;
    wire [15:0] io_wdata;
    wire [15:0] io_rdata;
    wire io_re;
    wire io_we;

    reset_conditioner u_reset_conditioner (
        .clk    (clk),
        .resetn (resetn),
        .rst    (rst)
    );

    instruction_memory #(
        .INIT_FILE (INIT_FILE)
    ) u_instruction_memory (
        .addr        (mem_addr),
        .instruction (instruction)
    );

    cpu_core u_cpu (
        .clk         (clk),
        .rst         (rst),
        .instruction (instruction),
        .io_rdata    (io_rdata),
        .mem_addr    (mem_addr),
        .io_addr     (io_addr),
        .io_wdata    (io_wdata),
        .io_re       (io_re),
        .io_we       (io_we)
    );

    gpio8 u_gpio8 (
        .clk      (clk),
        .rst      (rst),
        .io_addr  (io_addr),
        .io_wdata (io_wdata[7:0]),
        .io_re    (io_re),
        .io_we    (io_we),
        .io_rdata (io_rdata),
        .gpio     (gpio)
    );
endmodule
