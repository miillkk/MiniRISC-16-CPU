`timescale 1ns/1ps

module tb_program_loader;
    localparam CLKS=8;
    reg clk=0, rst=1, load_mode=1, rx=1;
    wire tx, program_we, loaded, error, busy;
    wire [9:0] program_addr;
    wire [15:0] program_wdata;
    wire [7:0] reply_data;
    wire reply_valid;
    reg [15:0] captured [0:1023];
    integer replies=0;

    always #5 clk=~clk;
    always @(posedge clk) begin
        if(program_we) captured[program_addr] <= program_wdata;
        if(reply_valid) begin
            if(reply_data!==8'h06) $fatal(1,"unexpected loader reply %h",reply_data);
            replies <= replies+1;
        end
    end
    program_loader #(.CLKS_PER_BIT(CLKS)) dut (
        .clk(clk), .rst(rst), .load_mode(load_mode), .rx(rx), .tx(tx),
        .program_we(program_we), .program_addr(program_addr),
        .program_wdata(program_wdata), .loaded(loaded), .error(error), .busy(busy)
    );
    uart_rx #(.CLKS_PER_BIT(CLKS)) monitor (
        .clk(clk), .rst(rst), .rx(tx), .data(reply_data), .valid(reply_valid)
    );

    task send_byte;
        input [7:0] value;
        integer bit_no;
        begin
            rx=0; repeat(CLKS) @(posedge clk);
            for(bit_no=0;bit_no<8;bit_no=bit_no+1) begin
                rx=value[bit_no]; repeat(CLKS) @(posedge clk);
            end
            rx=1; repeat(CLKS) @(posedge clk);
        end
    endtask

    initial begin
        repeat(4) @(posedge clk); rst=0;
        send_byte(8'h55); send_byte(8'h4C);
        send_byte(8'h00); send_byte(8'h02);
        send_byte(8'h12); send_byte(8'h34);
        send_byte(8'hAB); send_byte(8'hCD);
        send_byte(8'hBE); send_byte(8'h01); // 1234+ABCD=BE01
        repeat(200) @(posedge clk);
        if(!loaded || error || replies!=1) $fatal(1,"valid upload was not accepted");
        if(captured[0]!=16'h1234 || captured[1]!=16'hABCD)
            $fatal(1,"program words were not written");
        $display("tb_program_loader: TEST PASS");
        $finish;
    end
endmodule
