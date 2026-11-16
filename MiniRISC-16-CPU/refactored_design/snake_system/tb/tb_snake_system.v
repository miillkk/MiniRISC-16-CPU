`timescale 1ns/1ps

module tb_snake_system;
    localparam UART_CLKS = 8;
    reg clk=0, rst=1, uart_rx=1;
    reg [7:0] switches=0;
    wire uart_tx;
    wire [7:0] led;
    wire [15:0] display_low, display_high, display_control;
    wire [7:0] monitor_data;
    wire monitor_valid;
    reg [7:0] frame [0:67];
    integer byte_index=0, frame_count=0, timeout, i;

    always #5 clk=~clk;
    snake_soc #(
        .UART_CLKS_PER_BIT(UART_CLKS),
        .BASE_TICK_CYCLES(100000000)
    ) dut (
        .clk(clk), .rst(rst), .uart_rx(uart_rx), .uart_tx(uart_tx),
        .switches(switches), .led(led), .display_low(display_low),
        .display_high(display_high), .display_control(display_control)
    );
    uart_rx #(.CLKS_PER_BIT(UART_CLKS)) monitor (
        .clk(clk), .rst(rst), .rx(uart_tx), .data(monitor_data), .valid(monitor_valid)
    );

    always @(posedge clk) if (monitor_valid) begin
        if (byte_index==0 && monitor_data!=8'hA5) begin end
        else begin
            frame[byte_index] = monitor_data;
            if (byte_index==67) begin byte_index=0; frame_count=frame_count+1; end
            else byte_index=byte_index+1;
        end
    end

    task wait_frame;
        input integer target;
        begin
            timeout=0;
            while(frame_count<target && timeout<200000) begin @(posedge clk); timeout=timeout+1; end
            if(frame_count<target) $fatal(1,"frame timeout target=%0d",target);
            #1;
        end
    endtask
    task request_tick;
        begin
            force dut.u_snake_peripheral_subsystem.u_tick_timer.tick_pending = 1'b1;
            @(posedge clk); #1;
            release dut.u_snake_peripheral_subsystem.u_tick_timer.tick_pending;
        end
    endtask
    task send_uart;
        input [7:0] value;
        integer bit_no;
        begin
            uart_rx=0; repeat(UART_CLKS) @(posedge clk);
            for(bit_no=0;bit_no<8;bit_no=bit_no+1) begin
                uart_rx=value[bit_no]; repeat(UART_CLKS) @(posedge clk);
            end
            uart_rx=1; repeat(UART_CLKS) @(posedge clk);
        end
    endtask

    initial begin
        repeat(4) @(posedge clk); rst=0;
        wait_frame(1);
        if(frame[0]!=8'hA5 || frame[1]!=8'h11 || frame[2]!=0) $fatal(1,"initial frame header");
        if(frame[29]!=1 || frame[30]!=2 || frame[31]!=3) $fatal(1,"initial snake body");

        request_tick();
        wait_frame(2);
        if(dut.u_snake_peripheral_subsystem.u_scratchpad16.memory[0]!=28) $fatal(1,"right movement failed");
        if(frame[32]!=3) $fatal(1,"new head frame failed");

        dut.u_snake_peripheral_subsystem.u_scratchpad16.memory[4]=36;
        send_uart(8'h53);
        request_tick();
        wait_frame(3);
        if(dut.u_snake_peripheral_subsystem.u_scratchpad16.memory[0]!=36) $fatal(1,"down movement failed");
        if(dut.u_snake_peripheral_subsystem.u_scratchpad16.memory[2]!=4 ||
           dut.u_snake_peripheral_subsystem.u_scratchpad16.memory[3]!=1)
            $fatal(1,"food growth failed");

        send_uart(8'h57);
        request_tick();
        wait_frame(4);
        if(dut.u_snake_peripheral_subsystem.u_scratchpad16.memory[0]!=44)
            $fatal(1,"opposite direction was not ignored");

        dut.u_snake_peripheral_subsystem.u_scratchpad16.memory[0]=31;
        dut.u_snake_peripheral_subsystem.u_scratchpad16.memory[1]=1;
        request_tick();
        wait_frame(5);
        if(frame[1]!=8'h80 || led!=8'h80 || display_high!=16'hDEAD) $fatal(1,"game over failed");

        send_uart(8'h52);
        wait_frame(6);
        if(dut.u_snake_peripheral_subsystem.u_scratchpad16.memory[0]!=27) $fatal(1,"restart failed");
        $display("tb_snake_system: TEST PASS");
        $finish;
    end
endmodule
