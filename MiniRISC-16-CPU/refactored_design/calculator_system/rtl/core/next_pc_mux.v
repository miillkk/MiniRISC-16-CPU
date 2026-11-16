`timescale 1ns/1ps

module next_pc_mux (
    input  wire [7:0] pc_plus_one,
    input  wire [7:0] target_addr,
    input  wire       branch_taken,
    input  wire       jump,
    output wire [7:0] next_pc
);
    assign next_pc = jump ? target_addr :
                     (branch_taken ? target_addr : pc_plus_one);
endmodule
