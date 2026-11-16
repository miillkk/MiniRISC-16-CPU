`timescale 1ns/1ps

module tb_board_led_chaser;
    reg clk_100mhz;
    reg resetn;
    reg [7:0] switches;
    wire [7:0] led;
    wire [7:0] seg_low;
    wire [7:0] seg_high;
    wire [7:0] digit_enable;
    reg [7:0] expected [0:8];
    integer index;
    integer timeout;

    board_top #(
        .INIT_FILE("board_led_chaser.mem"),
        .SCAN_DIVIDER(4)
    ) dut (
        .clk_100mhz(clk_100mhz),
        .resetn(resetn),
        .switches(switches),
        .led(led),
        .seg_low(seg_low),
        .seg_high(seg_high),
        .digit_enable(digit_enable)
    );

    always #5 clk_100mhz = ~clk_100mhz;

    initial begin
        clk_100mhz = 1'b0;
        resetn = 1'b0;
        switches = 8'h00;

        expected[0] = 8'h01;
        expected[1] = 8'h02;
        expected[2] = 8'h04;
        expected[3] = 8'h08;
        expected[4] = 8'h10;
        expected[5] = 8'h20;
        expected[6] = 8'h40;
        expected[7] = 8'h80;
        expected[8] = 8'h01;

        // Shorten only the simulated delay from FF^3 to 02^3.
        #1;
        dut.u_instruction_memory.memory[8'h03] = 16'h0402;
        dut.u_instruction_memory.memory[8'h04] = 16'h0802;
        dut.u_instruction_memory.memory[8'h05] = 16'h0002;

        repeat (4) @(negedge clk_100mhz);
        resetn = 1'b1;

        for (index = 0; index < 9; index = index + 1) begin
            timeout = 0;
            while ((led !== expected[index]) && (timeout < 200)) begin
                @(negedge clk_100mhz);
                timeout = timeout + 1;
            end
            if (led !== expected[index]) begin
                $display("tb_board_led_chaser: TEST FAIL index=%0d expected=%h actual=%h PC=%h",
                         index, expected[index], led, dut.mem_addr);
                $finish;
            end
            @(negedge clk_100mhz);
        end

        if (dut.u_seven_segment8.read_control !== 16'h0000) begin
            $display("tb_board_led_chaser: TEST FAIL display unexpectedly enabled");
            $finish;
        end

        $display("tb_board_led_chaser: TEST PASS");
        $finish;
    end
endmodule
