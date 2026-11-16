`timescale 1ns/1ps

module tb_system;
    reg clk;
    reg resetn;
    wire [7:0] gpio;
    reg [7:0] external_value;
    integer errors;
    integer cycles;
    integer jz_taken_count;
    integer jz_not_taken_count;
    reg [15:0] opcode_coverage;
    reg expect_valid;
    reg completed;
    reg [7:0] exp_pc;
    reg exp_z;
    reg [15:0] exp_r0;
    reg [15:0] exp_r1;
    reg [15:0] exp_r2;
    reg [15:0] exp_r3;
    reg [7:0] exp_gpio_out;
    reg [7:0] exp_gpio_dir;
    reg [15:0] model_rd;
    reg [15:0] model_rs;
    reg [15:0] model_result;
    reg [3:0] model_opcode;
    reg [1:0] model_rd_addr;
    reg [1:0] model_rs_addr;
    reg [7:0] model_imm8;
    wire trace_clk = clk;
    wire trace_rst = dut.rst;
    wire [7:0] trace_pc = dut.mem_addr;
    wire [15:0] trace_instruction = dut.instruction;
    wire [3:0] trace_opcode = dut.instruction[15:12];
    wire trace_z = dut.u_cpu.u_datapath.z_flag;
    wire trace_reg_write = dut.u_cpu.reg_write & ~dut.rst;
    wire trace_z_write = dut.u_cpu.z_write & ~dut.rst;
    wire trace_branch_z = dut.u_cpu.branch_z;
    wire trace_jump = dut.u_cpu.jump;
    wire [7:0] trace_pc_next = dut.u_cpu.u_datapath.pc_next;
    wire [15:0] trace_rd_data = dut.u_cpu.u_datapath.rd_data;
    wire [15:0] trace_rs_data = dut.u_cpu.u_datapath.rs_data;
    wire [15:0] trace_alu_result = dut.u_cpu.u_datapath.alu_result;
    wire [15:0] trace_writeback_data = dut.u_cpu.u_datapath.writeback_data;
    wire [15:0] trace_r0 = dut.u_cpu.u_datapath.u_register_file.registers[0];
    wire [15:0] trace_r1 = dut.u_cpu.u_datapath.u_register_file.registers[1];
    wire [15:0] trace_r2 = dut.u_cpu.u_datapath.u_register_file.registers[2];
    wire [15:0] trace_r3 = dut.u_cpu.u_datapath.u_register_file.registers[3];
    wire [7:0] trace_io_addr = dut.io_addr;
    wire [15:0] trace_io_wdata = dut.io_wdata;
    wire [15:0] trace_io_rdata = dut.io_rdata;
    wire trace_io_re = dut.io_re;
    wire trace_io_we = dut.io_we;
    wire [7:0] trace_gpio_out = dut.u_gpio8.gpio_out;
    wire [7:0] trace_gpio_dir = dut.u_gpio8.gpio_dir;
    wire [7:0] trace_gpio_in = dut.u_gpio8.input_sync_2;
    wire [7:0] trace_gpio_pins = gpio;
    genvar bit_index;

    system_top #(
        .INIT_FILE ("system_demo.mem")
    ) dut (
        .clk    (clk),
        .resetn (resetn),
        .gpio   (gpio)
    );

    generate
        for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin : g_external_gpio
            assign gpio[bit_index] = dut.gpio_oe[bit_index] ? 1'bz : external_value[bit_index];
        end
    endgenerate

    always #5 clk = ~clk;

`ifdef IVERILOG
    initial begin
        $dumpfile("system.vcd");
        $dumpvars(0, tb_system);
    end
`endif

    task model_write_register;
        input [1:0] address;
        input [15:0] data;
        begin
            case (address)
                2'd0: exp_r0 = data;
                2'd1: exp_r1 = data;
                2'd2: exp_r2 = data;
                2'd3: exp_r3 = data;
            endcase
        end
    endtask

    always @(negedge clk) begin
        if (!dut.rst && !completed) begin
            exp_pc       = dut.u_cpu.u_datapath.pc + 8'h01;
            exp_z        = dut.u_cpu.u_datapath.z_flag;
            exp_r0       = dut.u_cpu.u_datapath.u_register_file.registers[0];
            exp_r1       = dut.u_cpu.u_datapath.u_register_file.registers[1];
            exp_r2       = dut.u_cpu.u_datapath.u_register_file.registers[2];
            exp_r3       = dut.u_cpu.u_datapath.u_register_file.registers[3];
            exp_gpio_out = dut.u_gpio8.gpio_out;
            exp_gpio_dir = dut.u_gpio8.gpio_dir;
            model_opcode = dut.instruction[15:12];
            model_rd_addr = dut.instruction[11:10];
            model_rs_addr = dut.instruction[9:8];
            model_imm8 = dut.instruction[7:0];

            case (model_rd_addr)
                2'd0: model_rd = exp_r0;
                2'd1: model_rd = exp_r1;
                2'd2: model_rd = exp_r2;
                default: model_rd = exp_r3;
            endcase
            case (model_rs_addr)
                2'd0: model_rs = exp_r0;
                2'd1: model_rs = exp_r1;
                2'd2: model_rs = exp_r2;
                default: model_rs = exp_r3;
            endcase
            model_result = 16'h0000;
            opcode_coverage[model_opcode] = 1'b1;

            case (model_opcode)
                4'h0: model_write_register(model_rd_addr, {8'h00, model_imm8});
                4'h1: model_write_register(model_rd_addr, model_rs);
                4'h2: model_write_register(model_rd_addr, model_rd + {8'h00, model_imm8});
                4'h3: model_write_register(model_rd_addr, model_rd + model_rs);
                4'h4: model_write_register(model_rd_addr, model_rd ^ model_rs);
                4'h5: model_write_register(model_rd_addr, model_rd - model_rs);
                4'h6: begin
                    model_result = model_rd - model_rs;
                    exp_z = (model_result == 16'h0000);
                end
                4'h7: model_write_register(model_rd_addr, model_rd & model_rs);
                4'h8: begin
                    if (exp_z) begin
                        exp_pc = model_imm8;
                        jz_taken_count = jz_taken_count + 1;
                    end else begin
                        jz_not_taken_count = jz_not_taken_count + 1;
                    end
                end
                4'h9: model_write_register(model_rd_addr, model_rd | model_rs);
                4'hA: exp_pc = model_imm8;
                4'hB: model_write_register(model_rd_addr, dut.io_rdata);
                4'hC: begin
                    if (model_imm8 == 8'h10)
                        exp_gpio_out = model_rs[7:0];
                    else if (model_imm8 == 8'h12)
                        exp_gpio_dir = model_rs[7:0];
                end
                default: begin end
            endcase
            expect_valid = 1'b1;
        end else begin
            expect_valid = 1'b0;
        end
    end

    always @(posedge clk) begin
        #1;
        if (expect_valid && !dut.rst) begin
            if (dut.u_cpu.u_datapath.pc !== exp_pc ||
                dut.u_cpu.u_datapath.z_flag !== exp_z ||
                dut.u_cpu.u_datapath.u_register_file.registers[0] !== exp_r0 ||
                dut.u_cpu.u_datapath.u_register_file.registers[1] !== exp_r1 ||
                dut.u_cpu.u_datapath.u_register_file.registers[2] !== exp_r2 ||
                dut.u_cpu.u_datapath.u_register_file.registers[3] !== exp_r3 ||
                dut.u_gpio8.gpio_out !== exp_gpio_out ||
                dut.u_gpio8.gpio_dir !== exp_gpio_dir) begin
                $display("ERROR tb_system: reference mismatch after opcode=%h pc actual/expected=%h/%h",
                         model_opcode, dut.u_cpu.u_datapath.pc, exp_pc);
                errors = errors + 1;
            end

            if ((^{dut.u_cpu.u_datapath.pc, dut.u_cpu.u_datapath.z_flag,
                   dut.u_cpu.u_datapath.u_register_file.registers[0],
                   dut.u_cpu.u_datapath.u_register_file.registers[1],
                   dut.u_cpu.u_datapath.u_register_file.registers[2],
                   dut.u_cpu.u_datapath.u_register_file.registers[3],
                   dut.instruction, dut.io_addr, dut.io_wdata, dut.io_rdata,
                   dut.io_re, dut.io_we, dut.u_gpio8.gpio_out,
                   dut.u_gpio8.gpio_dir, dut.u_gpio8.input_sync_2}) === 1'bx) begin
                $display("ERROR tb_system: X/Z detected in critical state or control at PC=%h",
                         dut.u_cpu.u_datapath.pc);
                errors = errors + 1;
            end

            if (dut.u_cpu.u_datapath.pc == 8'h21)
                completed = 1'b1;
        end
    end

    initial begin
        clk = 1'b0;
        resetn = 1'b0;
        external_value = 8'hA5;
        errors = 0;
        cycles = 0;
        jz_taken_count = 0;
        jz_not_taken_count = 0;
        opcode_coverage = 16'h0000;
        expect_valid = 1'b0;
        completed = 1'b0;

        repeat (3) @(posedge clk);
        #1;
        if (dut.rst !== 1'b1 || dut.mem_addr !== 8'h00 || dut.io_we !== 1'b0) begin
            $display("ERROR tb_system: reset state or write suppression incorrect");
            errors = errors + 1;
        end

        @(negedge clk);
        resetn = 1'b1;

        for (cycles = 0; cycles < 80 && !completed; cycles = cycles + 1)
            @(posedge clk);
        #2;

        if (!completed) begin
            $display("ERROR tb_system: timeout after %0d cycles", cycles);
            errors = errors + 1;
        end
        if (opcode_coverage !== 16'hFFFF) begin
            $display("ERROR tb_system: opcode coverage expected=FFFF actual=%h", opcode_coverage);
            errors = errors + 1;
        end
        if (jz_taken_count < 2 || jz_not_taken_count < 1) begin
            $display("ERROR tb_system: JZ coverage taken=%0d not_taken=%0d",
                     jz_taken_count, jz_not_taken_count);
            errors = errors + 1;
        end
        if (dut.mem_addr !== 8'h21 || dut.u_cpu.u_datapath.z_flag !== 1'b1 ||
            dut.u_cpu.u_datapath.u_register_file.registers[0] !== 16'h00A5 ||
            dut.u_cpu.u_datapath.u_register_file.registers[1] !== 16'h00A5 ||
            dut.u_cpu.u_datapath.u_register_file.registers[2] !== 16'h00A5 ||
            dut.u_cpu.u_datapath.u_register_file.registers[3] !== 16'h00A5 ||
            dut.u_gpio8.gpio_out !== 8'hA5 || dut.u_gpio8.gpio_dir !== 8'h0F ||
            dut.u_gpio8.input_sync_2 !== 8'hA5) begin
            $display("ERROR tb_system: final state mismatch PC=%h Z=%b R=%h,%h,%h,%h OUT=%h DIR=%h IN=%h",
                     dut.mem_addr, dut.u_cpu.u_datapath.z_flag,
                     dut.u_cpu.u_datapath.u_register_file.registers[0],
                     dut.u_cpu.u_datapath.u_register_file.registers[1],
                     dut.u_cpu.u_datapath.u_register_file.registers[2],
                     dut.u_cpu.u_datapath.u_register_file.registers[3],
                     dut.u_gpio8.gpio_out, dut.u_gpio8.gpio_dir,
                     dut.u_gpio8.input_sync_2);
            errors = errors + 1;
        end

        if (errors == 0)
            $display("tb_system: TEST PASS cycles=%0d opcode_coverage=%h JZ_taken=%0d JZ_not_taken=%0d",
                     cycles, opcode_coverage, jz_taken_count, jz_not_taken_count);
        else
            $display("tb_system: TEST FAIL errors=%0d", errors);
        $finish;
    end
endmodule
