`timescale 1ns/1ps

module tb_reset_conditioner;
    reg clk;
    reg resetn;
    wire rst;
    integer errors;

    reset_conditioner dut (
        .clk    (clk),
        .resetn (resetn),
        .rst    (rst)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        resetn = 1'b0;
        errors = 0;
        #1;
        if (rst !== 1'b1) begin
            $display("ERROR tb_reset_conditioner: reset did not assert asynchronously");
            errors = errors + 1;
        end

        @(negedge clk);
        resetn = 1'b1;
        @(posedge clk); #1;
        if (rst !== 1'b1) begin
            $display("ERROR tb_reset_conditioner: reset released after only one stage");
            errors = errors + 1;
        end
        @(posedge clk); #1;
        if (rst !== 1'b0) begin
            $display("ERROR tb_reset_conditioner: reset did not release after two stages");
            errors = errors + 1;
        end

        #2 resetn = 1'b0;
        #1;
        if (rst !== 1'b1) begin
            $display("ERROR tb_reset_conditioner: asynchronous reassertion failed");
            errors = errors + 1;
        end

        if (errors == 0)
            $display("tb_reset_conditioner: TEST PASS");
        else
            $display("tb_reset_conditioner: TEST FAIL errors=%0d", errors);
        $finish;
    end
endmodule
