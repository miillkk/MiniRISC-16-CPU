`timescale 1ns/1ps

module alu_operand_mux (
    input  wire [15:0] register_value,
    input  wire [15:0] immediate_value,
    input  wire        select_immediate,
    output wire [15:0] operand
);
    assign operand = select_immediate ? immediate_value : register_value;
endmodule
