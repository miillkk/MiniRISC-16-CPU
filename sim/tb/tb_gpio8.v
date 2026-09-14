`timescale 1ns/1ps

module tb_gpio8;
    reg clk;
    reg rst;
    reg [7:0] io_addr;
    reg [15:0] io_wdata;
    reg io_re;
    reg io_we;
    wire [15:0] io_rdata;
    wire [7:0] gpio_i;
    wire [7:0] gpio_o;
    wire [7:0] gpio_oe;
    wire [7:0] gpio_pins;
    reg [7:0] external_data;
    reg [7:0] external_enable;
    integer errors;
    genvar bit_index;

    gpio8 dut (
        .clk      (clk),
        .rst      (rst),
        .io_addr  (io_addr),
        .io_wdata (io_wdata),
        .io_re    (io_re),
        .io_we    (io_we),
        .io_rdata (io_rdata),
        .gpio_i   (gpio_i),
        .gpio_o   (gpio_o),
        .gpio_oe  (gpio_oe)
    );

    generate
        for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin : g_pin_model
            assign gpio_pins[bit_index] = gpio_oe[bit_index] ? gpio_o[bit_index] : 1'bz;
            assign gpio_pins[bit_index] = external_enable[bit_index] ? external_data[bit_index] : 1'bz;
        end
    endgenerate
    assign gpio_i = gpio_pins;

    always #5 clk = ~clk;

    task write_port;
        input [7:0] address;
        input [15:0] data;
        begin
            @(negedge clk);
            io_addr = address;
            io_wdata = data;
            io_we = 1'b1;
            @(posedge clk); #1;
            io_we = 1'b0;
        end
    endtask

    task read_port;
        input [7:0] address;
        input [15:0] expected;
        begin
            io_addr = address;
            io_re = 1'b1;
            #1;
            if (io_rdata !== expected) begin
                $display("ERROR tb_gpio8: read addr=%h expected=%h actual=%h", address, expected, io_rdata);
                errors = errors + 1;
            end
            io_re = 1'b0;
            #1;
            if (io_rdata !== 16'h0000) begin
                $display("ERROR tb_gpio8: read data not zero when io_re=0");
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        io_addr = 8'h00;
        io_wdata = 16'h0000;
        io_re = 1'b0;
        io_we = 1'b0;
        external_data = 8'hA0;
        external_enable = 8'hF0;
        errors = 0;

        repeat (2) @(posedge clk);
        #1;
        if (gpio_o !== 8'h00 || gpio_oe !== 8'h00 ||
            dut.input_sync_1 !== 8'h00 || dut.input_sync_2 !== 8'h00) begin
            $display("ERROR tb_gpio8: reset state incorrect");
            errors = errors + 1;
        end
        @(negedge clk);
        rst = 1'b0;

        write_port(8'h10, 16'h12A5);
        write_port(8'h12, 16'h340F);
        read_port(8'h10, 16'h00A5);
        read_port(8'h12, 16'h000F);

        if (gpio_oe !== 8'h0F || gpio_o !== 8'hA5) begin
            $display("ERROR tb_gpio8: output/direction registers incorrect");
            errors = errors + 1;
        end
        #1;
        if (gpio_pins !== 8'hA5) begin
            $display("ERROR tb_gpio8: mixed-direction pin value expected=A5 actual=%h", gpio_pins);
            errors = errors + 1;
        end

        repeat (3) @(posedge clk);
        #1;
        read_port(8'h11, 16'h00A5);

        write_port(8'h11, 16'h0055);
        write_port(8'h77, 16'h00FF);
        read_port(8'h10, 16'h00A5);
        read_port(8'h12, 16'h000F);
        read_port(8'h77, 16'h0000);

        external_enable = 8'h00;
        #1;
        if (gpio_pins[7:4] !== 4'hz || gpio_pins[3:0] !== 4'h5) begin
            $display("ERROR tb_gpio8: high-Z/output split incorrect pins=%h", gpio_pins);
            errors = errors + 1;
        end

        rst = 1'b1;
        @(posedge clk); #1;
        if (gpio_o !== 8'h00 || gpio_oe !== 8'h00 ||
            dut.input_sync_1 !== 8'h00 || dut.input_sync_2 !== 8'h00) begin
            $display("ERROR tb_gpio8: synchronous reset failed");
            errors = errors + 1;
        end

        if (errors == 0)
            $display("tb_gpio8: TEST PASS");
        else
            $display("tb_gpio8: TEST FAIL errors=%0d", errors);
        $finish;
    end
endmodule
