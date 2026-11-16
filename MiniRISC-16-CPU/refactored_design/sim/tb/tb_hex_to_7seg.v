`timescale 1ns/1ps

module tb_hex_to_7seg;
    reg [3:0] hex_value;
    wire [6:0] segments;
    integer value;

    hex_to_7seg dut (
        .hex_value (hex_value),
        .segments  (segments)
    );

    function [6:0] expected_segments;
        input [3:0] nibble;
        begin
            case (nibble)
                4'h0: expected_segments = 7'b0111111;
                4'h1: expected_segments = 7'b0000110;
                4'h2: expected_segments = 7'b1011011;
                4'h3: expected_segments = 7'b1001111;
                4'h4: expected_segments = 7'b1100110;
                4'h5: expected_segments = 7'b1101101;
                4'h6: expected_segments = 7'b1111101;
                4'h7: expected_segments = 7'b0000111;
                4'h8: expected_segments = 7'b1111111;
                4'h9: expected_segments = 7'b1101111;
                4'hA: expected_segments = 7'b1110111;
                4'hB: expected_segments = 7'b1111100;
                4'hC: expected_segments = 7'b0111001;
                4'hD: expected_segments = 7'b1011110;
                4'hE: expected_segments = 7'b1111001;
                default: expected_segments = 7'b1110001;
            endcase
        end
    endfunction

    initial begin
        for (value = 0; value < 16; value = value + 1) begin
            hex_value = value[3:0];
            #1;
            if (segments !== expected_segments(value[3:0])) begin
                $display("tb_hex_to_7seg: TEST FAIL value=%h got=%b", hex_value, segments);
                $finish;
            end
        end
        $display("tb_hex_to_7seg: TEST PASS");
        $finish;
    end
endmodule
