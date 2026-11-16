`timescale 1ns/1ps

module tb_calculator_system;
    reg clk = 1'b0;
    reg rst = 1'b1;
    reg [7:0] switches = 8'h00;
    reg confirm_toggle = 1'b0;
    reg button_valid = 1'b1;
    wire [7:0] led;
    wire [15:0] display_low;
    wire [15:0] display_high;
    wire [15:0] display_control;
    integer before_high, before_low, before_led;

    always #5 clk = ~clk;

    calculator_soc #(
        .INIT_FILE("calculator.mem")
    ) dut (
        .clk(clk), .rst(rst), .switches(switches),
        .confirm_toggle(confirm_toggle), .button_valid(button_valid), .led(led),
        .display_low(display_low), .display_high(display_high),
        .display_control(display_control)
    );

    task wait_display;
        input [15:0] expected_high;
        input [15:0] expected_low;
        integer count;
        begin : wait_block
            for (count = 0; count < 10000; count = count + 1) begin
                @(posedge clk); #1;
                if (display_high === expected_high && display_low === expected_low)
                    disable wait_block;
            end
            $display("TEST FAIL: timeout waiting for %h%h, got %h%h",
                     expected_high, expected_low, display_high, display_low);
            $finish;
        end
    endtask

    task toggle_confirm;
        begin
            confirm_toggle = ~confirm_toggle;
        end
    endtask

    task run_case;
        input [7:0] operand_a;
        input [7:0] operand_b;
        input [2:0] operation;
        input [15:0] expected_high;
        input [15:0] expected_low;
        input [7:0] expected_led;
        reg [7:0] changed_data;
        begin
            switches = operand_a;
            wait_display(16'hA000, {8'h00,operand_a});
            toggle_confirm();
            wait_display(16'hB000, {8'h00,operand_a});

            switches = operand_b;
            wait_display(16'hB000, {8'h00,operand_b});
            toggle_confirm();
            wait_display(16'hC000, {8'h00,operand_b});

            switches = {5'h00,operation};
            wait_display(16'hC000, {13'h0000,operation});
            toggle_confirm();
            wait_display(expected_high, expected_low);
            if (led !== expected_led) begin
                $display("TEST FAIL: operation %0d LED expected %h got %h", operation, expected_led, led);
                $finish;
            end
            if (display_control !== 16'h0001) begin
                $display("TEST FAIL: display is not enabled");
                $finish;
            end

            before_high = display_high; before_low = display_low; before_led = led;
            changed_data = operand_a ^ 8'h03;
            switches = changed_data;
            repeat (100) @(posedge clk);
            if (display_high !== before_high || display_low !== before_low || led !== before_led) begin
                $display("TEST FAIL: result changed without confirmation");
                $finish;
            end

            toggle_confirm();
            wait_display(16'hA000, {8'h00,changed_data});
            if (led !== 8'h00) begin
                $display("TEST FAIL: LED did not clear for new transaction");
                $finish;
            end
        end
    endtask

    initial begin
        repeat (3) @(posedge clk);
        rst = 1'b0;
        run_case(8'h2D,8'h17,3'd0,16'h2D17,16'h0044,8'h00);
        run_case(8'h14,8'h23,3'd1,16'h1423,16'hFFF1,8'h11);
        run_case(8'h5A,8'h0F,3'd2,16'h5A0F,16'h000A,8'h02);
        run_case(8'h5A,8'h0F,3'd3,16'h5A0F,16'h005F,8'h03);
        run_case(8'h5A,8'h0F,3'd4,16'h5A0F,16'h0055,8'h04);
        run_case(8'hFF,8'hFF,3'd5,16'hFFFF,16'hFE01,8'h15);
        run_case(8'hFF,8'h01,3'd6,16'hFF01,16'hFF00,8'h06);
        run_case(8'h33,8'h33,3'd7,16'h3333,16'h0001,8'h2F);
        run_case(8'h23,8'h00,3'd6,16'hE001,16'h2300,8'h86);

        // Reset from an active input state must restart the protocol.
        rst = 1'b1; repeat (3) @(posedge clk); rst = 1'b0;
        switches = 8'hA5;
        wait_display(16'hA000,16'h00A5);
        $display("tb_calculator_system: TEST PASS");
        $finish;
    end
endmodule
