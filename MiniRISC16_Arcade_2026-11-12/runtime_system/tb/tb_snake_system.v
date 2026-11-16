`timescale 1ns/1ps

module tb_snake_system;
    localparam UART_CLKS = 8;
    reg clk=0, rst=1, load_mode=0, uart_rx=1;
    reg [7:0] switches=0;
    wire uart_tx;
    wire [7:0] led;
    wire [15:0] display_low, display_high, display_control;
    wire [7:0] monitor_data;
    wire monitor_valid;
    reg [7:0] frame [0:139];
    integer byte_index=0, frame_count=0, timeout, i;

    always #5 clk=~clk;
    runtime_soc #(
        .UART_CLKS_PER_BIT(UART_CLKS),
        .BASE_TICK_CYCLES(100000000)
    ) dut (
        .clk(clk), .rst(rst), .load_mode(load_mode),
        .uart_rx(uart_rx), .uart_tx(uart_tx),
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
            if (byte_index==139) begin byte_index=0; frame_count=frame_count+1; end
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
            force dut.u_peripheral_subsystem.u_tick_timer.tick_pending = 1'b1;
            @(posedge clk); #1;
            release dut.u_peripheral_subsystem.u_tick_timer.tick_pending;
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
    task check_frame_protocol;
        input [7:0] expected_sequence;
        reg [7:0] checksum;
        integer check_index;
        begin
            if(frame[136]!=8'h03 || frame[137]!=8'h8C || frame[138]!=expected_sequence)
                $fatal(1,"protocol trailer mismatch version=%h length=%h sequence=%h",
                    frame[136],frame[137],frame[138]);
            checksum=0;
            for(check_index=0;check_index<139;check_index=check_index+1)
                checksum=checksum^frame[check_index];
            if(frame[139]!=checksum)
                $fatal(1,"protocol checksum mismatch expected=%h actual=%h",checksum,frame[139]);
        end
    endtask

    initial begin
        repeat(4) @(posedge clk); rst=0;
        wait_frame(1);
        if(frame[0]!=8'hA5 || frame[1]!=8'h11 || frame[2]!=0) $fatal(1,"initial frame header");
        if(frame[57]!=1 || frame[58]!=2 || frame[59]!=3) $fatal(1,"initial snake body");
        if(frame[23]!=8'hFF || frame[108]!=8'hFF) $fatal(1,"open-map obstacles missing");
        check_frame_protocol(0);

        request_tick();
        wait_frame(2);
        if(dut.u_peripheral_subsystem.u_scratchpad16.memory[0]!=56) $fatal(1,"right movement failed");
        if(frame[60]!=3) $fatal(1,"new head frame failed");
        check_frame_protocol(1);

        dut.u_peripheral_subsystem.u_scratchpad16.memory[4]=72;
        dut.u_peripheral_subsystem.u_scratchpad16.memory[3]=1;
        send_uart(8'h53);
        request_tick();
        wait_frame(3);
        if(dut.u_peripheral_subsystem.u_scratchpad16.memory[0]!=72) $fatal(1,"down movement failed");
        if(dut.u_peripheral_subsystem.u_scratchpad16.memory[2]!=4 ||
           dut.u_peripheral_subsystem.u_scratchpad16.memory[3]!=2)
            $fatal(1,"food growth failed");
        if(frame[133]!=1) $fatal(1,"two foods must advance to level 1");
        if(frame[44]!=0 || frame[45]!=0)
            $fatal(1,"score must not add dynamic walls");
        check_frame_protocol(2);

        dut.u_peripheral_subsystem.u_scratchpad16.memory[3]=3;
        dut.u_peripheral_subsystem.u_scratchpad16.memory[4]=88;
        send_uart(8'h57);
        request_tick();
        wait_frame(4);
        if(dut.u_peripheral_subsystem.u_scratchpad16.memory[0]!=88)
            $fatal(1,"opposite direction was not ignored");
        if(dut.u_peripheral_subsystem.u_scratchpad16.memory[3]!=4 || frame[133]!=2)
            $fatal(1,"four foods must advance to level 2");
        if(frame[106]!=0)
            $fatal(1,"score 4 must not add a dynamic wall");
        check_frame_protocol(3);

        dut.u_peripheral_subsystem.u_scratchpad16.memory[0]=86;
        dut.u_peripheral_subsystem.u_scratchpad16.memory[1]=2;
        dut.u_peripheral_subsystem.u_scratchpad16.memory[3]=5;
        dut.u_peripheral_subsystem.u_scratchpad16.memory[4]=102;
        request_tick();
        wait_frame(5);
        if(dut.u_peripheral_subsystem.u_scratchpad16.memory[0]!=102 ||
           dut.u_peripheral_subsystem.u_scratchpad16.memory[3]!=6 || frame[133]!=3)
            $fatal(1,"six foods must advance to level 3");
        check_frame_protocol(4);

        dut.u_peripheral_subsystem.u_scratchpad16.memory[0]=31;
        dut.u_peripheral_subsystem.u_scratchpad16.memory[1]=1;
        request_tick();
        wait_frame(6);
        if(frame[1]!=8'h80 || led!=8'h80 || display_high!=16'hDEAD) $fatal(1,"game over failed");

        send_uart(8'h52);
        wait_frame(7);
        if(dut.u_peripheral_subsystem.u_scratchpad16.memory[0]!=55) $fatal(1,"restart failed");
        check_frame_protocol(0);

        switches=8'h08;
        repeat(4) @(posedge clk);
        send_uart(8'h52);
        wait_frame(8);
        if(frame[134]!=8'h08 || frame[23]!=8'hFF || frame[94]!=8'hFF || frame[108]!=0)
            $fatal(1,"maze map selection failed");
        check_frame_protocol(0);

        switches=8'h10;
        repeat(4) @(posedge clk);
        send_uart(8'h52);
        wait_frame(9);
        if(frame[134]!=8'h10 || frame[22]!=8'hFF || frame[113]!=8'hFF)
            $fatal(1,"hard map selection failed");
        check_frame_protocol(0);

        load_mode=1;
        repeat(3) @(posedge clk); #1;
        if(display_high!=16'h10AD || display_control[0]!=1'b1)
            $fatal(1,"loader display must show 10AD with display enabled");
        $display("tb_snake_system: TEST PASS");
        $finish;
    end
endmodule
