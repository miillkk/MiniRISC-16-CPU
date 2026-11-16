`timescale 1ns/1ps

module writeback_mux (
    input  wire [15:0] alu_value,
    input  wire [15:0] io_value,
    input  wire [15:0] data_value,
    input  wire [1:0]  select_source,
    output reg  [15:0] writeback_value
);
    always @* begin
        case (select_source)
            2'b01: writeback_value = io_value;
            2'b10: writeback_value = data_value;
            default: writeback_value = alu_value;
        endcase
    end
endmodule
