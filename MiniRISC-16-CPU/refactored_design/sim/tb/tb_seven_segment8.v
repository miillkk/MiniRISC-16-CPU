`timescale 1ns/1ps

module tb_seven_segment8;
    reg clk;
    reg rst;
    reg write_low;
    reg write_high;
    reg write_control;
    reg [15:0] write_data;
    wire [15:0] read_low;
    wire [15:0] read_high;
    wire [15:0] read_control;
    wire [7:0] seg_low;
    wire [7:0] seg_high;
    wire [7:0] digit_enable;
    integer cycles;
    reg [7:0] seen_digits;

    seven_segment8 #(.SCAN_DIVIDER(3)) dut (
        .clk(clk), .rst(rst), .write_low(write_low), .write_high(write_high),
        .write_control(write_control), .write_data(write_data),
        .read_low(read_low), .read_high(read_high), .read_control(read_control),
        .seg_low(seg_low), .seg_high(seg_high), .digit_enable(digit_enable)
    );

    always #5 clk = ~clk;

    task write_register;
        input [1:0] select;
        input [15:0] value;
        begin
            @(negedge clk);
            write_data = value;
            write_low = (select == 0);
            write_high = (select == 1);
            write_control = (select == 2);
            @(negedge clk);
            write_low = 0; write_high = 0; write_control = 0;
        end
    endtask

    initial begin
        clk = 0; rst = 1; write_low = 0; write_high = 0; write_control = 0;
        write_data = 0; seen_digits = 0;
        repeat (3) @(negedge clk);
        rst = 0;
        write_register(0, 16'h3210);
        write_register(1, 16'h7654);
        write_register(2, 16'h8101); // enable, decimal points on digits 0 and 7

        if (read_low !== 16'h3210 || read_high !== 16'h7654 || read_control !== 16'h8101) begin
            $display("tb_seven_segment8: TEST FAIL register readback");
            $finish;
        end

        for (cycles = 0; cycles < 80; cycles = cycles + 1) begin
            @(negedge clk);
            if ((digit_enable & (digit_enable - 1'b1)) != 0) begin
                $display("tb_seven_segment8: TEST FAIL digit enable is not one-hot");
                $finish;
            end
            if (digit_enable != 0) begin
                seen_digits = seen_digits | digit_enable;
                if ((digit_enable[3:0] != 0) && (seg_high != 0)) begin
                    $display("tb_seven_segment8: TEST FAIL high bank active during low digit");
                    $finish;
                end
                if ((digit_enable[7:4] != 0) && (seg_low != 0)) begin
                    $display("tb_seven_segment8: TEST FAIL low bank active during high digit");
                    $finish;
                end
            end
        end

        if (seen_digits !== 8'hFF) begin
            $display("tb_seven_segment8: TEST FAIL not all digits scanned: %h", seen_digits);
            $finish;
        end
        $display("tb_seven_segment8: TEST PASS");
        $finish;
    end
endmodule
