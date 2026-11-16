`timescale 1ns/1ps

// Binary UART program loader. The board enters loader mode while SW7=1.
// Packet: 55 4C LEN_H LEN_L, LEN big-endian 16-bit words, SUM_H SUM_L.
// SUM is the 16-bit modulo sum of all program words. Responses: ACK=06,
// NAK=15. The 55 49 command returns "MR16", capacity 1000 and status.
module program_loader #(
    parameter integer CLKS_PER_BIT = 868
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        load_mode,
    input  wire        rx,
    output wire        tx,
    output reg         program_we,
    output reg  [11:0]  program_addr,
    output reg  [15:0] program_wdata,
    output reg         loaded,
    output reg         error,
    output wire        busy
);
    localparam ST_SYNC  = 4'd0;
    localparam ST_CMD   = 4'd1;
    localparam ST_LEN_H = 4'd2;
    localparam ST_LEN_L = 4'd3;
    localparam ST_DATA_H= 4'd4;
    localparam ST_DATA_L= 4'd5;
    localparam ST_SUM_H = 4'd6;
    localparam ST_SUM_L = 4'd7;

    wire [7:0] rx_data;
    wire rx_valid;
    wire tx_ready;
    reg [3:0] state;
    reg [15:0] word_count;
    reg [15:0] word_index;
    reg [7:0] data_high;
    reg [15:0] checksum;
    reg [7:0] checksum_high;
    reg [7:0] response [0:7];
    reg [3:0] response_count;
    integer shift_index;

    wire tx_write = load_mode && (response_count != 0) && tx_ready;
    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_loader_rx (
        .clk(clk), .rst(rst), .rx(rx), .data(rx_data), .valid(rx_valid)
    );
    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_loader_tx (
        .clk(clk), .rst(rst), .write_enable(tx_write),
        .write_data(response[0]), .tx(tx), .ready(tx_ready)
    );

    assign busy = load_mode && (state != ST_SYNC || response_count != 0);

    task queue_ack;
        input [7:0] value;
        begin
            response[0] <= value;
            response_count <= 1;
        end
    endtask

    always @(posedge clk) begin
        if (rst) begin
            state <= ST_SYNC;
            word_count <= 0;
            word_index <= 0;
            data_high <= 0;
            checksum <= 0;
            checksum_high <= 0;
            response_count <= 0;
            response[0] <= 0;
            response[1] <= 0;
            response[2] <= 0;
            response[3] <= 0;
            response[4] <= 0;
            response[5] <= 0;
            response[6] <= 0;
            response[7] <= 0;
            program_we <= 0;
            program_addr <= 0;
            program_wdata <= 0;
            loaded <= 0;
            error <= 0;
        end else begin
            program_we <= 0;
            if (tx_write) begin
                for (shift_index = 0; shift_index < 7; shift_index = shift_index + 1)
                    response[shift_index] <= response[shift_index + 1];
                response_count <= response_count - 1'b1;
            end
            if (!load_mode) begin
                state <= ST_SYNC;
                response_count <= 0;
            end else if (rx_valid) begin
                case (state)
                    ST_SYNC: if (rx_data == 8'h55) state <= ST_CMD;
                    ST_CMD: begin
                        if (rx_data == 8'h49) begin
                            response[0] <= 8'h4D;
                            response[1] <= 8'h52;
                            response[2] <= 8'h31;
                            response[3] <= 8'h36;
                            response[4] <= 8'h10;
                            response[5] <= 8'h00;
                            response[6] <= {6'b0, error, loaded};
                            response_count <= 7;
                            state <= ST_SYNC;
                        end else if (rx_data == 8'h4C) begin
                            loaded <= 0;
                            error <= 0;
                            state <= ST_LEN_H;
                        end else begin
                            error <= 1;
                            queue_ack(8'h15);
                            state <= ST_SYNC;
                        end
                    end
                    ST_LEN_H: begin
                        word_count[15:8] <= rx_data;
                        state <= ST_LEN_L;
                    end
                    ST_LEN_L: begin
                        word_count[7:0] <= rx_data;
                        word_index <= 0;
                        checksum <= 0;
                        if (({word_count[15:8], rx_data} == 0) ||
                            ({word_count[15:8], rx_data} > 4096)) begin
                            error <= 1;
                            queue_ack(8'h15);
                            state <= ST_SYNC;
                        end else state <= ST_DATA_H;
                    end
                    ST_DATA_H: begin
                        data_high <= rx_data;
                        state <= ST_DATA_L;
                    end
                    ST_DATA_L: begin
                        program_addr <= word_index[11:0];
                        program_wdata <= {data_high, rx_data};
                        program_we <= 1;
                        checksum <= checksum + {data_high, rx_data};
                        word_index <= word_index + 1'b1;
                        if (word_index + 1'b1 == word_count)
                            state <= ST_SUM_H;
                        else
                            state <= ST_DATA_H;
                    end
                    ST_SUM_H: begin
                        checksum_high <= rx_data;
                        state <= ST_SUM_L;
                    end
                    ST_SUM_L: begin
                        if ({checksum_high, rx_data} == checksum) begin
                            loaded <= 1;
                            error <= 0;
                            queue_ack(8'h06);
                        end else begin
                            loaded <= 0;
                            error <= 1;
                            queue_ack(8'h15);
                        end
                        state <= ST_SYNC;
                    end
                    default: state <= ST_SYNC;
                endcase
            end
        end
    end
endmodule

