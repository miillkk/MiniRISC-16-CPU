`timescale 1ns/1ps

module led8 (
    input  wire        clk,
    input  wire        rst,
    input  wire        write_enable,
    input  wire [7:0]  write_data,
    output reg  [7:0]  led,
    output wire [15:0] read_data
);
    always @(posedge clk) begin
        if (rst) led <= 8'h00;
        else if (write_enable) led <= write_data;
    end
    assign read_data = {8'h00, led};
endmodule
