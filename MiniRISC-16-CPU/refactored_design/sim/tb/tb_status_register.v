`timescale 1ns/1ps

module tb_status_register;
    reg clk;
    reg rst;
    reg write_enable;
    reg zero_in;
    reg negative_in;
    reg carry_in;
    reg overflow_in;
    wire z_flag;
    wire n_flag;
    wire c_flag;
    wire v_flag;
    integer errors;

    status_register dut (
        .clk(clk), .rst(rst), .write_enable(write_enable),
        .zero_in(zero_in), .negative_in(negative_in),
        .carry_in(carry_in), .overflow_in(overflow_in),
        .z_flag(z_flag), .n_flag(n_flag), .c_flag(c_flag), .v_flag(v_flag)
    );

    always #5 clk = ~clk;

    task check_flags;
        input [3:0] expected;
        begin
            #1;
            if ({z_flag, n_flag, c_flag, v_flag} !== expected) begin
                $display("ERROR tb_status_register: expected=%b actual=%b",
                         expected, {z_flag, n_flag, c_flag, v_flag});
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        write_enable = 1'b1;
        {zero_in, negative_in, carry_in, overflow_in} = 4'b1111;
        errors = 0;
        @(posedge clk); check_flags(4'b0000);

        rst = 1'b0;
        {zero_in, negative_in, carry_in, overflow_in} = 4'b1010;
        @(posedge clk); check_flags(4'b1010);

        write_enable = 1'b0;
        {zero_in, negative_in, carry_in, overflow_in} = 4'b0101;
        @(posedge clk); check_flags(4'b1010);

        write_enable = 1'b1;
        @(posedge clk); check_flags(4'b0101);

        if (errors == 0) $display("tb_status_register: TEST PASS");
        else $display("tb_status_register: TEST FAIL errors=%0d", errors);
        $finish;
    end
endmodule
