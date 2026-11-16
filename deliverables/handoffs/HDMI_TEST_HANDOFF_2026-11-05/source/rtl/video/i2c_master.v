`timescale 1ns/1ps

module i2c_master #(
    parameter integer CLOCK_DIVIDER = 250
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       start,
    input  wire       read_not_write,
    input  wire [6:0] device_address,
    input  wire [7:0] register_address,
    input  wire [7:0] write_data,
    output reg  [7:0] read_data,
    output reg        busy,
    output reg        done,
    output reg        acknowledge_error,
    output wire [4:0] debug_state,
    output wire       debug_scl_in,
    output wire       debug_sda_in,
    output wire       debug_scl_drive_low,
    inout  wire       scl,
    inout  wire       sda
);
    localparam S_IDLE=0, S_START_A=1, S_START_B=2, S_START_C=3,
               S_TX_SETUP=4, S_TX_HIGH=5, S_TX_LOW=6,
               S_ACK_RELEASE=7, S_ACK_HIGH=8, S_ACK_LOW=9,
               S_RSTART_A=10, S_RSTART_B=11, S_RSTART_C=12, S_RSTART_D=13,
               S_RX_SETUP=14, S_RX_HIGH=15, S_RX_LOW=16,
               S_NACK_SETUP=17, S_NACK_HIGH=18, S_NACK_LOW=19,
               S_STOP_A=20, S_STOP_B=21, S_STOP_C=22;
    reg [4:0] state;
    reg [15:0] divider_count;
    reg scl_low, sda_low;
    reg [7:0] tx_byte, rx_shift;
    reg [2:0] bit_index;
    reg [2:0] tx_stage;
    reg request_read;
    reg [6:0] saved_device;
    reg [7:0] saved_register, saved_data;
    wire tick = (divider_count == CLOCK_DIVIDER-1);
    wire scl_in = scl;
    wire sda_in = sda;
    assign debug_state = state;
    assign debug_scl_in = scl_in;
    assign debug_sda_in = sda_in;
    assign debug_scl_drive_low = scl_low;

    assign scl = scl_low ? 1'b0 : 1'bz;
    assign sda = sda_low ? 1'b0 : 1'bz;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE; divider_count <= 0; scl_low <= 0; sda_low <= 0;
            read_data <= 0; busy <= 0; done <= 0; acknowledge_error <= 0;
            tx_byte <= 0; rx_shift <= 0; bit_index <= 0; tx_stage <= 0;
            request_read <= 0; saved_device <= 0; saved_register <= 0; saved_data <= 0;
        end else begin
            done <= 1'b0;
            if (state == S_IDLE) begin
                divider_count <= 0;
                scl_low <= 0;
                sda_low <= 0;
                busy <= 0;
                if (start) begin
                    busy <= 1;
                    acknowledge_error <= 0;
                    request_read <= read_not_write;
                    saved_device <= device_address;
                    saved_register <= register_address;
                    saved_data <= write_data;
                    tx_byte <= {device_address,1'b0};
                    tx_stage <= 0;
                    bit_index <= 7;
                    state <= S_START_A;
                end
            end else if (tick) begin
                divider_count <= 0;
                case (state)
                    S_START_A: begin scl_low<=0; sda_low<=0; state<=S_START_B; end
                    S_START_B: begin scl_low<=0; sda_low<=1; state<=S_START_C; end
                    S_START_C: begin scl_low<=1; sda_low<=1; state<=S_TX_SETUP; end
                    S_TX_SETUP: begin sda_low<=~tx_byte[bit_index]; scl_low<=1; state<=S_TX_HIGH; end
                    S_TX_HIGH: begin
                        scl_low<=0;
                        if (scl_in) state<=S_TX_LOW;
                    end
                    S_TX_LOW: begin
                        scl_low<=1;
                        if (bit_index==0) state<=S_ACK_RELEASE;
                        else begin bit_index<=bit_index-1'b1; state<=S_TX_SETUP; end
                    end
                    S_ACK_RELEASE: begin sda_low<=0; scl_low<=1; state<=S_ACK_HIGH; end
                    S_ACK_HIGH: begin
                        scl_low<=0;
                        if (scl_in) begin
                            if (sda_in) acknowledge_error<=1;
                            state<=S_ACK_LOW;
                        end
                    end
                    S_ACK_LOW: begin
                        scl_low<=1;
                        if (acknowledge_error) begin state<=S_STOP_A; end
                        else if (tx_stage==0) begin
                            tx_stage<=1; tx_byte<=saved_register; bit_index<=7; state<=S_TX_SETUP;
                        end else if (tx_stage==1 && request_read) begin
                            state<=S_RSTART_A;
                        end else if (tx_stage==1) begin
                            tx_stage<=2; tx_byte<=saved_data; bit_index<=7; state<=S_TX_SETUP;
                        end else if (tx_stage==2) begin
                            state<=S_STOP_A;
                        end else begin
                            bit_index<=7; rx_shift<=0; state<=S_RX_SETUP;
                        end
                    end
                    S_RSTART_A: begin sda_low<=0; scl_low<=1; state<=S_RSTART_B; end
                    S_RSTART_B: begin scl_low<=0; sda_low<=0; if(scl_in) state<=S_RSTART_C; end
                    S_RSTART_C: begin scl_low<=0; sda_low<=1; state<=S_RSTART_D; end
                    S_RSTART_D: begin
                        scl_low<=1; tx_stage<=3; tx_byte<={saved_device,1'b1}; bit_index<=7; state<=S_TX_SETUP;
                    end
                    S_RX_SETUP: begin sda_low<=0; scl_low<=1; state<=S_RX_HIGH; end
                    S_RX_HIGH: begin
                        scl_low<=0;
                        if (scl_in) begin rx_shift[bit_index]<=sda_in; state<=S_RX_LOW; end
                    end
                    S_RX_LOW: begin
                        scl_low<=1;
                        if (bit_index==0) begin read_data<={rx_shift[7:1],rx_shift[0]}; state<=S_NACK_SETUP; end
                        else begin bit_index<=bit_index-1'b1; state<=S_RX_SETUP; end
                    end
                    S_NACK_SETUP: begin sda_low<=0; scl_low<=1; state<=S_NACK_HIGH; end
                    S_NACK_HIGH: begin scl_low<=0; if(scl_in) state<=S_NACK_LOW; end
                    S_NACK_LOW: begin scl_low<=1; state<=S_STOP_A; end
                    S_STOP_A: begin sda_low<=1; scl_low<=1; state<=S_STOP_B; end
                    S_STOP_B: begin scl_low<=0; sda_low<=1; if(scl_in) state<=S_STOP_C; end
                    S_STOP_C: begin
                        sda_low<=0; scl_low<=0; busy<=0; done<=1; state<=S_IDLE;
                    end
                    default: state<=S_IDLE;
                endcase
            end else begin
                divider_count <= divider_count + 1'b1;
            end
        end
    end
endmodule
