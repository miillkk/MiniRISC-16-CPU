`timescale 1ns/1ps
module tb_loader4k;
localparam CLKS=8;
reg clk=0,rst=1,rx=1;
always #5 clk=~clk;
wire tx,we,loaded,error,busy;
wire [11:0] address;
wire [15:0] data;
wire [7:0] reply;
wire valid;
reg [7:0] replies[0:31];
reg [15:0] captured[0:4095];
integer count=0,i;
reg [15:0] sum;
program_loader #(.CLKS_PER_BIT(CLKS)) dut(.clk(clk),.rst(rst),.load_mode(1'b1),.rx(rx),.tx(tx),.program_we(we),.program_addr(address),.program_wdata(data),.loaded(loaded),.error(error),.busy(busy));
uart_rx #(.CLKS_PER_BIT(CLKS)) monitor(.clk(clk),.rst(rst),.rx(tx),.data(reply),.valid(valid));
always @(posedge clk)begin if(we)captured[address]<=data;if(valid)begin replies[count]=reply;count=count+1;end end
task send;
input [7:0] b;
integer k;
begin @(negedge clk);rx=0;repeat(CLKS)@(negedge clk);for(k=0;k<8;k=k+1)begin rx=b[k];repeat(CLKS)@(negedge clk);end rx=1;repeat(CLKS)@(negedge clk);end
endtask
task upload;
input integer length;
integer k;
begin
send(8'h55);send(8'h4c);send(length>>8);send(length&255);sum=0;
for(k=0;k<length;k=k+1)begin send(k>>8);send(k&255);sum=sum+k;end
send(sum>>8);send(sum&255);repeat(200)@(negedge clk);
if(!loaded || error)$fatal(1,"upload rejected");
for(k=0;k<length;k=k+1)if(captured[k]!==k)$fatal(1,"address/data mismatch %d",k);
end
endtask
initial begin
repeat(4)@(negedge clk);rst=0;
send(8'h55);send(8'h49);repeat(800)@(negedge clk);
if(count!=7 || replies[0]!=8'h4d || replies[4]!=16 || replies[5]!=0)$fatal(1,"identity capacity");
upload(4096);if(replies[7]!=6)$fatal(1,"4K ACK");
upload(1024);if(replies[8]!=6)$fatal(1,"legacy ACK");
send(8'h55);send(8'h4c);send(8'h20);send(0);repeat(200)@(negedge clk);
if(replies[9]!=8'h15 || !error)$fatal(1,"oversize rejection");
$display("LOADER4K RTL PASS: identity, 4096 addresses, legacy 1024, oversize reject");$finish;
end
initial begin #100000000;$fatal(1,"timeout");end
endmodule
