`timescale 1ns/1ps

module tb_button_s1_controller;
    reg clk = 1'b0;
    reg por_rst = 1'b1;
    reg button_n = 1'b1;
    wire confirm_toggle;
    wire long_reset;
    wire input_valid;

    always #5 clk = ~clk;

    button_s1_controller #(
        .DEBOUNCE_CYCLES(3),
        .LONG_PRESS_CYCLES(8)
    ) dut (
        .clk(clk), .por_rst(por_rst), .button_n(button_n),
        .confirm_toggle(confirm_toggle), .long_reset(long_reset),
        .input_valid(input_valid)
    );

    task wait_cycles;
        input integer count;
        integer index;
        begin
            for (index = 0; index < count; index = index + 1)
                @(posedge clk);
            #1;
        end
    endtask

    initial begin
        wait_cycles(2);
        por_rst = 1'b0;
        wait_cycles(8);
        if (!input_valid || confirm_toggle || long_reset)
            $fatal(1, "released startup state is invalid");

        // Contact bounce followed by one short press must produce one token change.
        button_n = 1'b0; wait_cycles(1);
        button_n = 1'b1; wait_cycles(1);
        button_n = 1'b0; wait_cycles(6);
        if (confirm_toggle || long_reset) $fatal(1, "press generated an early event");
        button_n = 1'b1; wait_cycles(6);
        if (!confirm_toggle || long_reset) $fatal(1, "short press did not toggle exactly once");
        wait_cycles(8);
        if (!confirm_toggle) $fatal(1, "confirmation token was not retained");

        // A long press resets while held and must not create a confirmation on release.
        button_n = 1'b0; wait_cycles(16);
        if (!long_reset) $fatal(1, "long press did not assert reset");
        button_n = 1'b1; wait_cycles(6);
        if (long_reset) $fatal(1, "long reset did not release");
        if (!confirm_toggle) $fatal(1, "long press incorrectly changed confirmation token");

        // A later short press still works.
        button_n = 1'b0; wait_cycles(6);
        button_n = 1'b1; wait_cycles(6);
        if (confirm_toggle) $fatal(1, "second short press did not toggle token");

        $display("tb_button_s1_controller: TEST PASS");
        $finish;
    end
endmodule
