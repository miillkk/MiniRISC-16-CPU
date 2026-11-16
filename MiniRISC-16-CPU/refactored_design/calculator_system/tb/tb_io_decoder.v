`timescale 1ns/1ps

module tb_io_decoder;
    reg [7:0] io_addr;
    reg io_re, io_we;
    reg [15:0] display_low_rdata = 16'h1111;
    reg [15:0] display_high_rdata = 16'h2222;
    reg [15:0] display_control_rdata = 16'h3333;
    reg [15:0] led_rdata = 16'h0044;
    reg [15:0] switch_rdata = 16'h0155;
    reg [15:0] input_control_rdata = 16'h0003;
    reg [15:0] status_rdata = 16'h0068;
    reg [15:0] scratchpad_rdata = 16'hABCD;
    wire [15:0] io_rdata;
    wire display_low_write, display_high_write, display_control_write;
    wire led_write, scratchpad_write;
    integer write_count;

    io_decoder dut (
        .io_addr(io_addr), .io_re(io_re), .io_we(io_we),
        .display_low_rdata(display_low_rdata), .display_high_rdata(display_high_rdata),
        .display_control_rdata(display_control_rdata), .led_rdata(led_rdata),
        .switch_rdata(switch_rdata), .status_rdata(status_rdata),
        .input_control_rdata(input_control_rdata),
        .scratchpad_rdata(scratchpad_rdata), .io_rdata(io_rdata),
        .display_low_write(display_low_write), .display_high_write(display_high_write),
        .display_control_write(display_control_write), .led_write(led_write),
        .scratchpad_write(scratchpad_write)
    );

    task check_read;
        input [7:0] address;
        input [15:0] expected;
        begin
            io_addr = address; io_re = 1; io_we = 0; #1;
            if (io_rdata !== expected) $fatal(1, "read %h expected %h got %h", address, expected, io_rdata);
        end
    endtask

    task check_write;
        input [7:0] address;
        input [4:0] expected;
        begin
            io_addr = address; io_re = 0; io_we = 1; #1;
            if ({scratchpad_write,led_write,display_control_write,display_high_write,display_low_write} !== expected)
                $fatal(1, "write decode %h mismatch", address);
            write_count = display_low_write + display_high_write + display_control_write + led_write + scratchpad_write;
            if (write_count > 1) $fatal(1, "write enables are not one-hot");
        end
    endtask

    initial begin
        io_addr=0; io_re=0; io_we=0; #1;
        check_read(8'h20,16'h1111); check_read(8'h21,16'h2222);
        check_read(8'h22,16'h3333); check_read(8'h30,16'h0044);
        check_read(8'h31,16'h0155); check_read(8'h32,16'h0068);
        check_read(8'h33,16'h0003);
        check_read(8'h40,16'hABCD); check_read(8'h4F,16'hABCD);
        check_read(8'h7E,16'h0000);
        check_write(8'h20,5'b00001); check_write(8'h21,5'b00010);
        check_write(8'h22,5'b00100); check_write(8'h30,5'b01000);
        check_write(8'h40,5'b10000); check_write(8'h4F,5'b10000);
        check_write(8'h31,5'b00000); check_write(8'h32,5'b00000);
        check_write(8'h33,5'b00000);
        check_write(8'h7E,5'b00000);
        $display("tb_io_decoder: TEST PASS");
        $finish;
    end
endmodule
