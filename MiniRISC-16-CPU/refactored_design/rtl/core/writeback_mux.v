`timescale 1ns/1ps

module writeback_mux (
    input  wire [15:0] alu_value,
    input  wire [15:0] io_value,
    input  wire        select_io,
    output wire [15:0] writeback_value
);
    assign writeback_value = select_io ? io_value : alu_value;
endmodule
