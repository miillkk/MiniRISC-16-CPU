`timescale 1ns/1ps

module runtime_soc #(
    parameter integer UART_CLKS_PER_BIT = 868,
    parameter integer BASE_TICK_CYCLES = 50000000
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        load_mode,
    input  wire        uart_rx,
    output wire        uart_tx,
    input  wire [7:0]  switches,
    output wire [7:0]  led,
    output wire [15:0] display_low,
    output wire [15:0] display_high,
    output wire [15:0] display_control,
    output wire        frame_we,
    output wire [6:0]  frame_addr,
    output wire [7:0]  frame_wdata
);
    wire cpu_rst = rst | load_mode;
    wire [9:0] program_addr;
    wire [15:0] instruction;
    wire [7:0] io_addr;
    wire [15:0] io_wdata, io_rdata;
    wire io_re, io_we;
    wire [7:0] data_addr;
    wire [15:0] data_wdata, data_rdata;
    wire data_re, data_we;
    wire z_flag, n_flag, c_flag, v_flag;
    wire cpu_uart_tx, loader_uart_tx;
    wire loader_we, loader_loaded, loader_error, loader_busy;
    wire [9:0] loader_addr;
    wire [15:0] loader_wdata;
    wire [7:0] game_led;
    wire [15:0] game_display_low, game_display_high, game_display_control;

    runtime_program_memory u_program_memory (
        .clk(clk), .cpu_addr(program_addr), .instruction(instruction),
        .loader_we(loader_we), .loader_addr(loader_addr),
        .loader_wdata(loader_wdata)
    );
    program_loader #(.CLKS_PER_BIT(UART_CLKS_PER_BIT)) u_program_loader (
        .clk(clk), .rst(rst), .load_mode(load_mode), .rx(uart_rx),
        .tx(loader_uart_tx), .program_we(loader_we),
        .program_addr(loader_addr), .program_wdata(loader_wdata),
        .loaded(loader_loaded), .error(loader_error), .busy(loader_busy)
    );
    data_memory u_data_memory (
        .clk(clk), .write_enable(data_we), .address(data_addr),
        .write_data(data_wdata), .read_data(data_rdata)
    );
    cpu_core u_cpu_core (
        .clk(clk), .rst(cpu_rst), .instruction(instruction),
        .io_rdata(io_rdata), .data_rdata(data_rdata),
        .mem_addr(program_addr), .io_addr(io_addr), .io_wdata(io_wdata),
        .io_re(io_re), .io_we(io_we), .data_addr(data_addr),
        .data_wdata(data_wdata), .data_re(data_re), .data_we(data_we),
        .z_flag(z_flag), .n_flag(n_flag), .c_flag(c_flag), .v_flag(v_flag)
    );
    snake_peripheral_subsystem #(
        .UART_CLKS_PER_BIT(UART_CLKS_PER_BIT),
        .BASE_TICK_CYCLES(BASE_TICK_CYCLES)
    ) u_peripheral_subsystem (
        .clk(clk), .rst(cpu_rst), .uart_rx_i(uart_rx), .uart_tx_o(cpu_uart_tx),
        .switches(switches), .io_addr(io_addr), .io_wdata(io_wdata),
        .io_re(io_re), .io_we(io_we), .z_flag(z_flag), .n_flag(n_flag),
        .c_flag(c_flag), .v_flag(v_flag), .io_rdata(io_rdata), .led(game_led),
        .display_low(game_display_low), .display_high(game_display_high),
        .display_control(game_display_control)
    );

    assign uart_tx = load_mode ? loader_uart_tx : cpu_uart_tx;
    assign led = load_mode ? {loader_error, loader_loaded, loader_busy, 5'b00000} : game_led;
    assign display_high = load_mode ? 16'h10AD : game_display_high;
    assign display_low = load_mode ? {12'h000, loader_error, loader_loaded, loader_busy, 1'b0} : game_display_low;
    // control_value[0] is the global display enable. Keep it asserted in
    // loader mode so the diagnostic "10AD" indication is actually visible.
    assign display_control = load_mode ? 16'h0001 : game_display_control;
    assign frame_we = data_we && (data_addr < 8'h48);
    assign frame_addr = data_addr[6:0];
    assign frame_wdata = data_wdata[7:0];
endmodule
