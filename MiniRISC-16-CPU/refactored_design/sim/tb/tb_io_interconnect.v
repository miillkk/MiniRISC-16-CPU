`timescale 1ns/1ps

module tb_io_interconnect;
    reg [7:0] io_addr;
    reg io_re;
    reg io_we;
    reg [15:0] display_low_rdata;
    reg [15:0] display_high_rdata;
    reg [15:0] display_control_rdata;
    reg [15:0] led_rdata;
    reg [15:0] switch_rdata;
    wire [15:0] io_rdata;
    wire display_low_write;
    wire display_high_write;
    wire display_control_write;
    wire led_write;

    io_interconnect dut (
        .io_addr(io_addr), .io_re(io_re), .io_we(io_we),
        .display_low_rdata(display_low_rdata), .display_high_rdata(display_high_rdata),
        .display_control_rdata(display_control_rdata), .led_rdata(led_rdata),
        .switch_rdata(switch_rdata), .io_rdata(io_rdata),
        .display_low_write(display_low_write), .display_high_write(display_high_write),
        .display_control_write(display_control_write), .led_write(led_write)
    );

    task check_write;
        input [7:0] address;
        input [3:0] expected;
        begin
            io_addr = address;
            io_we = 1'b1;
            #1;
            if ({led_write, display_control_write, display_high_write, display_low_write} !== expected) begin
                $display("tb_io_interconnect: TEST FAIL write addr=%h", address);
                $finish;
            end
            io_we = 1'b0;
        end
    endtask

    task check_read;
        input [7:0] address;
        input [15:0] expected;
        begin
            io_addr = address;
            io_re = 1'b1;
            #1;
            if (io_rdata !== expected) begin
                $display("tb_io_interconnect: TEST FAIL read addr=%h got=%h", address, io_rdata);
                $finish;
            end
            io_re = 1'b0;
        end
    endtask

    initial begin
        io_addr = 0; io_re = 0; io_we = 0;
        display_low_rdata = 16'h1111;
        display_high_rdata = 16'h2222;
        display_control_rdata = 16'h3333;
        led_rdata = 16'h0044;
        switch_rdata = 16'h0055;

        check_write(8'h20, 4'b0001);
        check_write(8'h21, 4'b0010);
        check_write(8'h22, 4'b0100);
        check_write(8'h30, 4'b1000);
        check_write(8'h31, 4'b0000);
        check_write(8'hFF, 4'b0000);

        check_read(8'h20, 16'h1111);
        check_read(8'h21, 16'h2222);
        check_read(8'h22, 16'h3333);
        check_read(8'h30, 16'h0044);
        check_read(8'h31, 16'h0055);
        check_read(8'hFF, 16'h0000);

        $display("tb_io_interconnect: TEST PASS");
        $finish;
    end
endmodule
