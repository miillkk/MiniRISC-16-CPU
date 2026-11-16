`timescale 1ns/1ps

module scratchpad_ram (
    input  wire        clk,
    input  wire        rst,
    input  wire        write_enable,
    input  wire [3:0]  address,
    input  wire [15:0] write_data,
    output wire [15:0] read_data
);
    reg [15:0] memory [0:15];
    integer index;

    assign read_data = memory[address];

    always @(posedge clk) begin
        if (rst) begin
            for (index = 0; index < 16; index = index + 1)
                memory[index] <= 16'h0000;
        end else if (write_enable) begin
            memory[address] <= write_data;
        end
    end
endmodule
