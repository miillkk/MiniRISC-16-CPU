`timescale 1ns/1ps

module switch8_sync (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] switches,
    output reg  [7:0] synchronized
);
    reg [7:0] stage1;
    always @(posedge clk) begin
        if (rst) begin stage1 <= 8'h00; synchronized <= 8'h00; end
        else begin stage1 <= switches; synchronized <= stage1; end
    end
endmodule
