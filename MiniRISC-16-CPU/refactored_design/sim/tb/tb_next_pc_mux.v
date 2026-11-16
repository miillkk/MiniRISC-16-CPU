`timescale 1ns/1ps

module tb_next_pc_mux;
    reg [7:0] pc_plus_one;
    reg [7:0] target_addr;
    reg branch_taken;
    reg jump;
    wire [7:0] next_pc;
    integer errors;

    next_pc_mux dut (
        .pc_plus_one(pc_plus_one), .target_addr(target_addr),
        .branch_taken(branch_taken), .jump(jump), .next_pc(next_pc)
    );

    task check_mux;
        input test_branch;
        input test_jump;
        input [7:0] expected;
        begin
            branch_taken = test_branch;
            jump = test_jump;
            #1;
            if (next_pc !== expected) begin
                $display("ERROR tb_next_pc_mux: branch=%b jump=%b expected=%h actual=%h",
                         test_branch, test_jump, expected, next_pc);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        pc_plus_one = 8'h11;
        target_addr = 8'hA5;
        check_mux(1'b0, 1'b0, 8'h11);
        check_mux(1'b1, 1'b0, 8'hA5);
        check_mux(1'b0, 1'b1, 8'hA5);
        check_mux(1'b1, 1'b1, 8'hA5);
        if (errors == 0) $display("tb_next_pc_mux: TEST PASS");
        else $display("tb_next_pc_mux: TEST FAIL errors=%0d", errors);
        $finish;
    end
endmodule
