`timescale 1ns/1ps

module tb_alu;
    reg  [15:0] operand_a;
    reg  [15:0] operand_b;
    reg  [2:0]  alu_op;
    wire [15:0] result;
    wire zero;
    wire negative;
    wire carry;
    wire overflow;
    integer errors;

    alu dut (
        .operand_a (operand_a),
        .operand_b (operand_b),
        .alu_op    (alu_op),
        .result    (result),
        .zero      (zero),
        .negative  (negative),
        .carry     (carry),
        .overflow  (overflow)
    );

    task check_alu;
        input [15:0] test_a;
        input [15:0] test_b;
        input [2:0]  test_op;
        input [15:0] expected_result;
        input [3:0]  expected_flags;
        begin
            operand_a = test_a;
            operand_b = test_b;
            alu_op    = test_op;
            #1;
            if (result !== expected_result ||
                {zero, negative, carry, overflow} !== expected_flags) begin
                $display("ERROR tb_alu: op=%b a=%h b=%h result=%h/%h ZNCV=%b/%b",
                         test_op, test_a, test_b, result, expected_result,
                         {zero, negative, carry, overflow}, expected_flags);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        check_alu(16'h1234, 16'hABCD, 3'b000, 16'hABCD, 4'b0100);
        check_alu(16'hFFFF, 16'h0001, 3'b001, 16'h0000, 4'b1010);
        check_alu(16'h7FFF, 16'h0001, 3'b001, 16'h8000, 4'b0101);
        check_alu(16'h0000, 16'h0001, 3'b010, 16'hFFFF, 4'b0100);
        check_alu(16'h8000, 16'h0001, 3'b010, 16'h7FFF, 4'b0011);
        check_alu(16'h1234, 16'h1234, 3'b010, 16'h0000, 4'b1010);
        check_alu(16'h0001, 16'h0002, 3'b010, 16'hFFFF, 4'b0100);
        check_alu(16'hF0F0, 16'h0FF0, 3'b011, 16'h00F0, 4'b0000);
        check_alu(16'hF000, 16'h0FF0, 3'b100, 16'hFFF0, 4'b0100);
        check_alu(16'hAAAA, 16'hFFFF, 3'b101, 16'h5555, 4'b0000);
        check_alu(16'hFFFF, 16'hFFFF, 3'b110, 16'h0000, 4'b1000);

        if (errors == 0)
            $display("tb_alu: TEST PASS");
        else
            $display("tb_alu: TEST FAIL errors=%0d", errors);
        $finish;
    end
endmodule
