`timescale 1ns/1ps

module uart_tx #(
    parameter integer CLKS_PER_BIT = 868
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       write_enable,
    input  wire [7:0] write_data,
    output reg        tx,
    output wire       ready
);
    reg [9:0] shift;
    reg [3:0] bit_count;
    reg [15:0] counter;
    reg busy;
    assign ready = ~busy;

    always @(posedge clk) begin
        if (rst) begin
            tx <= 1'b1;
            shift <= 10'h3FF;
            bit_count <= 4'd0;
            counter <= 16'd0;
            busy <= 1'b0;
        end else if (!busy) begin
            tx <= 1'b1;
            if (write_enable) begin
                shift <= {1'b1, write_data, 1'b0};
                tx <= 1'b0;
                bit_count <= 4'd0;
                counter <= CLKS_PER_BIT - 1;
                busy <= 1'b1;
            end
        end else if (counter != 0) begin
            counter <= counter - 1'b1;
        end else if (bit_count == 4'd9) begin
            tx <= 1'b1;
            busy <= 1'b0;
        end else begin
            shift <= {1'b1, shift[9:1]};
            tx <= shift[1];
            bit_count <= bit_count + 1'b1;
            counter <= CLKS_PER_BIT - 1;
        end
    end
endmodule
