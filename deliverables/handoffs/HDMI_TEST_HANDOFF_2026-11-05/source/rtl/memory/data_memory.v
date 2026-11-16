`timescale 1ns/1ps

module data_memory (
    input  wire        clk,
    input  wire        write_enable,
    input  wire [7:0]  address,
    input  wire [15:0] write_data,
    output wire [15:0] read_data
);
    reg [15:0] memory [0:255];
    assign read_data = memory[address];
    always @(posedge clk)
        if (write_enable)
            memory[address] <= write_data;
endmodule
