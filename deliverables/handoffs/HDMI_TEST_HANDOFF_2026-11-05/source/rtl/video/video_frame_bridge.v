`timescale 1ns/1ps

module video_frame_bridge (
    input  wire         sys_clk,
    input  wire         sys_rst,
    input  wire         frame_we,
    input  wire [6:0]   frame_addr,
    input  wire [7:0]   frame_wdata,
    input  wire         pixel_clk,
    input  wire         pixel_rst,
    output reg  [575:0] pixel_frame,
    output reg  [5:0]   pixel_head,
    output reg          pixel_frame_valid
);
    reg [7:0] shadow [0:71];
    reg [575:0] held_frame;
    reg [5:0] held_head;
    reg frame_toggle;
    reg commit_pending;
    reg scan_active;
    reg [5:0] scan_index;
    reg [7:0] scan_max;
    reg [5:0] scan_head;
    reg toggle_meta, toggle_sync, toggle_seen;
    integer i;

    always @(posedge sys_clk) begin
        if (sys_rst) begin
            held_frame <= 576'b0;
            held_head <= 6'b0;
            frame_toggle <= 1'b0;
            commit_pending <= 1'b0;
            scan_active <= 1'b0;
            scan_index <= 6'b0;
            scan_max <= 8'b0;
            scan_head <= 6'b0;
            for (i=0;i<72;i=i+1)
                shadow[i] <= 8'b0;
        end else begin
            if (frame_we && frame_addr < 7'd72) begin
                shadow[frame_addr] <= frame_wdata;
                if (frame_addr == 7'd71)
                    commit_pending <= 1'b1;
            end
            if (commit_pending && !scan_active) begin
                commit_pending <= 1'b0;
                scan_active <= 1'b1;
                scan_index <= 6'd0;
                scan_max <= 8'd0;
                scan_head <= 6'd0;
            end else if (scan_active) begin
                if ((shadow[scan_index + 7'd4] != 8'hFF) &&
                    (shadow[scan_index + 7'd4] >= scan_max)) begin
                    scan_max <= shadow[scan_index + 7'd4];
                    scan_head <= scan_index;
                end
                if (scan_index == 6'd63) begin
                    for (i=0;i<72;i=i+1)
                        held_frame[i*8 +: 8] <= shadow[i];
                    if ((shadow[67] != 8'hFF) && (shadow[67] >= scan_max))
                        held_head <= 6'd63;
                    else
                        held_head <= scan_head;
                    frame_toggle <= ~frame_toggle;
                    scan_active <= 1'b0;
                end else begin
                    scan_index <= scan_index + 6'd1;
                end
            end
        end
    end

    always @(posedge pixel_clk) begin
        if (pixel_rst) begin
            toggle_meta <= 1'b0;
            toggle_sync <= 1'b0;
            toggle_seen <= 1'b0;
            pixel_frame <= 576'b0;
            pixel_head <= 6'b0;
            pixel_frame_valid <= 1'b0;
        end else begin
            toggle_meta <= frame_toggle;
            toggle_sync <= toggle_meta;
            if (toggle_sync != toggle_seen) begin
                toggle_seen <= toggle_sync;
                pixel_frame <= held_frame;
                pixel_head <= held_head;
                pixel_frame_valid <= 1'b1;
            end
        end
    end
endmodule
