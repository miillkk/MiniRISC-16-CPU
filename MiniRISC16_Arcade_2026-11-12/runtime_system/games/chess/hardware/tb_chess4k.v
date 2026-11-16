`timescale 1ns/1ps
module tb_chess4k;
reg clk=0,rst=1;
always #5 clk=~clk;
wire [11:0] pc;
wire [15:0] instruction,io_wdata,data_wdata,data_rdata;
wire [7:0] io_addr,data_addr;
wire io_re,io_we,data_re,data_we;
reg rx_valid=0;
reg [7:0] rx_byte=0;
wire [15:0] io_rdata=io_addr==8'h11 ? {14'b0,1'b1,rx_valid} : {8'b0,rx_byte};
integer count=0;
integer i,black_home;
reg [7:0] frame[0:69];
reg [7:0] checksum=0;
reg seen_high=0;
runtime_program_memory rom(.clk(clk),.cpu_addr(pc),.instruction(instruction),.loader_we(1'b0),.loader_addr(12'b0),.loader_wdata(16'b0));
data_memory ram(.clk(clk),.write_enable(data_we),.address(data_addr),.write_data(data_wdata),.read_data(data_rdata));
cpu_core cpu(.clk(clk),.rst(rst),.instruction(instruction),.io_rdata(io_rdata),.data_rdata(data_rdata),.mem_addr(pc),.io_addr(io_addr),.io_wdata(io_wdata),.io_re(io_re),.io_we(io_we),.data_addr(data_addr),.data_wdata(data_wdata),.data_re(data_re),.data_we(data_we));
always @(posedge clk) begin
 if(pc>1023)seen_high<=1;
 if(io_re && io_addr==8'h10)rx_valid<=0;
 if(io_we && io_addr==8'h10)begin
   frame[count%70]=io_wdata[7:0];
   checksum=checksum^io_wdata[7:0];
   count=count+1;
   if(count%70==0)begin
     if(checksum!=0)$fatal(1,"frame XOR");
     checksum=0;
   end
 end
end
task send;
 input [7:0] b;
 begin @(negedge clk);rx_byte=b;rx_valid=1;wait(!rx_valid);end
endtask
task move;
 input [7:0] a,b;
 integer goal;
 begin goal=count+70;send(242);send(a);send(b);send(0);wait(count==goal);@(negedge clk);if(frame[4]!=0)$fatal(1,"legal move rejected");end
endtask
initial begin
 #40;@(negedge clk);rst=0;wait(count==70);@(negedge clk);
 if(frame[1]!=7 || frame[5+4]!=6 || !seen_high)$fatal(1,"boot/12-bit PC");
 move(8'h15,8'h25); // f2-f3
 move(8'h64,8'h44); // e7-e5
 move(8'h16,8'h36); // g2-g4
 move(8'h73,8'h37); // Qd8-h4 mate
 if(frame[3]!=3)$fatal(1,"Fools mate not detected");
 send(244);wait(count==420);@(negedge clk);
 if(frame[2]!=64 || frame[3]!=0)$fatal(1,"AI mode reset");
 move(8'h14,8'h34); // human e2-e4, CPU replies before sending the frame
 if(frame[2]!=64 || frame[5+28]!=1)$fatal(1,"AI turn/human move");
 black_home=0;for(i=48;i<64;i=i+1)if(frame[5+i]&8)black_home=black_home+1;
 if(black_home!=15)$fatal(1,"AI did not develop one black piece");
 $display("CHESS4K RTL PASS: boot, high PC, checkmate, AI mode/autonomous reply, frame checksum");$finish;
end
initial begin #100000000;$fatal(1,"timeout");end
endmodule
