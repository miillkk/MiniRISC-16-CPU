`timescale 1ns/1ps

module tb_cpu_core;
    reg clk;
    reg rst;
    wire [7:0] mem_addr;
    wire [15:0] instruction;
    wire [7:0] io_addr;
    wire [15:0] io_wdata;
    wire [15:0] io_rdata;
    wire io_re;
    wire io_we;

    reg [15:0] program [0:255];
    reg [15:0] opcode_coverage;
    reg [7:0] executing_pc;
    reg [15:0] executing_instruction;
    integer index;
    integer commits;
    integer io_write_count;
    integer errors;

    assign instruction = program[mem_addr];
    assign io_rdata = (io_re && io_addr == 8'h11) ? 16'h00A5 : 16'h0000;

    cpu_core dut (
        .clk(clk), .rst(rst), .instruction(instruction), .io_rdata(io_rdata),
        .mem_addr(mem_addr), .io_addr(io_addr), .io_wdata(io_wdata),
        .io_re(io_re), .io_we(io_we)
    );

    always #5 clk = ~clk;

    initial begin
        for (index = 0; index < 256; index = index + 1)
            program[index] = 16'hF000;
        $readmemh("system_demo.mem", program);

        clk = 1'b0;
        rst = 1'b1;
        opcode_coverage = 16'h0000;
        executing_pc = 8'h00;
        executing_instruction = 16'h0000;
        commits = 0;
        io_write_count = 0;
        errors = 0;

        repeat (2) @(posedge clk);
        #1;
        if (mem_addr !== 8'h00 || io_re !== 1'b0 || io_we !== 1'b0) begin
            $display("ERROR tb_cpu_core: reset interface state incorrect");
            errors = errors + 1;
        end
        if ({dut.u_datapath.z_flag, dut.u_datapath.n_flag,
             dut.u_datapath.c_flag, dut.u_datapath.v_flag} !== 4'b0000) begin
            $display("ERROR tb_cpu_core: flags not cleared by reset");
            errors = errors + 1;
        end

        @(negedge clk);
        rst = 1'b0;

        while (commits < 60 && mem_addr != 8'h21) begin
            #1;
            executing_pc = mem_addr;
            executing_instruction = instruction;
            opcode_coverage[executing_instruction[15:12]] = 1'b1;

            if (executing_instruction[15:12] == 4'hC) begin
                if (io_we !== 1'b1) begin
                    $display("ERROR tb_cpu_core: OUP missing io_we at PC=%h", executing_pc);
                    errors = errors + 1;
                end
                case (executing_pc)
                    8'h12, 8'h1C: begin
                        if (io_addr !== 8'h10 || io_wdata !== 16'h00A5) begin
                            $display("ERROR tb_cpu_core: GPIO_OUT transaction mismatch at PC=%h", executing_pc);
                            errors = errors + 1;
                        end
                    end
                    8'h14: begin
                        if (io_addr !== 8'h12 || io_wdata !== 16'h000F) begin
                            $display("ERROR tb_cpu_core: GPIO_DIR transaction mismatch");
                            errors = errors + 1;
                        end
                    end
                    default: begin
                        $display("ERROR tb_cpu_core: unexpected OUP at PC=%h", executing_pc);
                        errors = errors + 1;
                    end
                endcase
                io_write_count = io_write_count + 1;
            end

            if (executing_instruction[15:12] == 4'hB) begin
                if (io_re !== 1'b1 || io_addr !== 8'h11 || io_rdata !== 16'h00A5) begin
                    $display("ERROR tb_cpu_core: INP transaction mismatch");
                    errors = errors + 1;
                end
            end

            @(posedge clk);
            #1;
            commits = commits + 1;
            @(negedge clk);
        end

        if (mem_addr !== 8'h21) begin
            $display("ERROR tb_cpu_core: completion PC not reached, pc=%h", mem_addr);
            errors = errors + 1;
        end
        if (commits !== 29) begin
            $display("ERROR tb_cpu_core: expected 29 commits, actual=%0d", commits);
            errors = errors + 1;
        end
        if (opcode_coverage !== 16'hFFFF) begin
            $display("ERROR tb_cpu_core: opcode coverage expected=ffff actual=%h", opcode_coverage);
            errors = errors + 1;
        end
        if (io_write_count !== 3) begin
            $display("ERROR tb_cpu_core: expected 3 I/O writes, actual=%0d", io_write_count);
            errors = errors + 1;
        end
        if (dut.u_datapath.u_register_file.registers[0] !== 16'h00A5 ||
            dut.u_datapath.u_register_file.registers[1] !== 16'h00A5 ||
            dut.u_datapath.u_register_file.registers[2] !== 16'h00A5 ||
            dut.u_datapath.u_register_file.registers[3] !== 16'h00A5) begin
            $display("ERROR tb_cpu_core: final register state mismatch");
            errors = errors + 1;
        end
        if ({dut.u_datapath.z_flag, dut.u_datapath.n_flag,
             dut.u_datapath.c_flag, dut.u_datapath.v_flag} !== 4'b1010) begin
            $display("ERROR tb_cpu_core: final ZNCV expected=1010 actual=%b",
                     {dut.u_datapath.z_flag, dut.u_datapath.n_flag,
                      dut.u_datapath.c_flag, dut.u_datapath.v_flag});
            errors = errors + 1;
        end
        if ((^{mem_addr, io_addr, io_wdata, io_re, io_we,
               dut.u_datapath.z_flag, dut.u_datapath.n_flag,
               dut.u_datapath.c_flag, dut.u_datapath.v_flag}) === 1'bx) begin
            $display("ERROR tb_cpu_core: unknown state detected");
            errors = errors + 1;
        end

        if (errors == 0)
            $display("tb_cpu_core: TEST PASS commits=%0d opcode_coverage=%h", commits, opcode_coverage);
        else
            $display("tb_cpu_core: TEST FAIL errors=%0d", errors);
        $finish;
    end
endmodule
