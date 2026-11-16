`timescale 1ns/1ps

module tb_program_capacity;
    reg clk=0, rst=1;
    reg [15:0] rom [0:1023];
    wire [9:0] mem_addr;
    wire [15:0] instruction=rom[mem_addr];
    wire [7:0] io_addr, data_addr;
    wire [15:0] io_wdata, data_wdata;
    wire io_re, io_we, data_re, data_we;
    wire z_flag, n_flag, c_flag, v_flag;
    integer i;

    always #5 clk=~clk;
    cpu_core dut (
        .clk(clk), .rst(rst), .instruction(instruction),
        .io_rdata(16'h0000), .data_rdata(16'h0000),
        .mem_addr(mem_addr), .io_addr(io_addr), .io_wdata(io_wdata),
        .io_re(io_re), .io_we(io_we), .data_addr(data_addr),
        .data_wdata(data_wdata), .data_re(data_re), .data_we(data_we),
        .z_flag(z_flag), .n_flag(n_flag), .c_flag(c_flag), .v_flag(v_flag)
    );

    initial begin
        for(i=0;i<1024;i=i+1) rom[i]=16'hFFFF;
        rom[10'h000]=16'hF100; // JMPA 0x100
        rom[10'h100]=16'h0000; // MOVI R0,0
        rom[10'h101]=16'h2000; // ADDI R0,0 -> Z
        rom[10'h102]=16'h8006; // JZ 0x106 in the current page
        rom[10'h103]=16'h04EE;
        rom[10'h106]=16'h04AA; // MOVI R1,AA
        rom[10'h107]=16'hF200; // JMPA 0x200
        rom[10'h200]=16'h0855; // MOVI R2,55
        rom[10'h201]=16'hF201; // self loop
        repeat(3) @(posedge clk); rst=0;
        repeat(10) @(posedge clk); #1;
        if(mem_addr!=10'h201) $fatal(1,"10-bit PC/absolute jump failed: %h",mem_addr);
        if(dut.u_datapath.u_register_file.registers[1]!=16'h00AA)
            $fatal(1,"page-local JZ failed");
        if(dut.u_datapath.u_register_file.registers[2]!=16'h0055)
            $fatal(1,"page-2 execution failed");
        $display("tb_program_capacity: TEST PASS");
        $finish;
    end
endmodule
