`timescale 1ns/1ps

module seven_segment8_driver #(
    parameter integer SCAN_DIVIDER = 100000
) (
    input  wire        clk,
    input  wire        rst,
    input  wire [15:0] low_value,
    input  wire [15:0] high_value,
    input  wire [15:0] control_value,
    output reg  [7:0]  seg_low,
    output reg  [7:0]  seg_high,
    output reg  [7:0]  digit_enable
);
    function integer clog2;
        input integer value;
        integer work;
        begin
            work = value - 1;
            clog2 = 0;
            while (work > 0) begin
                clog2 = clog2 + 1;
                work = work >> 1;
            end
            if (clog2 < 1) clog2 = 1;
        end
    endfunction

    localparam integer COUNTER_WIDTH = clog2(SCAN_DIVIDER);
    reg [COUNTER_WIDTH-1:0] scan_counter;
    reg [2:0] scan_index;
    reg blanking;
    reg [3:0] selected_nibble;
    wire [6:0] decoded_segments;
    wire selected_dp = control_value[8 + scan_index];

    hex_to_7seg u_hex_to_7seg (
        .hex_value(selected_nibble), .segments(decoded_segments)
    );

    always @(posedge clk) begin
        if (rst) begin
            scan_counter <= {COUNTER_WIDTH{1'b0}};
            scan_index <= 3'd0;
            blanking <= 1'b1;
        end else if (SCAN_DIVIDER <= 1) begin
            scan_counter <= {COUNTER_WIDTH{1'b0}};
            scan_index <= scan_index + 3'd1;
            blanking <= 1'b0;
        end else if (scan_counter == SCAN_DIVIDER - 1) begin
            scan_counter <= {COUNTER_WIDTH{1'b0}};
            scan_index <= scan_index + 3'd1;
            blanking <= 1'b1;
        end else begin
            scan_counter <= scan_counter + 1'b1;
            blanking <= 1'b0;
        end
    end

    always @* begin
        case (scan_index)
            3'd0: selected_nibble = low_value[3:0];
            3'd1: selected_nibble = low_value[7:4];
            3'd2: selected_nibble = low_value[11:8];
            3'd3: selected_nibble = low_value[15:12];
            3'd4: selected_nibble = high_value[3:0];
            3'd5: selected_nibble = high_value[7:4];
            3'd6: selected_nibble = high_value[11:8];
            default: selected_nibble = high_value[15:12];
        endcase
    end

    always @* begin
        seg_low = 8'h00;
        seg_high = 8'h00;
        digit_enable = 8'h00;
        if (control_value[0] && !blanking) begin
            digit_enable[scan_index] = 1'b1;
            if (scan_index < 3'd4)
                seg_low = {selected_dp, decoded_segments};
            else
                seg_high = {selected_dp, decoded_segments};
        end
    end
endmodule
