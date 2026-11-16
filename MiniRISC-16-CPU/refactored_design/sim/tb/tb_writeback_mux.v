`timescale 1ns/1ps

module tb_writeback_mux;
    reg [15:0] alu_value;
    reg [15:0] io_value;
    reg select_io;
    wire [15:0] writeback_value;
    integer errors;

    writeback_mux dut (
        .alu_value(alu_value), .io_value(io_value),
        .select_io(select_io), .writeback_value(writeback_value)
    );

    initial begin
        errors = 0;
        alu_value = 16'h55AA;
        io_value = 16'hA55A;
        select_io = 1'b0;
        #1;
        if (writeback_value !== 16'h55AA) errors = errors + 1;
        select_io = 1'b1;
        #1;
        if (writeback_value !== 16'hA55A) errors = errors + 1;
        if (errors == 0) $display("tb_writeback_mux: TEST PASS");
        else $display("tb_writeback_mux: TEST FAIL errors=%0d", errors);
        $finish;
    end
endmodule
