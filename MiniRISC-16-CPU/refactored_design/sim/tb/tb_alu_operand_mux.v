`timescale 1ns/1ps

module tb_alu_operand_mux;
    reg [15:0] register_value;
    reg [15:0] immediate_value;
    reg select_immediate;
    wire [15:0] operand;
    integer errors;

    alu_operand_mux dut (
        .register_value(register_value), .immediate_value(immediate_value),
        .select_immediate(select_immediate), .operand(operand)
    );

    initial begin
        errors = 0;
        register_value = 16'h1234;
        immediate_value = 16'h00A5;
        select_immediate = 1'b0;
        #1;
        if (operand !== 16'h1234) errors = errors + 1;
        select_immediate = 1'b1;
        #1;
        if (operand !== 16'h00A5) errors = errors + 1;
        if (errors == 0) $display("tb_alu_operand_mux: TEST PASS");
        else $display("tb_alu_operand_mux: TEST FAIL errors=%0d", errors);
        $finish;
    end
endmodule
