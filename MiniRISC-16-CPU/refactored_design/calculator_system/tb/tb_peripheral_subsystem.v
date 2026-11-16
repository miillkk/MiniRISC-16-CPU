`timescale 1ns/1ps

module tb_peripheral_subsystem;
    reg clk = 0, rst = 1;
    reg [7:0] switches = 8'h2A;
    reg confirm_toggle = 1'b1;
    reg button_valid = 1'b1;
    reg [7:0] io_addr = 0;
    reg [15:0] io_wdata = 0;
    reg io_re = 0, io_we = 0;
    reg z_flag=1, n_flag=0, c_flag=1, v_flag=0;
    wire [15:0] io_rdata;
    wire [7:0] led;
    wire [15:0] display_low, display_high, display_control;
    wire input_valid;
    always #5 clk = ~clk;

    peripheral_subsystem dut (
        .clk(clk), .rst(rst), .switches(switches),
        .confirm_toggle(confirm_toggle), .button_valid(button_valid), .io_addr(io_addr),
        .io_wdata(io_wdata), .io_re(io_re), .io_we(io_we),
        .z_flag(z_flag), .n_flag(n_flag), .c_flag(c_flag), .v_flag(v_flag),
        .io_rdata(io_rdata), .led(led), .display_low(display_low),
        .display_high(display_high), .display_control(display_control),
        .input_valid(input_valid)
    );

    task write_io;
        input [7:0] address; input [15:0] value;
        begin
            io_addr=address; io_wdata=value; io_we=1; @(posedge clk); #1; io_we=0;
        end
    endtask

    task read_check;
        input [7:0] address; input [15:0] expected;
        begin
            io_addr=address; io_re=1; #1;
            if (io_rdata !== expected) $fatal(1, "read %h expected %h got %h",address,expected,io_rdata);
            io_re=0;
        end
    endtask

    initial begin
        repeat(2) @(posedge clk); rst=0; repeat(8) @(posedge clk);
        if (!input_valid) $fatal(1,"switch input never became valid");
        write_io(8'h20,16'h1234); write_io(8'h21,16'hABCD);
        write_io(8'h22,16'h0001); write_io(8'h30,16'h005A);
        write_io(8'h40,16'hCAFE); write_io(8'h4F,16'hBEEF);
        if (display_low!==16'h1234 || display_high!==16'hABCD || display_control!==16'h0001 || led!==8'h5A)
            $fatal(1,"peripheral register write failed");
        read_check(8'h40,16'hCAFE); read_check(8'h4F,16'hBEEF);
        read_check(8'h32,16'h0028);
        read_check(8'h31,16'h002A); read_check(8'h33,16'h0003);
        read_check(8'h7E,16'h0000);
        $display("tb_peripheral_subsystem: TEST PASS");
        $finish;
    end
endmodule
