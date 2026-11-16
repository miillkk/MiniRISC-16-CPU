`timescale 1ns/1ps

module tb_program_counter;
    reg clk;
    reg rst;
    reg [7:0] next_pc;
    wire [7:0] pc;
    wire [7:0] pc_plus_one;
    integer errors;

    program_counter dut (
        .clk(clk), .rst(rst), .next_pc(next_pc),
        .pc(pc), .pc_plus_one(pc_plus_one)
    );

    always #5 clk = ~clk;

    task check_state;
        input [7:0] expected_pc;
        input [7:0] expected_plus_one;
        begin
            #1;
            if (pc !== expected_pc || pc_plus_one !== expected_plus_one) begin
                $display("ERROR tb_program_counter: pc=%h/%h plus=%h/%h",
                         pc, expected_pc, pc_plus_one, expected_plus_one);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        next_pc = 8'h55;
        errors = 0;
        @(posedge clk); check_state(8'h00, 8'h01);
        rst = 1'b0;
        next_pc = 8'h42;
        @(posedge clk); check_state(8'h42, 8'h43);
        next_pc = 8'hFF;
        @(posedge clk); check_state(8'hFF, 8'h00);
        next_pc = pc_plus_one;
        @(posedge clk); check_state(8'h00, 8'h01);

        if (errors == 0) $display("tb_program_counter: TEST PASS");
        else $display("tb_program_counter: TEST FAIL errors=%0d", errors);
        $finish;
    end
endmodule
