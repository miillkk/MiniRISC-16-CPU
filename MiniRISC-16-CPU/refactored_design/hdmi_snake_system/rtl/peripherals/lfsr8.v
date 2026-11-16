`timescale 1ns/1ps

module lfsr8 (
    input  wire        clk,
    input  wire        rst,
    input  wire        advance,
    input  wire [7:0]  seed_mix,
    output wire [15:0] read_data
);
    reg [7:0] value;
    wire feedback = value[7] ^ value[5] ^ value[4] ^ value[3];
    always @(posedge clk) begin
        if (rst) value <= 8'hA7 ^ seed_mix;
        else if (advance) begin
            value <= {value[6:0], feedback};
            if (value == 8'h00) value <= 8'h5D;
        end
    end
    assign read_data = {8'h00, value};
endmodule
