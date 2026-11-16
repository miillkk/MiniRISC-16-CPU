`timescale 1ns/1ps

module tb_zero_extender_8_to_16;
    reg [7:0] value_in;
    wire [15:0] value_out;
    integer errors;

    zero_extender_8_to_16 dut (.value_in(value_in), .value_out(value_out));

    task check_value;
        input [7:0] test_value;
        begin
            value_in = test_value;
            #1;
            if (value_out !== {8'h00, test_value}) begin
                $display("ERROR tb_zero_extender_8_to_16: input=%h output=%h", test_value, value_out);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        check_value(8'h00);
        check_value(8'h7F);
        check_value(8'h80);
        check_value(8'hFF);
        if (errors == 0) $display("tb_zero_extender_8_to_16: TEST PASS");
        else $display("tb_zero_extender_8_to_16: TEST FAIL errors=%0d", errors);
        $finish;
    end
endmodule
