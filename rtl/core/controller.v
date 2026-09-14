`timescale 1ns/1ps

module controller (
    input  wire [15:0] instruction,
    output wire [1:0]  rd_addr,
    output wire [1:0]  rs_addr,
    output wire [7:0]  imm8,
    output reg  [2:0]  alu_op,
    output reg          alu_src,
    output reg          reg_write,
    output reg          z_write,
    output reg          branch_z,
    output reg          jump,
    output reg          wb_sel,
    output reg          io_re,
    output reg          io_we
);
    localparam ALU_PASS_B = 3'b000;
    localparam ALU_ADD    = 3'b001;
    localparam ALU_SUB    = 3'b010;
    localparam ALU_AND    = 3'b011;
    localparam ALU_OR     = 3'b100;
    localparam ALU_XOR    = 3'b101;

    wire [3:0] opcode = instruction[15:12];

    assign rd_addr = instruction[11:10];
    assign rs_addr = instruction[9:8];
    assign imm8    = instruction[7:0];

    always @* begin
        alu_op    = ALU_PASS_B;
        alu_src   = 1'b0;
        reg_write = 1'b0;
        z_write   = 1'b0;
        branch_z  = 1'b0;
        jump      = 1'b0;
        wb_sel    = 1'b0;
        io_re     = 1'b0;
        io_we     = 1'b0;

        case (opcode)
            4'h0: begin // MOVI Rd, #imm8
                alu_op    = ALU_PASS_B;
                alu_src   = 1'b1;
                reg_write = 1'b1;
            end
            4'h1: begin // MOVR Rd, Rs
                alu_op    = ALU_PASS_B;
                reg_write = 1'b1;
            end
            4'h2: begin // ADDI Rd, #imm8
                alu_op    = ALU_ADD;
                alu_src   = 1'b1;
                reg_write = 1'b1;
            end
            4'h3: begin // ADDR Rd, Rs
                alu_op    = ALU_ADD;
                reg_write = 1'b1;
            end
            4'h4: begin // XOR Rd, Rs
                alu_op    = ALU_XOR;
                reg_write = 1'b1;
            end
            4'h5: begin // SUB Rd, Rs
                alu_op    = ALU_SUB;
                reg_write = 1'b1;
            end
            4'h6: begin // CMP Rd, Rs
                alu_op  = ALU_SUB;
                z_write = 1'b1;
            end
            4'h7: begin // AND Rd, Rs
                alu_op    = ALU_AND;
                reg_write = 1'b1;
            end
            4'h8: begin // JZ #imm8
                branch_z = 1'b1;
            end
            4'h9: begin // OR Rd, Rs
                alu_op    = ALU_OR;
                reg_write = 1'b1;
            end
            4'hA: begin // JUMP #imm8
                jump = 1'b1;
            end
            4'hB: begin // INP Rd, port
                reg_write = 1'b1;
                wb_sel    = 1'b1;
                io_re     = 1'b1;
            end
            4'hC: begin // OUP port, Rs
                io_we = 1'b1;
            end
            default: begin // 0xD..0xF: reserved safe operation
                alu_op    = ALU_PASS_B;
                alu_src   = 1'b0;
                reg_write = 1'b0;
                z_write   = 1'b0;
                branch_z  = 1'b0;
                jump      = 1'b0;
                wb_sel    = 1'b0;
                io_re     = 1'b0;
                io_we     = 1'b0;
            end
        endcase
    end
endmodule
