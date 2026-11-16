`timescale 1ns/1ps

module instruction_memory #(
    parameter INIT_FILE = ""
) (
    input  wire [9:0]  addr,
    output wire [15:0] instruction
);
    reg [15:0] memory [0:1023];
    integer index;
    initial begin
        for (index = 0; index < 1024; index = index + 1)
            memory[index] = 16'hFFFF;
        if (INIT_FILE != "")
            $readmemh(INIT_FILE, memory);
    end
    assign instruction = memory[addr];
endmodule
