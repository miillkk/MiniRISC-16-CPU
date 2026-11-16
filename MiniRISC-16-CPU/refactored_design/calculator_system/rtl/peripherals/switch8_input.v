`timescale 1ns/1ps

module switch8_input (
    input  wire        clk,
    input  wire        rst,
    input  wire [7:0]  switches,
    output wire [15:0] read_data,
    output reg         input_valid
);
    reg [7:0] sync_stage_1;
    reg [7:0] sync_stage_2;

    assign read_data = {8'h00, sync_stage_2};

    always @(posedge clk) begin
        if (rst) begin
            sync_stage_1 <= 8'h00;
            sync_stage_2 <= 8'h00;
            input_valid  <= 1'b0;
        end else begin
            sync_stage_1 <= switches;
            sync_stage_2 <= sync_stage_1;
            input_valid  <= 1'b1;
        end
    end
endmodule
