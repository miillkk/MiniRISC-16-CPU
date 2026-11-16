`timescale 1ns/1ps

module switch8 (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] switches,
    output wire [15:0] read_data
);
    reg [7:0] sync_stage_1;
    reg [7:0] sync_stage_2;

    always @(posedge clk) begin
        if (rst) begin
            sync_stage_1 <= 8'h00;
            sync_stage_2 <= 8'h00;
        end else begin
            sync_stage_1 <= switches;
            sync_stage_2 <= sync_stage_1;
        end
    end

    assign read_data = {8'h00, sync_stage_2};
endmodule
