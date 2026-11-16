`timescale 1ns/1ps

module reset_conditioner (
    input  wire clk,
    input  wire resetn,
    output wire rst
);
    reg [1:0] release_sync;

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            release_sync <= 2'b00;
        else
            release_sync <= {release_sync[0], 1'b1};
    end

    assign rst = ~release_sync[1];
endmodule
