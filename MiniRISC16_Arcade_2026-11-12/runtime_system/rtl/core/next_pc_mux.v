`timescale 1ns/1ps

module next_pc_mux (
    input  wire [9:0] pc_plus_one,
    input  wire [1:0] current_page,
    input  wire [7:0] target_addr,
    input  wire [9:0] absolute_target,
    input  wire       branch_taken,
    input  wire       jump,
    input  wire       long_jump,
    output wire [9:0] next_pc
);
    wire [9:0] page_target = {current_page, target_addr};
    assign next_pc = long_jump ? absolute_target :
                     (jump ? page_target :
                     (branch_taken ? page_target : pc_plus_one));
endmodule
