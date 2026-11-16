`timescale 1ns/1ps

module tb_uart_port;
    localparam CLKS = 8;
    reg clk = 0, rst = 1, rx = 1;
    reg read_data = 0, write_data = 0;
    reg [7:0] cpu_wdata = 0;
    wire tx;
    wire [15:0] data_rdata, status_rdata;
    wire [7:0] monitor_data;
    wire monitor_valid;

    always #5 clk = ~clk;
    uart_port #(.CLKS_PER_BIT(CLKS)) dut (
        .clk(clk), .rst(rst), .rx(rx), .tx(tx), .read_data(read_data),
        .write_data(write_data), .cpu_wdata(cpu_wdata),
        .data_rdata(data_rdata), .status_rdata(status_rdata)
    );
    uart_rx #(.CLKS_PER_BIT(CLKS)) monitor (
        .clk(clk), .rst(rst), .rx(tx), .data(monitor_data), .valid(monitor_valid)
    );

    task send_rx;
        input [7:0] value;
        integer i;
        begin
            rx = 0; repeat(CLKS) @(posedge clk);
            for (i=0;i<8;i=i+1) begin rx=value[i]; repeat(CLKS) @(posedge clk); end
            rx = 1; repeat(CLKS) @(posedge clk);
        end
    endtask

    initial begin
        repeat(3) @(posedge clk); rst=0;
        send_rx(8'h57);
        repeat(4) @(posedge clk);
        if (!status_rdata[0] || data_rdata[7:0] != 8'h57) $fatal(1,"UART RX failed");
        read_data=1; @(posedge clk); #1; read_data=0;
        if (status_rdata[0]) $fatal(1,"UART RX pop failed");
        cpu_wdata=8'hA5; write_data=1; @(posedge clk); #1; write_data=0;
        wait(monitor_valid); #1;
        if (monitor_data != 8'hA5) $fatal(1,"UART TX failed");
        $display("tb_uart_port: TEST PASS");
        $finish;
    end
endmodule
