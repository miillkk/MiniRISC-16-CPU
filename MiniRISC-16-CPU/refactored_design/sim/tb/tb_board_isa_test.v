`timescale 1ns/1ps

module tb_board_isa_test;
    reg clk_100mhz;
    reg resetn;
    reg [7:0] switches;
    wire [7:0] led;
    wire [7:0] seg_low;
    wire [7:0] seg_high;
    wire [7:0] digit_enable;
    integer timeout;

    board_top #(
        .INIT_FILE("board_isa_test.mem"),
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
        switches = 8'h3C;
        repeat (4) @(negedge clk_100mhz);
        resetn = 1'b1;

        timeout = 0;
        while ((led !== 8'hA5) && (led[7:4] !== 4'hE) &&
               (led[7:4] !== 4'hF) && (timeout < 400)) begin
            @(negedge clk_100mhz);
            timeout = timeout + 1;
        end

        repeat (20) @(negedge clk_100mhz);

        if (led !== 8'hA5) begin
            $display("tb_board_isa_test: TEST FAIL LED/error code=%h PC=%h",
                     led, dut.mem_addr);
            $finish;
        end

        if (dut.u_seven_segment8.read_high !== 16'h600D ||
            dut.u_seven_segment8.read_low !== 16'h0000 ||
            dut.u_seven_segment8.read_control[0] !== 1'b1 ||
            dut.mem_addr !== 8'hD2) begin
            $display("tb_board_isa_test: TEST FAIL high=%h low=%h control=%h PC=%h",
                     dut.u_seven_segment8.read_high,
                     dut.u_seven_segment8.read_low,
                     dut.u_seven_segment8.read_control,
                     dut.mem_addr);
            $finish;
        end

        resetn = 1'b0;
        switches = 8'h00;
        repeat (4) @(negedge clk_100mhz);
        resetn = 1'b1;

        timeout = 0;
        while ((led !== 8'hEB) && (timeout < 250)) begin
            @(negedge clk_100mhz);
            timeout = timeout + 1;
        end

        repeat (20) @(negedge clk_100mhz);
        if (led !== 8'hEB ||
            dut.u_seven_segment8.read_high !== 16'hE000 ||
            dut.u_seven_segment8.read_low !== 16'h00EB ||
            dut.mem_addr !== 8'hE1) begin
            $display("tb_board_isa_test: TEST FAIL negative path LED=%h high=%h low=%h PC=%h",
                     led,
                     dut.u_seven_segment8.read_high,
                     dut.u_seven_segment8.read_low,
                     dut.mem_addr);
            $finish;
        end

        $display("tb_board_isa_test: TEST PASS");
        $finish;
    end
endmodule
