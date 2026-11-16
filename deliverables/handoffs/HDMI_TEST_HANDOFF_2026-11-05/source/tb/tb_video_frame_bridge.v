`timescale 1ns/1ps
module tb_video_frame_bridge;
    reg sys_clk=0,pixel_clk=0,sys_rst=1,pixel_rst=1,frame_we=0;
    reg [6:0] frame_addr=0; reg [7:0] frame_wdata=0;
    wire [575:0] pixel_frame; wire [5:0] pixel_head; wire valid;
    integer i;
    always #5 sys_clk=~sys_clk;
    always #20 pixel_clk=~pixel_clk;
    video_frame_bridge dut(.sys_clk(sys_clk),.sys_rst(sys_rst),.frame_we(frame_we),.frame_addr(frame_addr),.frame_wdata(frame_wdata),.pixel_clk(pixel_clk),.pixel_rst(pixel_rst),.pixel_frame(pixel_frame),.pixel_head(pixel_head),.pixel_frame_valid(valid));
    initial begin
        repeat(4) @(posedge sys_clk); sys_rst=0;
        repeat(2) @(posedge pixel_clk); pixel_rst=0;
        for(i=0;i<72;i=i+1) begin
            @(negedge sys_clk); frame_we=1; frame_addr=i; frame_wdata=i;
            @(negedge sys_clk); frame_we=0;
        end
        repeat(100) @(posedge sys_clk);
        repeat(8) @(posedge pixel_clk);
        if(!valid) $fatal(1,"frame never committed");
        if(pixel_frame[2*8 +: 8] != 8'd2) $fatal(1,"header mismatch");
        if(pixel_frame[71*8 +: 8] != 8'd71) $fatal(1,"last byte mismatch");
        if(pixel_head != 6'd63) $fatal(1,"head scan mismatch %0d",pixel_head);
        $display("tb_video_frame_bridge: TEST PASS"); $finish;
    end
endmodule
