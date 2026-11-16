`timescale 1ns/1ps
module tb_i2c_master;
    reg clk=0,rst=1,start=0,read_req=0,slave_low=0;
    reg [7:0] reg_addr=8'h42,wdata=8'h55;
    wire [7:0] rdata; wire busy,done,ack_error;
    tri1 scl,sda;
    assign sda = slave_low ? 1'b0 : 1'bz;
    always #5 clk=~clk;
    i2c_master #(.CLOCK_DIVIDER(2)) dut(.clk(clk),.rst(rst),.start(start),.read_not_write(read_req),.device_address(7'h39),.register_address(reg_addr),.write_data(wdata),.read_data(rdata),.busy(busy),.done(done),.acknowledge_error(ack_error),.scl(scl),.sda(sda));
    task launch;
        input rd;
        begin
            @(negedge clk); read_req=rd; start=1;
            @(negedge clk); start=0;
            wait(done); @(negedge clk);
        end
    endtask
    initial begin
        repeat(4) @(posedge clk); rst=0;
        slave_low=1; launch(0);
        if(ack_error) $fatal(1,"ACKed write flagged error");
        launch(1);
        if(ack_error || rdata!=0) $fatal(1,"read transaction failed data=%02x",rdata);
        slave_low=0; launch(0);
        if(!ack_error) $fatal(1,"NACK was not detected");
        $display("tb_i2c_master: TEST PASS"); $finish;
    end
endmodule
