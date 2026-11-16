`timescale 1ns/1ps

module display_registers (
    input  wire        clk,
    input  wire        rst,
    input  wire        write_low,
    input  wire        write_high,
    input  wire        write_control,
    input  wire [15:0] write_data,
    output reg  [15:0] low_value,
    output reg  [15:0] high_value,
    output reg  [15:0] control_value
);
    always @(posedge clk) begin
        if (rst) begin
            low_value     <= 16'h0000;
            high_value    <= 16'h0000;
            control_value <= 16'h0000;
        end else begin
            if (write_low)     low_value <= write_data;
            if (write_high)    high_value <= write_data;
            if (write_control) control_value <= write_data;
        end
    end
endmodule
