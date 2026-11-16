`timescale 1ns/1ps

module tb_calculator_board_top;
    reg clk_100mhz = 1'b0;
    reg resetn = 1'b1;
    reg [7:0] switches = 8'hA5;
    wire [7:0] led;
    wire [7:0] seg_low;
    wire [7:0] seg_high;
    wire [7:0] digit_enable;

    always #5 clk_100mhz = ~clk_100mhz;

    calculator_board_top #(
        .INIT_FILE("calculator.mem"),
        .SCAN_DIVIDER(4),
        .DEBOUNCE_CYCLES(3),
        .LONG_PRESS_CYCLES(20),
        .POWER_ON_RESET_CYCLES(3)
    ) dut (
        .clk_100mhz(clk_100mhz), .resetn(resetn), .switches(switches),
        .led(led), .seg_low(seg_low), .seg_high(seg_high),
        .digit_enable(digit_enable)
    );

    task wait_display;
        input [15:0] expected_high;
        input [15:0] expected_low;
        integer count;
        begin : wait_block
            for (count = 0; count < 2000; count = count + 1) begin
                @(posedge clk_100mhz); #1;
                if (dut.display_high === expected_high && dut.display_low === expected_low)
                    disable wait_block;
            end
            $fatal(1, "timeout waiting for display %h%h, got %h%h",
                   expected_high, expected_low, dut.display_high, dut.display_low);
        end
    endtask

    task short_press;
        begin
            resetn = 1'b0;
            repeat (8) @(posedge clk_100mhz);
            resetn = 1'b1;
            repeat (8) @(posedge clk_100mhz);
        end
    endtask

    initial begin
        wait_display(16'hA000, 16'h00A5);
        short_press();
        wait_display(16'hB000, 16'h00A5);

        // Holding S1 beyond the long-press threshold must reset the whole system.
        resetn = 1'b0;
        repeat (32) @(posedge clk_100mhz);
        #1;
        if (!dut.long_reset) $fatal(1, "top-level long reset was not asserted");
        resetn = 1'b1;
        wait_display(16'hA000, 16'h00A5);
        if (led !== 8'h00) $fatal(1, "LED did not clear after long reset");

        $display("tb_calculator_board_top: TEST PASS");
        $finish;
    end
endmodule
