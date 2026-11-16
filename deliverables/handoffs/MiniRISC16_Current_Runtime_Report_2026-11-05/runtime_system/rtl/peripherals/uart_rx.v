`timescale 1ns/1ps

module uart_rx #(
    parameter integer CLKS_PER_BIT = 868
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,
    output reg  [7:0] data,
    output reg        valid
);
    localparam IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;
    reg [1:0] state;
    reg [15:0] counter;
    reg [2:0] bit_index;
    reg [7:0] shift;
    reg rx_meta, rx_sync;

    always @(posedge clk) begin
        rx_meta <= rx;
        rx_sync <= rx_meta;
        valid <= 1'b0;
        if (rst) begin
            state <= IDLE;
            counter <= 16'd0;
            bit_index <= 3'd0;
            shift <= 8'h00;
            data <= 8'h00;
            rx_meta <= 1'b1;
            rx_sync <= 1'b1;
        end else begin
            case (state)
                IDLE: if (!rx_sync) begin
                    counter <= (CLKS_PER_BIT / 2);
                    state <= START;
                end
                START: if (counter != 0) counter <= counter - 1'b1;
                       else if (!rx_sync) begin
                           counter <= CLKS_PER_BIT - 1;
                           bit_index <= 3'd0;
                           state <= DATA;
                       end else state <= IDLE;
                DATA: if (counter != 0) counter <= counter - 1'b1;
                      else begin
                          shift[bit_index] <= rx_sync;
                          counter <= CLKS_PER_BIT - 1;
                          if (bit_index == 3'd7) state <= STOP;
                          else bit_index <= bit_index + 1'b1;
                      end
                STOP: if (counter != 0) counter <= counter - 1'b1;
                      else begin
                          if (rx_sync) begin data <= shift; valid <= 1'b1; end
                          state <= IDLE;
                      end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
