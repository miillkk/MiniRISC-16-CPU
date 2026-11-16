`timescale 1ns/1ps

module alu (
    input  wire [15:0] operand_a,
    input  wire [15:0] operand_b,
    input  wire [2:0]  alu_op,
    output reg  [15:0] result,
    output reg         zero,
    output reg         negative,
    output reg         carry,
    output reg         overflow
);
    localparam ALU_PASS_B = 3'b000;
    localparam ALU_ADD    = 3'b001;
    localparam ALU_SUB    = 3'b010;
    localparam ALU_AND    = 3'b011;
    localparam ALU_OR     = 3'b100;
    localparam ALU_XOR    = 3'b101;

    reg [16:0] extended_result;

    always @* begin
        result          = 16'h0000;
        extended_result = 17'h00000;
        carry           = 1'b0;
        overflow        = 1'b0;
        case (alu_op)
            ALU_PASS_B: result = operand_b;
            ALU_ADD: begin
                extended_result = {1'b0, operand_a} + {1'b0, operand_b};
                result          = extended_result[15:0];
                carry           = extended_result[16];
                overflow        = ~(operand_a[15] ^ operand_b[15]) &
                                  (result[15] ^ operand_a[15]);
            end
            ALU_SUB: begin
                extended_result = {1'b0, operand_a} +
                                  {1'b0, ~operand_b} + 17'h00001;
                result          = extended_result[15:0];
                carry           = extended_result[16];
                overflow        = (operand_a[15] ^ operand_b[15]) &
                                  (result[15] ^ operand_a[15]);
            end
            ALU_AND: result = operand_a & operand_b;
            ALU_OR:  result = operand_a | operand_b;
            ALU_XOR: result = operand_a ^ operand_b;
            default: result = 16'h0000;
        endcase
        zero     = (result == 16'h0000);
        negative = result[15];
    end
endmodule
