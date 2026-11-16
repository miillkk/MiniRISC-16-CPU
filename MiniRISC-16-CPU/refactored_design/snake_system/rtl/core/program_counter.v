`timescale 1ns/1ps

module program_counter (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] next_pc,
    output reg  [7:0] pc,
    output wire [7:0] pc_plus_one
);
    assign pc_plus_one = pc + 8'h01;
    always @(posedge clk) begin
        if (rst) pc <= 8'h00;
        else pc <= next_pc;
    end
endmodule
