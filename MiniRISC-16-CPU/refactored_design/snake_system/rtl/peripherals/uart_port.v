`timescale 1ns/1ps

module uart_port #(
    parameter integer CLKS_PER_BIT = 868
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        rx,
    output wire        tx,
    input  wire        read_data,
    input  wire        write_data,
    input  wire [7:0]  cpu_wdata,
    output wire [15:0] data_rdata,
    output wire [15:0] status_rdata
);
    wire [7:0] received_byte;
    wire received_pulse;
    wire tx_ready;
    reg [7:0] rx_buffer;
    reg rx_valid;
    reg overrun;

    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_uart_rx (
        .clk(clk), .rst(rst), .rx(rx), .data(received_byte), .valid(received_pulse)
    );
    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_uart_tx (
        .clk(clk), .rst(rst), .write_enable(write_data & tx_ready),
        .write_data(cpu_wdata), .tx(tx), .ready(tx_ready)
    );

    always @(posedge clk) begin
        if (rst) begin
            rx_buffer <= 8'h00;
            rx_valid <= 1'b0;
            overrun <= 1'b0;
        end else begin
            if (read_data) rx_valid <= 1'b0;
            if (received_pulse) begin
                if (rx_valid && !read_data) overrun <= 1'b1;
                rx_buffer <= received_byte;
                rx_valid <= 1'b1;
            end
        end
    end

    assign data_rdata = {8'h00, rx_buffer};
    assign status_rdata = {13'h0000, overrun, tx_ready, rx_valid};
endmodule
