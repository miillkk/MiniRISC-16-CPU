`timescale 1ns/1ps

module video_timing_640x480 (
    input  wire       pixel_clk,
    input  wire       rst,
    output reg [9:0]  pixel_x,
    output reg [9:0]  pixel_y,
    output wire       active_video,
    output wire       hsync,
    output wire       vsync,
    output wire       frame_start
);
    localparam H_ACTIVE = 640;
    localparam H_FRONT  = 16;
    localparam H_SYNC   = 96;
    localparam H_TOTAL  = 800;
    localparam V_ACTIVE = 480;
    localparam V_FRONT  = 10;
    localparam V_SYNC   = 2;
    localparam V_TOTAL  = 525;

    always @(posedge pixel_clk) begin
        if (rst) begin
            pixel_x <= 10'd0;
            pixel_y <= 10'd0;
        end else if (pixel_x == H_TOTAL-1) begin
            pixel_x <= 10'd0;
            if (pixel_y == V_TOTAL-1)
                pixel_y <= 10'd0;
            else
                pixel_y <= pixel_y + 10'd1;
        end else begin
            pixel_x <= pixel_x + 10'd1;
        end
    end

    assign active_video = (pixel_x < H_ACTIVE) && (pixel_y < V_ACTIVE);
    assign hsync = ~((pixel_x >= H_ACTIVE + H_FRONT) &&
                     (pixel_x <  H_ACTIVE + H_FRONT + H_SYNC));
    assign vsync = ~((pixel_y >= V_ACTIVE + V_FRONT) &&
                     (pixel_y <  V_ACTIVE + V_FRONT + V_SYNC));
    assign frame_start = (pixel_x == 0) && (pixel_y == 0);
endmodule
