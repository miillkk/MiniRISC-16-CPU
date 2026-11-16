`timescale 1ns/1ps
module tb_snake_renderer;
    reg [9:0] x=0,y=0; reg active=1,valid=1,load=0,test_pattern=0;
    reg [575:0] frame=0; reg [5:0] head=1;
    wire [7:0] yy,cb,cr;
    snake_renderer dut(.pixel_x(x),.pixel_y(y),.active_video(active),.frame_data(frame),.head_position(head),.frame_valid(valid),.load_mode(load),.test_pattern(test_pattern),.y_value(yy),.cb_value(cb),.cr_value(cr));
    initial begin
        frame[3*8 +: 8]=8'd2;
        frame[5*8 +: 8]=8'd3;
        frame[7*8 +: 8]=8'hFF;
        #1;
        x=10'd190; y=10'd90; #1;
        if(yy!=8'd184) $fatal(1,"head color %0d",yy);
        x=10'd238; y=10'd90; #1;
        if(yy!=8'd82 || cr!=8'd240) $fatal(1,"food color");
        x=10'd286; y=10'd90; #1;
        if(yy!=8'd119) $fatal(1,"obstacle color");
        test_pattern=1; x=10; y=100; #1;
        if(yy!=8'd235) $fatal(1,"test pattern white");
        active=0; #1;
        if(yy!=8'd16 || cb!=8'd128 || cr!=8'd128) $fatal(1,"blanking color");
        $display("tb_snake_renderer: TEST PASS"); $finish;
    end
endmodule
