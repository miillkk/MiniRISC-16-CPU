`timescale 1ns/1ps

module status_register (
    input  wire clk,
    input  wire rst,
    input  wire write_enable,
    input  wire zero_in,
    input  wire negative_in,
    input  wire carry_in,
    input  wire overflow_in,
    output reg  z_flag,
    output reg  n_flag,
    output reg  c_flag,
    output reg  v_flag
);
    always @(posedge clk) begin
        if (rst) begin
            z_flag <= 1'b0;
            n_flag <= 1'b0;
            c_flag <= 1'b0;
            v_flag <= 1'b0;
        end else if (write_enable) begin
            z_flag <= zero_in;
            n_flag <= negative_in;
            c_flag <= carry_in;
            v_flag <= overflow_in;
        end
    end
endmodule
