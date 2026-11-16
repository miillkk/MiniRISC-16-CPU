`timescale 1ns/1ps

module tb_switch8_debounced;
    reg clk = 1'b0;
    reg rst = 1'b1;
    reg [7:0] switches = 8'h00;
    wire [15:0] read_data;
    wire input_valid;

    always #5 clk = ~clk;

    switch8_input dut (
        .clk(clk), .rst(rst), .switches(switches),
        .read_data(read_data), .input_valid(input_valid)
    );

    task expect;
        input condition;
        input [255:0] message;
        begin
            if (!condition) begin
                $display("TEST FAIL: %0s", message);
                $finish;
            end
        end
    endtask

    initial begin
        repeat (2) @(posedge clk);
        rst = 1'b0;
        repeat (4) @(posedge clk); #1;
        expect(input_valid && read_data == 16'h0000, "initial zero did not become valid");

        switches = 8'hD5;
        repeat (3) @(posedge clk); #1;
        expect(read_data == 16'h00D5, "full eight-bit switch value was not synchronized");

        rst = 1'b1;
        switches = 8'hFF;
        repeat (2) @(posedge clk);
        rst = 1'b0;
        repeat (4) @(posedge clk); #1;
        expect(input_valid && read_data == 16'h00FF, "0xFF did not become valid");
        $display("tb_switch8_debounced: TEST PASS");
        $finish;
    end
endmodule
