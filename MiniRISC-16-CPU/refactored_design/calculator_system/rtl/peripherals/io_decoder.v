`timescale 1ns/1ps

module io_decoder (
    input  wire [7:0]  io_addr,
    input  wire        io_re,
    input  wire        io_we,
    input  wire [15:0] display_low_rdata,
    input  wire [15:0] display_high_rdata,
    input  wire [15:0] display_control_rdata,
    input  wire [15:0] led_rdata,
    input  wire [15:0] switch_rdata,
    input  wire [15:0] input_control_rdata,
    input  wire [15:0] status_rdata,
    input  wire [15:0] scratchpad_rdata,
    output reg  [15:0] io_rdata,
    output reg         display_low_write,
    output reg         display_high_write,
    output reg         display_control_write,
    output reg         led_write,
    output reg         scratchpad_write
);
    localparam DISPLAY_LOW_ADDR     = 8'h20;
    localparam DISPLAY_HIGH_ADDR    = 8'h21;
    localparam DISPLAY_CONTROL_ADDR = 8'h22;
    localparam LED_ADDR             = 8'h30;
    localparam SWITCH_ADDR          = 8'h31;
    localparam STATUS_ADDR          = 8'h32;
    localparam INPUT_CONTROL_ADDR   = 8'h33;

    wire scratchpad_selected = (io_addr[7:4] == 4'h4);

    always @* begin
        display_low_write     = 1'b0;
        display_high_write    = 1'b0;
        display_control_write = 1'b0;
        led_write             = 1'b0;
        scratchpad_write      = 1'b0;
        if (io_we) begin
            if (scratchpad_selected) begin
                scratchpad_write = 1'b1;
            end else begin
                case (io_addr)
                    DISPLAY_LOW_ADDR:     display_low_write = 1'b1;
                    DISPLAY_HIGH_ADDR:    display_high_write = 1'b1;
                    DISPLAY_CONTROL_ADDR: display_control_write = 1'b1;
                    LED_ADDR:             led_write = 1'b1;
                    default: begin end
                endcase
            end
        end
    end

    always @* begin
        io_rdata = 16'h0000;
        if (io_re) begin
            if (scratchpad_selected) begin
                io_rdata = scratchpad_rdata;
            end else begin
                case (io_addr)
                    DISPLAY_LOW_ADDR:     io_rdata = display_low_rdata;
                    DISPLAY_HIGH_ADDR:    io_rdata = display_high_rdata;
                    DISPLAY_CONTROL_ADDR: io_rdata = display_control_rdata;
                    LED_ADDR:             io_rdata = led_rdata;
                    SWITCH_ADDR:          io_rdata = switch_rdata;
                    STATUS_ADDR:          io_rdata = status_rdata;
                    INPUT_CONTROL_ADDR:   io_rdata = input_control_rdata;
                    default:              io_rdata = 16'h0000;
                endcase
            end
        end
    end
endmodule
