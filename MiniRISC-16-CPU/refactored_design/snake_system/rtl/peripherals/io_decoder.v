`timescale 1ns/1ps

module io_decoder (
    input  wire [7:0]  address,
    input  wire        read_enable,
    input  wire        write_enable,
    input  wire [15:0] uart_data,
    input  wire [15:0] uart_status,
    input  wire [15:0] timer_data,
    input  wire [15:0] rng_data,
    input  wire [15:0] led_data,
    input  wire [15:0] switch_data,
    input  wire [15:0] flags_data,
    input  wire [15:0] scratch_data,
    output reg  [15:0] read_data,
    output wire uart_data_read,
    output wire uart_data_write,
    output wire timer_read,
    output wire rng_read,
    output wire display_low_write,
    output wire display_high_write,
    output wire display_control_write,
    output wire led_write,
    output wire scratch_write
);
    assign uart_data_read = read_enable && address == 8'h10;
    assign uart_data_write = write_enable && address == 8'h10;
    assign timer_read = read_enable && address == 8'h12;
    assign rng_read = read_enable && address == 8'h13;
    assign display_low_write = write_enable && address == 8'h20;
    assign display_high_write = write_enable && address == 8'h21;
    assign display_control_write = write_enable && address == 8'h22;
    assign led_write = write_enable && address == 8'h30;
    assign scratch_write = write_enable && address >= 8'h40 && address <= 8'h4F;

    always @* begin
        read_data = 16'h0000;
        if (read_enable) begin
            case (address)
                8'h10: read_data = uart_data;
                8'h11: read_data = uart_status;
                8'h12: read_data = timer_data;
                8'h13: read_data = rng_data;
                8'h30: read_data = led_data;
                8'h31: read_data = switch_data;
                8'h32: read_data = flags_data;
                default: if (address >= 8'h40 && address <= 8'h4F)
                    read_data = scratch_data;
            endcase
        end
    end
endmodule
