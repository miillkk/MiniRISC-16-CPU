`timescale 1ns/1ps

module tb_cpu_data_instructions;
    reg clk = 0;
    reg rst = 1;
    reg [15:0] instruction = 16'hF000;
    wire [7:0] data_addr;
    wire [15:0] data_wdata, data_rdata;
    wire data_re, data_we;
    wire [9:0] mem_addr;
    wire [7:0] io_addr;
    wire [15:0] io_wdata;
    wire io_re, io_we;
    wire z,n,c,v;

    always #5 clk = ~clk;
    cpu_core dut (
        .clk(clk), .rst(rst), .instruction(instruction),
        .io_rdata(16'h0000), .data_rdata(data_rdata), .mem_addr(mem_addr),
        .io_addr(io_addr), .io_wdata(io_wdata), .io_re(io_re), .io_we(io_we),
        .data_addr(data_addr), .data_wdata(data_wdata), .data_re(data_re),
        .data_we(data_we), .z_flag(z), .n_flag(n), .c_flag(c), .v_flag(v)
    );
    data_memory ram (
        .clk(clk), .write_enable(data_we), .address(data_addr),
        .write_data(data_wdata), .read_data(data_rdata)
    );

    task execute;
        input [15:0] word;
        begin instruction = word; @(posedge clk); #1; end
    endtask

    initial begin
        repeat (2) @(posedge clk);
        rst = 0;
        execute(16'h0022); // MOVI R0,22
        execute(16'h045A); // MOVI R1,5A
        execute(16'hE100); // STR R0,R1
        if (ram.memory[8'h22] !== 16'h005A) $fatal(1,"STR failed");
        execute(16'hD800); // LDR R2,R0
        if (dut.u_datapath.u_register_file.registers[2] !== 16'h005A) $fatal(1,"LDR failed");
        if (!data_re || data_addr != 8'h22) $fatal(1,"LDR bus controls failed");
        $display("tb_cpu_data_instructions: TEST PASS");
        $finish;
    end
endmodule
