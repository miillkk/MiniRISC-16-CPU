`timescale 1ns/1ps

module tick_timer #(
    parameter integer BASE_TICK_CYCLES = 50000000
) (
    input  wire        clk,
    input  wire        rst,
    input  wire [1:0]  speed,
    input  wire        pause,
    input  wire        acknowledge,
    output wire [15:0] read_data
);
    reg [31:0] counter;
    reg tick_pending;
    reg half_tick;
    wire [31:0] selected_cycles = (BASE_TICK_CYCLES >> speed) < 2 ? 2 : (BASE_TICK_CYCLES >> speed);

    always @(posedge clk) begin
        if (rst) begin
            counter <= 32'd0;
            tick_pending <= 1'b0;
            half_tick <= 1'b0;
        end else begin
            if (acknowledge) tick_pending <= 1'b0;
            // A pending tick is a one-entry event queue. Freeze the divider
            // until the CPU consumes it so a slow UART frame cannot create an
            // immediate second movement after the acknowledge cycle.
            if (!pause && !tick_pending) begin
                if (counter >= selected_cycles - 1) begin
                    counter <= 32'd0;
                    if (half_tick) begin
                        half_tick <= 1'b0;
                        tick_pending <= 1'b1;
                    end else begin
                        half_tick <= 1'b1;
                    end
                end else counter <= counter + 1'b1;
            end
        end
    end
    assign read_data = {15'h0000, tick_pending};
endmodule
