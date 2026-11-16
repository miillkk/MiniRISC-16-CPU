`timescale 1ns/1ps

module zero_extender_8_to_16 (
    input  wire [7:0]  value_in,
    output wire [15:0] value_out
);
    assign value_out = {8'h00, value_in};
endmodule
