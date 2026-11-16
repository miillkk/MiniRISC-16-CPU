`timescale 1ns/1ps

module cpu_status_port (
    input  wire z_flag,
    input  wire n_flag,
    input  wire c_flag,
    input  wire v_flag,
    output wire [15:0] read_data
);
    // The bit positions directly match LED6..LED3.
    assign read_data = {9'h000, v_flag, c_flag, n_flag, z_flag, 3'b000};
endmodule
