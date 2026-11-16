`timescale 1ns/1ps

module register_file (
    input  wire        clk,
    input  wire        rst,
    input  wire        write_enable,
    input  wire [1:0]  write_addr,
    input  wire [15:0] write_data,
    input  wire [1:0]  read_addr_a,
    input  wire [1:0]  read_addr_b,
    output wire [15:0] read_data_a,
    output wire [15:0] read_data_b
);
    reg [15:0] registers [0:3];
    integer index;

    assign read_data_a = registers[read_addr_a];
    assign read_data_b = registers[read_addr_b];

    always @(posedge clk) begin
        if (rst) begin
            for (index = 0; index < 4; index = index + 1)
                registers[index] <= 16'h0000;
        end else if (write_enable) begin
            registers[write_addr] <= write_data;
        end
    end
endmodule
