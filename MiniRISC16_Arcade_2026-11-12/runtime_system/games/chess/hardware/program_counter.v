`timescale 1ns/1ps

module program_counter (
    input  wire       clk,
    input  wire       rst,
    input  wire [11:0] next_pc,
    output reg  [11:0] pc,
    output wire [11:0] pc_plus_one
);
    assign pc_plus_one = pc + 12'h001;
    always @(posedge clk) begin
        if (rst) pc <= 12'h000;
        else pc <= next_pc;
    end
endmodule

