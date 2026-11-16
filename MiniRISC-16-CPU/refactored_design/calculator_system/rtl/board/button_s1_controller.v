`timescale 1ns/1ps

module button_s1_controller #(
    parameter integer DEBOUNCE_CYCLES = 1000000,
    parameter integer LONG_PRESS_CYCLES = 100000000
) (
    input  wire clk,
    input  wire por_rst,
    input  wire button_n,
    output reg  confirm_toggle,
    output reg  long_reset,
    output reg  input_valid
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

    localparam integer DEBOUNCE_WIDTH = clog2(DEBOUNCE_CYCLES);
    localparam integer PRESS_WIDTH = clog2(LONG_PRESS_CYCLES);

    reg sync_stage_1;
    reg sync_stage_2;
    reg candidate_pressed;
    reg debounced_pressed;
    reg [DEBOUNCE_WIDTH-1:0] stable_count;
    reg [PRESS_WIDTH-1:0] press_count;
    reg long_press_seen;

    wire synchronized_pressed = ~sync_stage_2;

    always @(posedge clk) begin
        if (por_rst) begin
            sync_stage_1      <= 1'b1;
            sync_stage_2      <= 1'b1;
            candidate_pressed <= 1'b0;
            debounced_pressed <= 1'b0;
            stable_count      <= {DEBOUNCE_WIDTH{1'b0}};
            press_count       <= {PRESS_WIDTH{1'b0}};
            long_press_seen   <= 1'b0;
            confirm_toggle    <= 1'b0;
            long_reset        <= 1'b0;
            input_valid       <= 1'b0;
        end else begin
            sync_stage_1 <= button_n;
            sync_stage_2 <= sync_stage_1;

            if (synchronized_pressed != candidate_pressed) begin
                candidate_pressed <= synchronized_pressed;
                stable_count <= {DEBOUNCE_WIDTH{1'b0}};
            end else if (!input_valid || candidate_pressed != debounced_pressed) begin
                if ((DEBOUNCE_CYCLES <= 1) ||
                    (stable_count == DEBOUNCE_CYCLES - 1)) begin
                    stable_count <= {DEBOUNCE_WIDTH{1'b0}};
                    if (!input_valid) begin
                        debounced_pressed <= candidate_pressed;
                        input_valid <= 1'b1;
                        press_count <= {PRESS_WIDTH{1'b0}};
                        long_press_seen <= 1'b0;
                    end else begin
                        debounced_pressed <= candidate_pressed;
                        if (candidate_pressed) begin
                            press_count <= {PRESS_WIDTH{1'b0}};
                            long_press_seen <= 1'b0;
                            long_reset <= 1'b0;
                        end else begin
                            if (!long_press_seen)
                                confirm_toggle <= ~confirm_toggle;
                            press_count <= {PRESS_WIDTH{1'b0}};
                            long_press_seen <= 1'b0;
                            long_reset <= 1'b0;
                        end
                    end
                end else begin
                    stable_count <= stable_count + 1'b1;
                end
            end else begin
                stable_count <= {DEBOUNCE_WIDTH{1'b0}};
            end

            if (input_valid && candidate_pressed == debounced_pressed) begin
                if (debounced_pressed) begin
                    if (!long_press_seen) begin
                        if ((LONG_PRESS_CYCLES <= 1) ||
                            (press_count == LONG_PRESS_CYCLES - 1)) begin
                            long_press_seen <= 1'b1;
                            long_reset <= 1'b1;
                        end else begin
                            press_count <= press_count + 1'b1;
                        end
                    end else begin
                        long_reset <= 1'b1;
                    end
                end else begin
                    press_count <= {PRESS_WIDTH{1'b0}};
                    long_reset <= 1'b0;
                end
            end
        end
    end
endmodule
