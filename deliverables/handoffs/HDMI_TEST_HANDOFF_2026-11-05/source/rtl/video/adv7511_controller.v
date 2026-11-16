`timescale 1ns/1ps

module adv7511_controller #(
    parameter integer STARTUP_DELAY_CYCLES = 1000000,
    parameter integer POLL_DELAY_CYCLES = 1000000,
    parameter integer I2C_CLOCK_DIVIDER = 250
) (
    input  wire clk,
    input  wire rst,
    input  wire hdmi_int_n,
    output reg  ready,
    output reg  fault,
    output reg  hpd_present,
    output wire [3:0] debug_state,
    output wire       debug_i2c_busy,
    output wire [4:0] debug_i2c_state,
    output wire       debug_i2c_scl,
    output wire       debug_i2c_sda,
    output wire       debug_i2c_ack_error,
    output wire       debug_i2c_scl_drive_low,
    inout  wire iic_scl_hdmi,
    inout  wire iic_sda_hdmi
);
    localparam C_DELAY=0, C_HPD_START=1, C_HPD_WAIT=2, C_POLL_WAIT=3,
               C_WRITE_START=4, C_WRITE_WAIT=5, C_PLL_DELAY=6,
               C_PLL_START=7, C_PLL_WAIT=8, C_READY_WAIT=9;
    reg [3:0] state;
    reg [31:0] delay_count;
    reg [5:0] table_index;
    reg [1:0] retry_count;
    reg master_start, master_read;
    reg [7:0] master_register, master_wdata;
    wire [7:0] master_rdata;
    wire master_busy, master_done, master_ack_error;
    assign debug_state = state;
    assign debug_i2c_busy = master_busy;
    assign debug_i2c_ack_error = master_ack_error;
    reg [7:0] table_register, table_value;

    i2c_master #(.CLOCK_DIVIDER(I2C_CLOCK_DIVIDER)) u_i2c_master (
        .clk(clk),.rst(rst),.start(master_start),.read_not_write(master_read),
        .device_address(7'h39),.register_address(master_register),
        .write_data(master_wdata),.read_data(master_rdata),.busy(master_busy),
        .done(master_done),.acknowledge_error(master_ack_error),
        .debug_state(debug_i2c_state),.debug_scl_in(debug_i2c_scl),
        .debug_sda_in(debug_i2c_sda),
        .debug_scl_drive_low(debug_i2c_scl_drive_low),
        .scl(iic_scl_hdmi),.sda(iic_sda_hdmi)
    );

    always @* begin
        table_register = 8'h00; table_value = 8'h00;
        case (table_index)
            0:begin table_register=8'h41;table_value=8'h10;end
            1:begin table_register=8'h98;table_value=8'h03;end
            2:begin table_register=8'h9A;table_value=8'hE0;end
            3:begin table_register=8'h9C;table_value=8'h30;end
            4:begin table_register=8'h9D;table_value=8'h61;end
            5:begin table_register=8'hA2;table_value=8'hA4;end
            6:begin table_register=8'hA3;table_value=8'hA4;end
            7:begin table_register=8'hE0;table_value=8'hD0;end
            8:begin table_register=8'hF9;table_value=8'h00;end
            9:begin table_register=8'h15;table_value=8'h01;end
            10:begin table_register=8'h16;table_value=8'h34;end
            11:begin table_register=8'h48;table_value=8'h08;end
            12:begin table_register=8'h17;table_value=8'h00;end
            13:begin table_register=8'hBA;table_value=8'h60;end
            14:begin table_register=8'h3B;table_value=8'h40;end
            15:begin table_register=8'h3C;table_value=8'h01;end
            16:begin table_register=8'h18;table_value=8'hE6;end
            17:begin table_register=8'h19;table_value=8'h69;end
            18:begin table_register=8'h1A;table_value=8'h04;end
            19:begin table_register=8'h1B;table_value=8'hAC;end
            20:begin table_register=8'h1C;table_value=8'h00;end
            21:begin table_register=8'h1D;table_value=8'h00;end
            22:begin table_register=8'h1E;table_value=8'h1C;end
            23:begin table_register=8'h1F;table_value=8'h81;end
            24:begin table_register=8'h20;table_value=8'h1C;end
            25:begin table_register=8'h21;table_value=8'hBC;end
            26:begin table_register=8'h22;table_value=8'h04;end
            27:begin table_register=8'h23;table_value=8'hAD;end
            28:begin table_register=8'h24;table_value=8'h1E;end
            29:begin table_register=8'h25;table_value=8'h6E;end
            30:begin table_register=8'h26;table_value=8'h02;end
            31:begin table_register=8'h27;table_value=8'h20;end
            32:begin table_register=8'h28;table_value=8'h1F;end
            33:begin table_register=8'h29;table_value=8'hFE;end
            34:begin table_register=8'h2A;table_value=8'h04;end
            35:begin table_register=8'h2B;table_value=8'hAD;end
            36:begin table_register=8'h2C;table_value=8'h08;end
            37:begin table_register=8'h2D;table_value=8'h1A;end
            38:begin table_register=8'h2E;table_value=8'h1B;end
            39:begin table_register=8'h2F;table_value=8'hA9;end
            40:begin table_register=8'hAF;table_value=8'h02;end
            41:begin table_register=8'h40;table_value=8'h80;end
            42:begin table_register=8'h4C;table_value=8'h00;end
            43:begin table_register=8'h4A;table_value=8'h80;end
            44:begin table_register=8'h55;table_value=8'h02;end
            45:begin table_register=8'h56;table_value=8'h10;end
            46:begin table_register=8'h57;table_value=8'h08;end
            47:begin table_register=8'h44;table_value=8'h10;end
            48:begin table_register=8'h0B;table_value=8'h00;end
            49:begin table_register=8'hD6;table_value=8'h00;end
            default:begin table_register=8'h00;table_value=8'h00;end
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            state<=C_DELAY; delay_count<=0; table_index<=0; retry_count<=0;
            master_start<=0; master_read<=0; master_register<=0; master_wdata<=0;
            ready<=0; fault<=0; hpd_present<=0;
        end else begin
            master_start <= 1'b0;
            case (state)
                C_DELAY: begin
                    ready<=0;
                    if (delay_count>=STARTUP_DELAY_CYCLES-1) begin delay_count<=0;state<=C_HPD_START;end
                    else delay_count<=delay_count+1;
                end
                C_HPD_START: if(!master_busy) begin master_read<=1;master_register<=8'h42;master_start<=1;state<=C_HPD_WAIT;end
                C_HPD_WAIT: if(master_done) begin
                    if(master_ack_error) begin fault<=1;hpd_present<=0;delay_count<=0;state<=C_POLL_WAIT;end
                    else if(master_rdata[6]) begin hpd_present<=1;fault<=0;table_index<=0;retry_count<=0;state<=C_WRITE_START;end
                    else begin hpd_present<=0;ready<=0;delay_count<=0;state<=C_POLL_WAIT;end
                end
                C_POLL_WAIT: begin
                    if(delay_count>=POLL_DELAY_CYCLES-1 || !hdmi_int_n) begin delay_count<=0;state<=C_HPD_START;end
                    else delay_count<=delay_count+1;
                end
                C_WRITE_START: if(!master_busy) begin
                    master_read<=0;master_register<=table_register;master_wdata<=table_value;master_start<=1;state<=C_WRITE_WAIT;
                end
                C_WRITE_WAIT: if(master_done) begin
                    if(master_ack_error) begin
                        if(retry_count==3) begin fault<=1;ready<=0;delay_count<=0;state<=C_POLL_WAIT;end
                        else begin retry_count<=retry_count+1;state<=C_WRITE_START;end
                    end else begin
                        retry_count<=0;
                        if(table_index==49) begin delay_count<=0;state<=C_PLL_DELAY;end
                        else begin table_index<=table_index+1;state<=C_WRITE_START;end
                    end
                end
                C_PLL_DELAY: begin
                    if(delay_count>=STARTUP_DELAY_CYCLES-1) begin delay_count<=0;state<=C_PLL_START;end
                    else delay_count<=delay_count+1;
                end
                C_PLL_START: if(!master_busy) begin master_read<=1;master_register<=8'h9E;master_start<=1;state<=C_PLL_WAIT;end
                C_PLL_WAIT: if(master_done) begin
                    if(!master_ack_error && master_rdata[4]) begin ready<=1;fault<=0;delay_count<=0;state<=C_READY_WAIT;end
                    else begin fault<=1;ready<=0;delay_count<=0;state<=C_POLL_WAIT;end
                end
                C_READY_WAIT: begin
                    if(delay_count>=POLL_DELAY_CYCLES-1 || !hdmi_int_n) begin delay_count<=0;state<=C_HPD_START;end
                    else delay_count<=delay_count+1;
                end
                default: state<=C_DELAY;
            endcase
        end
    end
endmodule
