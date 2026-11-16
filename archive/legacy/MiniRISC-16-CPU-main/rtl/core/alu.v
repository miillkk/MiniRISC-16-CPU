`timescale 1ns/1ps

module alu (
    input  wire [15:0] operand_a,
    input  wire [15:0] operand_b,
    input  wire [2:0]  alu_op,
    output reg  [15:0] result
);
    localparam ALU_PASS_B = 3'b000;
    localparam ALU_ADD    = 3'b001;
    localparam ALU_SUB    = 3'b010;
    localparam ALU_AND    = 3'b011;
    localparam ALU_OR     = 3'b100;
    localparam ALU_XOR    = 3'b101;

    always @* begin
        case (alu_op)
            ALU_PASS_B: result = operand_b;
            ALU_ADD:    result = operand_a + operand_b;
            ALU_SUB:    result = operand_a - operand_b;
            ALU_AND:    result = operand_a & operand_b;
            ALU_OR:     result = operand_a | operand_b;
            ALU_XOR:    result = operand_a ^ operand_b;
            default:    result = 16'h0000;
        endcase
    end
endmodule
