`timescale 1ns/1ps

module tb_register_file;
    reg clk;
    reg rst;
    reg write_enable;
    reg [1:0] write_addr;
    reg [15:0] write_data;
    reg [1:0] read_addr_a;
    reg [1:0] read_addr_b;
    wire [15:0] read_data_a;
    wire [15:0] read_data_b;
    integer errors;

    register_file dut (
        .clk(clk), .rst(rst), .write_enable(write_enable),
        .write_addr(write_addr), .write_data(write_data),
        .read_addr_a(read_addr_a), .read_addr_b(read_addr_b),
        .read_data_a(read_data_a), .read_data_b(read_data_b)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        write_enable = 1'b0;
        write_addr = 2'b00;
        write_data = 16'h0000;
        read_addr_a = 2'b00;
        read_addr_b = 2'b11;
        errors = 0;

        @(posedge clk); #1;
        if (read_data_a !== 16'h0000 || read_data_b !== 16'h0000) errors = errors + 1;

        rst = 1'b0;
        write_enable = 1'b1;
        write_addr = 2'b00;
        write_data = 16'h1234;
        @(posedge clk); #1;
        write_addr = 2'b11;
        write_data = 16'hABCD;
        @(posedge clk); #1;
        write_enable = 1'b0;
        read_addr_a = 2'b00;
        read_addr_b = 2'b11;
        #1;
        if (read_data_a !== 16'h1234 || read_data_b !== 16'hABCD) begin
            $display("ERROR tb_register_file: readback mismatch");
            errors = errors + 1;
        end

        write_addr = 2'b00;
        write_data = 16'hFFFF;
        @(posedge clk); #1;
        if (read_data_a !== 16'h1234) begin
            $display("ERROR tb_register_file: disabled write changed R0");
            errors = errors + 1;
        end

        rst = 1'b1;
        @(posedge clk); #1;
        if (dut.registers[0] !== 16'h0000 || dut.registers[1] !== 16'h0000 ||
            dut.registers[2] !== 16'h0000 || dut.registers[3] !== 16'h0000) begin
            $display("ERROR tb_register_file: reset did not clear all registers");
            errors = errors + 1;
        end

        if (errors == 0) $display("tb_register_file: TEST PASS");
        else $display("tb_register_file: TEST FAIL errors=%0d", errors);
        $finish;
    end
endmodule
