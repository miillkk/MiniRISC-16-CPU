`timescale 1ns/1ps

module tb_tick_timer;
    reg clk=0, rst=1, pause=0, acknowledge=0;
    reg [1:0] speed=0;
    wire [15:0] read_data;
    always #5 clk=~clk;
    tick_timer #(.BASE_TICK_CYCLES(16)) dut (
        .clk(clk), .rst(rst), .speed(speed), .pause(pause),
        .acknowledge(acknowledge), .read_data(read_data)
    );
    initial begin
        repeat(2) @(posedge clk);
        @(negedge clk); rst=0;
        repeat(32) @(posedge clk); #1;
        if (!read_data[0]) $fatal(1,"base tick missing");
        acknowledge=1; @(posedge clk); #1; acknowledge=0;
        if (read_data[0]) $fatal(1,"tick acknowledge failed");
        speed=2'b11;
        repeat(4) @(posedge clk); #1;
        if (!read_data[0]) $fatal(1,"fast tick missing");
        acknowledge=1; @(posedge clk); #1; acknowledge=0; pause=1;
        repeat(8) @(posedge clk); #1;
        if (read_data[0]) $fatal(1,"pause failed");
        $display("tb_tick_timer: TEST PASS");
        $finish;
    end
endmodule
