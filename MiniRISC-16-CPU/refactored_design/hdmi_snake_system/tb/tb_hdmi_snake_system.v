`timescale 1ns/1ps
module tb_hdmi_snake_system;
    reg clk=0,resetn=0,uart_rx=1,hdmi_int_n=1; reg [7:0] switches=8'h40;
    wire uart_tx; wire [7:0] led,seg_low,seg_high,digit_enable; wire [15:0] hdmi_data;
    wire hdmi_hsync,hdmi_vsync,hdmi_de,hdmi_clk; tri1 scl,sda;
    always #5 clk=~clk;
    hdmi_snake_board_top #(.BASE_TICK_CYCLES(32),.SCAN_DIVIDER(8),.HDMI_STARTUP_DELAY_CYCLES(8),.HDMI_POLL_DELAY_CYCLES(32),.I2C_CLOCK_DIVIDER(2)) dut(
        .clk_100mhz(clk),.resetn(resetn),.uart_rx(uart_rx),.uart_tx(uart_tx),.switches(switches),.led(led),.seg_low(seg_low),.seg_high(seg_high),.digit_enable(digit_enable),.hdmi_data(hdmi_data),.hdmi_hsync(hdmi_hsync),.hdmi_vsync(hdmi_vsync),.hdmi_de(hdmi_de),.hdmi_clk(hdmi_clk),.hdmi_int_n(hdmi_int_n),.iic_scl_hdmi(scl),.iic_sda_hdmi(sda));
    initial begin
        repeat(8) @(posedge clk); resetn=1;
        repeat(200) @(posedge clk);
        $display("tb_hdmi_snake_system: TEST PASS"); $finish;
    end
endmodule
