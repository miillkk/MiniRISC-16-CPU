`timescale 1ns/1ps

module tb_scratchpad_ram;
    reg clk = 0;
    reg rst = 1;
    reg write_enable = 0;
    reg [3:0] address = 0;
    reg [15:0] write_data = 0;
    wire [15:0] read_data;
    always #5 clk = ~clk;

    scratchpad_ram dut (
        .clk(clk), .rst(rst), .write_enable(write_enable), .address(address),
        .write_data(write_data), .read_data(read_data)
    );

    initial begin
        repeat (2) @(posedge clk);
        rst = 0;
        address = 4'h0; #1;
        if (read_data !== 16'h0000) $fatal(1, "reset value at 0 is not zero");
        address = 4'hF; #1;
        if (read_data !== 16'h0000) $fatal(1, "reset value at F is not zero");
        address = 4'h0; write_data = 16'h1234; write_enable = 1;
        @(posedge clk); #1; write_enable = 0;
        if (read_data !== 16'h1234) $fatal(1, "address 0 write failed");
        address = 4'hF; write_data = 16'hBEEF; write_enable = 1;
        @(posedge clk); #1; write_enable = 0;
        if (read_data !== 16'hBEEF) $fatal(1, "address F write failed");
        address = 4'h0; #1;
        if (read_data !== 16'h1234) $fatal(1, "address alias detected");
        $display("tb_scratchpad_ram: TEST PASS");
        $finish;
    end
endmodule
