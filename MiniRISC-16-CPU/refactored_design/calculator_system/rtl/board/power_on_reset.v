`timescale 1ns/1ps

module power_on_reset #(
    parameter integer RESET_CYCLES = 16
) (
    input  wire clk,
    output reg  rst
);
    function integer clog2;
        input integer value;
        integer work;
        begin
            work = value - 1;
            clog2 = 0;
            while (work > 0) begin
                clog2 = clog2 + 1;
                work = work >> 1;
            end
            if (clog2 < 1) clog2 = 1;
        end
    endfunction

    localparam integer COUNTER_WIDTH = clog2(RESET_CYCLES);
    reg [COUNTER_WIDTH-1:0] count;

    initial begin
        count = {COUNTER_WIDTH{1'b0}};
        rst   = 1'b1;
    end

    always @(posedge clk) begin
        if (RESET_CYCLES <= 1) begin
            rst <= 1'b0;
        end else if (rst) begin
            if (count == RESET_CYCLES - 1) begin
                rst <= 1'b0;
            end else begin
                count <= count + 1'b1;
            end
        end
    end
endmodule
