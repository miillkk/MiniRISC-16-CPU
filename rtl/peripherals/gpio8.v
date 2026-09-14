`timescale 1ns/1ps

module gpio8 (
    input  wire        clk,
    input  wire        rst,
    input  wire [7:0]  io_addr,
    input  wire [15:0] io_wdata,
    input  wire        io_re,
    input  wire        io_we,
    output reg  [15:0] io_rdata,
    input  wire [7:0]  gpio_i,
    output wire [7:0]  gpio_o,
    output wire [7:0]  gpio_oe
);
    localparam GPIO_OUT_ADDR = 8'h10;
    localparam GPIO_IN_ADDR  = 8'h11;
    localparam GPIO_DIR_ADDR = 8'h12;

    reg [7:0] gpio_out;
    reg [7:0] gpio_dir;
    reg [7:0] input_sync_1;
    reg [7:0] input_sync_2;

    assign gpio_o  = gpio_out;
    assign gpio_oe = gpio_dir;

    always @(posedge clk) begin
        if (rst) begin
            gpio_out    <= 8'h00;
            gpio_dir    <= 8'h00;
            input_sync_1 <= 8'h00;
            input_sync_2 <= 8'h00;
        end else begin
            input_sync_1 <= gpio_i;
            input_sync_2 <= input_sync_1;

            if (io_we) begin
                case (io_addr)
                    GPIO_OUT_ADDR: gpio_out <= io_wdata[7:0];
                    GPIO_DIR_ADDR: gpio_dir <= io_wdata[7:0];
                    default: begin end
                endcase
            end
        end
    end

    always @* begin
        io_rdata = 16'h0000;
        if (io_re) begin
            case (io_addr)
                GPIO_OUT_ADDR: io_rdata = {8'h00, gpio_out};
                GPIO_IN_ADDR:  io_rdata = {8'h00, input_sync_2};
                GPIO_DIR_ADDR: io_rdata = {8'h00, gpio_dir};
                default:       io_rdata = 16'h0000;
            endcase
        end
    end
endmodule
