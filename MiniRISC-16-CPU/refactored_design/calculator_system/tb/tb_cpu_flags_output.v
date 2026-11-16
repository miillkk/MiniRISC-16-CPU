`timescale 1ns/1ps

module tb_cpu_flags_output;
    reg clk = 0;
    reg rst = 1;
    reg [15:0] instruction = 16'hF000;
    reg [15:0] io_rdata = 0;
    wire [7:0] mem_addr, io_addr;
    wire [15:0] io_wdata;
    wire io_re, io_we, z_flag, n_flag, c_flag, v_flag;
    always #5 clk = ~clk;

    cpu_core dut (
        .clk(clk), .rst(rst), .instruction(instruction), .io_rdata(io_rdata),
        .mem_addr(mem_addr), .io_addr(io_addr), .io_wdata(io_wdata),
        .io_re(io_re), .io_we(io_we), .z_flag(z_flag), .n_flag(n_flag),
        .c_flag(c_flag), .v_flag(v_flag)
    );

    task execute;
        input [15:0] value;
        begin instruction = value; @(posedge clk); #1; end
    endtask

    initial begin
        repeat (2) @(posedge clk); rst = 0;
        execute(16'h0000); // MOVI R0,0
        execute(16'h0401); // MOVI R1,1
        execute(16'h5100); // SUB R0,R1
        if ({z_flag,n_flag,c_flag,v_flag} !== 4'b0100) $fatal(1, "SUB flags incorrect");
        execute(16'h0001); // MOVI R0,1, must preserve flags
        if ({z_flag,n_flag,c_flag,v_flag} !== 4'b0100) $fatal(1, "MOVI changed flags");
        execute(16'h6100); // CMP R0,R1
        if ({z_flag,n_flag,c_flag,v_flag} !== 4'b1010) $fatal(1, "CMP flags incorrect");
        $display("tb_cpu_flags_output: TEST PASS");
        $finish;
    end
endmodule
