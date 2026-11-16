`timescale 1ns/1ps
module tb_video_timing_640x480;
    reg clk=0, rst=1;
    wire [9:0] x,y; wire de,hs,vs,fs;
    integer cycles=0, active_count=0, hs_low_count=0, vs_low_count=0;
    always #5 clk=~clk;
    video_timing_640x480 dut(.pixel_clk(clk),.rst(rst),.pixel_x(x),.pixel_y(y),.active_video(de),.hsync(hs),.vsync(vs),.frame_start(fs));
    initial begin
        repeat(4) @(posedge clk); rst=0;
        repeat(800*525) begin
            @(negedge clk);
            cycles=cycles+1;
            if(de) active_count=active_count+1;
            if(!hs) hs_low_count=hs_low_count+1;
            if(!vs) vs_low_count=vs_low_count+1;
        end
        if(cycles!=420000) $fatal(1,"cycle count failed");
        if(active_count!=640*480) $fatal(1,"active count %0d",active_count);
        if(hs_low_count!=96*525) $fatal(1,"hsync count %0d",hs_low_count);
        if(vs_low_count!=2*800) $fatal(1,"vsync count %0d",vs_low_count);
        if(x!=0 || y!=0 || !fs) $fatal(1,"frame wrap failed x=%0d y=%0d",x,y);
        $display("tb_video_timing_640x480: TEST PASS"); $finish;
    end
endmodule
