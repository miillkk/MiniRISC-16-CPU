`timescale 1ns/1ps

module tb_cpu_status_port;
    reg z_flag, n_flag, c_flag, v_flag;
    wire [15:0] read_data;
    cpu_status_port dut (
        .z_flag(z_flag), .n_flag(n_flag), .c_flag(c_flag), .v_flag(v_flag),
        .read_data(read_data)
    );
    initial begin
        {v_flag,c_flag,n_flag,z_flag} = 4'b0000; #1;
        if (read_data !== 16'h0000) $fatal(1, "zero flags mapping failed");
        {v_flag,c_flag,n_flag,z_flag} = 4'b1011; #1;
        if (read_data !== 16'h0058) $fatal(1, "VCNZ mapping failed: %h", read_data);
        {v_flag,c_flag,n_flag,z_flag} = 4'b0100; #1;
        if (read_data !== 16'h0020) $fatal(1, "carry mapping failed");
        $display("tb_cpu_status_port: TEST PASS");
        $finish;
    end
endmodule
