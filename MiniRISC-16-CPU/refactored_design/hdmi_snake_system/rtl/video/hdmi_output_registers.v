`timescale 1ns/1ps

module hdmi_output_registers (
    input  wire        pixel_clk,
    input  wire        rst,
    input  wire [9:0]  pixel_x,
    input  wire [7:0]  y_value,
    input  wire [7:0]  cb_value,
    input  wire [7:0]  cr_value,
    input  wire        hsync_i,
    input  wire        vsync_i,
    input  wire        de_i,
    output reg  [15:0] hdmi_data,
    output reg         hdmi_hsync,
    output reg         hdmi_vsync,
    output reg         hdmi_de,
    output wire        hdmi_clk
);
    always @(negedge pixel_clk or posedge rst) begin
        if (rst) begin
            hdmi_data <= {8'd16,8'd128};
            hdmi_hsync <= 1'b1;
            hdmi_vsync <= 1'b1;
            hdmi_de <= 1'b0;
        end else begin
            hdmi_data <= {y_value, pixel_x[0] ? cr_value : cb_value};
            hdmi_hsync <= hsync_i;
            hdmi_vsync <= vsync_i;
            hdmi_de <= de_i;
        end
    end

    ODDR #(.DDR_CLK_EDGE("OPPOSITE_EDGE"), .INIT(1'b0), .SRTYPE("ASYNC"))
    u_hdmi_clock_oddr (
        .Q(hdmi_clk), .C(pixel_clk), .CE(1'b1),
        .D1(1'b1), .D2(1'b0), .R(rst), .S(1'b0)
    );
endmodule
