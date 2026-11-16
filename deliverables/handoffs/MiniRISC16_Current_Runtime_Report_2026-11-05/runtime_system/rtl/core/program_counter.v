`timescale 1ns/1ps

module program_counter (
    input  wire       clk,
    input  wire       rst,
    input  wire [9:0] next_pc,
    output reg  [9:0] pc,
    output wire [9:0] pc_plus_one
);
    assign pc_plus_one = pc + 10'h001;
    always @(posedge clk) begin
        if (rst) pc <= 10'h000;
        else pc <= next_pc;
    end
endmodule
