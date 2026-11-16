`timescale 1ns/1ps

module led8 (
    input  wire        clk,
    input  wire        rst,
    input  wire        write_enable,
    input  wire [7:0]  write_data,
    output wire [15:0] read_data,
    output wire [7:0]  led
);
    reg [7:0] led_value;

    always @(posedge clk) begin
        if (rst)
            led_value <= 8'h00;
        else if (write_enable)
            led_value <= write_data;
    end

    assign read_data = {8'h00, led_value};
    assign led       = led_value;
endmodule
