`timescale 1ns/1ps

module tb_datapath;
    reg clk;
    reg rst;
    reg [15:0] io_rdata;
    reg [1:0] rd_addr;
    reg [1:0] rs_addr;
    reg [7:0] imm8;
    reg [2:0] alu_op;
    reg alu_src;
    reg reg_write;
    reg flags_write;
    reg branch_z;
    reg jump;
    reg wb_sel;
    reg control_io_re;
    reg control_io_we;
    wire [7:0] mem_addr;
    wire [7:0] io_addr;
    wire [15:0] io_wdata;
    wire io_re;
    wire io_we;
    reg [7:0] expected_pc;
    integer errors;

    datapath dut (
        .clk(clk), .rst(rst), .io_rdata(io_rdata),
        .rd_addr(rd_addr), .rs_addr(rs_addr), .imm8(imm8),
        .alu_op(alu_op), .alu_src(alu_src), .reg_write(reg_write),
        .flags_write(flags_write), .branch_z(branch_z), .jump(jump),
        .wb_sel(wb_sel), .control_io_re(control_io_re),
        .control_io_we(control_io_we), .mem_addr(mem_addr),
        .io_addr(io_addr), .io_wdata(io_wdata), .io_re(io_re), .io_we(io_we)
    );

    always #5 clk = ~clk;

    task step;
        input [1:0] test_rd;
        input [1:0] test_rs;
        input [7:0] test_imm;
        input [2:0] test_alu_op;
        input test_alu_src;
        input test_reg_write;
        input test_flags_write;
        input test_branch_z;
        input test_jump;
        input test_wb_sel;
        input test_io_re;
        input test_io_we;
        begin
            @(negedge clk);
            rd_addr       = test_rd;
            rs_addr       = test_rs;
            imm8          = test_imm;
            alu_op        = test_alu_op;
            alu_src       = test_alu_src;
            reg_write     = test_reg_write;
            flags_write   = test_flags_write;
            branch_z      = test_branch_z;
            jump          = test_jump;
            wb_sel        = test_wb_sel;
            control_io_re = test_io_re;
            control_io_we = test_io_we;
            @(posedge clk);
            #1;
        end
    endtask

    task check_flags;
        input [3:0] expected;
        begin
            if ({dut.z_flag, dut.n_flag, dut.c_flag, dut.v_flag} !== expected) begin
                $display("ERROR tb_datapath: expected ZNCV=%b actual=%b",
                         expected, {dut.z_flag, dut.n_flag, dut.c_flag, dut.v_flag});
                errors = errors + 1;
            end
        end
    endtask

    task check_register;
        input [1:0] address;
        input [15:0] expected;
        begin
            if (dut.u_register_file.registers[address] !== expected) begin
                $display("ERROR tb_datapath: R%0d expected=%h actual=%h",
                         address, expected, dut.u_register_file.registers[address]);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        io_rdata = 16'h0000;
        rd_addr = 2'b00;
        rs_addr = 2'b00;
        imm8 = 8'h00;
        alu_op = 3'b000;
        alu_src = 1'b0;
        reg_write = 1'b0;
        flags_write = 1'b0;
        branch_z = 1'b0;
        jump = 1'b0;
        wb_sel = 1'b0;
        control_io_re = 1'b1;
        control_io_we = 1'b1;
        errors = 0;

        repeat (2) @(posedge clk);
        #1;
        if (mem_addr !== 8'h00 || io_re !== 1'b0 || io_we !== 1'b0) begin
            $display("ERROR tb_datapath: reset outputs incorrect");
            errors = errors + 1;
        end
        check_flags(4'b0000);
        check_register(2'b00, 16'h0000);
        check_register(2'b01, 16'h0000);
        check_register(2'b10, 16'h0000);
        check_register(2'b11, 16'h0000);

        rst = 1'b0;
        io_rdata = 16'hFFFF;
        step(2'b00,2'b00,8'h11,3'b000,1'b0,1'b1,1'b0,1'b0,1'b0,1'b1,1'b1,1'b0);
        check_register(2'b00, 16'hFFFF);
        check_flags(4'b0000);
        if (io_addr !== 8'h11 || io_re !== 1'b1) begin
            $display("ERROR tb_datapath: I/O read interface incorrect");
            errors = errors + 1;
        end

        step(2'b00,2'b00,8'h01,3'b001,1'b1,1'b1,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0);
        check_register(2'b00, 16'h0000);
        check_flags(4'b1010);

        io_rdata = 16'h7FFF;
        step(2'b00,2'b00,8'h11,3'b000,1'b0,1'b1,1'b0,1'b0,1'b0,1'b1,1'b1,1'b0);
        step(2'b00,2'b00,8'h01,3'b001,1'b1,1'b1,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0);
        check_register(2'b00, 16'h8000);
        check_flags(4'b0101);

        step(2'b01,2'b00,8'hA5,3'b000,1'b1,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0);
        step(2'b00,2'b01,8'h00,3'b101,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0);
        check_flags(4'b0101);

        io_rdata = 16'h0000;
        step(2'b00,2'b00,8'h11,3'b000,1'b0,1'b1,1'b0,1'b0,1'b0,1'b1,1'b1,1'b0);
        io_rdata = 16'h0001;
        step(2'b01,2'b00,8'h11,3'b000,1'b0,1'b1,1'b0,1'b0,1'b0,1'b1,1'b1,1'b0);
        step(2'b00,2'b01,8'h00,3'b010,1'b0,1'b1,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0);
        check_register(2'b00, 16'hFFFF);
        check_flags(4'b0100);

        io_rdata = 16'h8000;
        step(2'b00,2'b00,8'h11,3'b000,1'b0,1'b1,1'b0,1'b0,1'b0,1'b1,1'b1,1'b0);
        step(2'b00,2'b01,8'h00,3'b010,1'b0,1'b1,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0);
        check_register(2'b00, 16'h7FFF);
        check_flags(4'b0011);

        io_rdata = 16'h1234;
        step(2'b10,2'b00,8'h11,3'b000,1'b0,1'b1,1'b0,1'b0,1'b0,1'b1,1'b1,1'b0);
        step(2'b11,2'b00,8'h11,3'b000,1'b0,1'b1,1'b0,1'b0,1'b0,1'b1,1'b1,1'b0);
        step(2'b10,2'b11,8'h00,3'b010,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0);
        check_register(2'b10, 16'h1234);
        check_flags(4'b1010);

        step(2'b10,2'b11,8'h00,3'b011,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0);
        check_flags(4'b1010);
        step(2'b00,2'b00,8'h40,3'b000,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0);
        if (mem_addr !== 8'h40) begin
            $display("ERROR tb_datapath: JZ did not use stored Z");
            errors = errors + 1;
        end

        io_rdata = 16'h0000;
        step(2'b00,2'b00,8'h11,3'b000,1'b0,1'b1,1'b0,1'b0,1'b0,1'b1,1'b1,1'b0);
        io_rdata = 16'h0001;
        step(2'b01,2'b00,8'h11,3'b000,1'b0,1'b1,1'b0,1'b0,1'b0,1'b1,1'b1,1'b0);
        step(2'b00,2'b01,8'h00,3'b010,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0);
        expected_pc = mem_addr + 8'h01;
        step(2'b00,2'b00,8'h50,3'b000,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0);
        if (mem_addr !== expected_pc) begin
            $display("ERROR tb_datapath: JZ incorrectly taken when Z=0");
            errors = errors + 1;
        end

        step(2'b00,2'b01,8'h12,3'b000,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1);
        if (io_addr !== 8'h12 || io_wdata !== 16'h0001 || io_we !== 1'b1) begin
            $display("ERROR tb_datapath: I/O write interface incorrect");
            errors = errors + 1;
        end

        step(2'b00,2'b00,8'hAA,3'b000,1'b0,1'b0,1'b0,1'b1,1'b1,1'b0,1'b0,1'b0);
        if (mem_addr !== 8'hAA) begin
            $display("ERROR tb_datapath: JUMP did not select target");
            errors = errors + 1;
        end

        if ((^{mem_addr, dut.z_flag, dut.n_flag, dut.c_flag, dut.v_flag,
               dut.u_register_file.registers[0], dut.u_register_file.registers[1],
               dut.u_register_file.registers[2], dut.u_register_file.registers[3]}) === 1'bx) begin
            $display("ERROR tb_datapath: unknown state detected");
            errors = errors + 1;
        end

        if (errors == 0) $display("tb_datapath: TEST PASS");
        else $display("tb_datapath: TEST FAIL errors=%0d", errors);
        $finish;
    end
endmodule
