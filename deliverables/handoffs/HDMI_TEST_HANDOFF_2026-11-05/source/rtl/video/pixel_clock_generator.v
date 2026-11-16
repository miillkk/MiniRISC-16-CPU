`timescale 1ns/1ps

module pixel_clock_generator (
    input  wire clk_100mhz,
    input  wire rst,
    output wire pixel_clk,
    output wire pixel_rst,
    output wire locked
);
    wire clk_feedback_raw;
    wire clk_feedback;
    wire pixel_clk_raw;
    reg [3:0] reset_pipe;

    MMCME2_BASE #(
        .BANDWIDTH("OPTIMIZED"),
        .CLKIN1_PERIOD(10.000),
        .DIVCLK_DIVIDE(1),
        .CLKFBOUT_MULT_F(9.000),
        .CLKOUT0_DIVIDE_F(35.750),
        .STARTUP_WAIT("FALSE")
    ) u_mmcm (
        .CLKIN1(clk_100mhz),
        .CLKFBIN(clk_feedback),
        .RST(rst),
        .PWRDWN(1'b0),
        .CLKFBOUT(clk_feedback_raw),
        .CLKOUT0(pixel_clk_raw),
        .LOCKED(locked)
    );

    BUFG u_feedback_bufg (.I(clk_feedback_raw), .O(clk_feedback));
    BUFG u_pixel_bufg (.I(pixel_clk_raw), .O(pixel_clk));

    always @(posedge pixel_clk or negedge locked) begin
        if (!locked)
            reset_pipe <= 4'b1111;
        else
            reset_pipe <= {reset_pipe[2:0], 1'b0};
    end

    assign pixel_rst = reset_pipe[3];
endmodule
