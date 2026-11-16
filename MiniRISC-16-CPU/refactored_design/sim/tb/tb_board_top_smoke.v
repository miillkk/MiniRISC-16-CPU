`timescale 1ns/1ps

module tb_board_top_smoke;
    reg clk_100mhz;
    reg resetn;
    reg [7:0] switches;
    wire [7:0] led;
    wire [7:0] seg_low;
    wire [7:0] seg_high;
    wire [7:0] digit_enable;
    integer timeout;

    board_top #(
        .INIT_FILE("board_demo.mem"),
        .SCAN_DIVIDER(4)
    ) dut (
        .clk_100mhz(clk_100mhz), .resetn(resetn), .switches(switches),
        .led(led), .seg_low(seg_low), .seg_high(seg_high),
        .digit_enable(digit_enable)
    );

    always #5 clk_100mhz = ~clk_100mhz;

    initial begin
        clk_100mhz = 0;
        resetn = 0;
        switches = 8'h0F;
        repeat (4) @(negedge clk_100mhz);
        resetn = 1;

        timeout = 0;
        while ((led !== 8'hA5) && (timeout < 100)) begin
            @(negedge clk_100mhz);
            timeout = timeout + 1;
        end

        if (led !== 8'hA5) begin
            $display("tb_board_top_smoke: TEST FAIL self-test LED=%h", led);
            $finish;
        end

        repeat (10) @(negedge clk_100mhz);
        if (dut.u_seven_segment8.read_high !== 16'hC0DE ||
            dut.u_seven_segment8.read_low !== 16'h0010 ||
            dut.u_seven_segment8.read_control[0] !== 1'b1) begin
            $display("tb_board_top_smoke: TEST FAIL display high=%h low=%h control=%h",
                     dut.u_seven_segment8.read_high,
                     dut.u_seven_segment8.read_low,
                     dut.u_seven_segment8.read_control);
            $finish;
        end

        switches = 8'hFF;
        repeat (12) @(negedge clk_100mhz);
        if (dut.u_seven_segment8.read_low !== 16'h0100) begin
            $display("tb_board_top_smoke: TEST FAIL switch update low=%h",
                     dut.u_seven_segment8.read_low);
            $finish;
        end

        $display("tb_board_top_smoke: TEST PASS");
        $finish;
    end
endmodule
