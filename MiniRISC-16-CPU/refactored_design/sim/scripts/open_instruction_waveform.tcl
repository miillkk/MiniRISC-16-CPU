# Open a focused MiniRISC-16 instruction-execution waveform in Vivado GUI.
# The project is supplied on the Vivado command line before this script runs.

set simset [get_filesets sim_1]
set_property top tb_cpu_core $simset
set_property xsim.simulate.runtime {} $simset
update_compile_order -fileset $simset

catch {close_sim -force}
launch_simulation -simset $simset -mode behavioral

proc add_trace_signal {signal_path} {
    set objects [get_objects -quiet $signal_path]
    if {[llength $objects] > 0} {
        log_wave $objects
        add_wave $objects
    }
}

foreach signal {
    /tb_cpu_core/clk
    /tb_cpu_core/rst
    /tb_cpu_core/mem_addr
    /tb_cpu_core/instruction
    /tb_cpu_core/executing_pc
    /tb_cpu_core/executing_instruction
    /tb_cpu_core/dut/u_controller/opcode
} {
    add_trace_signal $signal
}

foreach signal {
    /tb_cpu_core/dut/rd_addr
    /tb_cpu_core/dut/rs_addr
    /tb_cpu_core/dut/imm8
    /tb_cpu_core/dut/alu_op
    /tb_cpu_core/dut/alu_src
    /tb_cpu_core/dut/reg_write
    /tb_cpu_core/dut/flags_write
    /tb_cpu_core/dut/branch_z
    /tb_cpu_core/dut/jump
    /tb_cpu_core/dut/wb_sel
    /tb_cpu_core/dut/control_io_re
    /tb_cpu_core/dut/control_io_we
} {
    add_trace_signal $signal
}

foreach signal {
    /tb_cpu_core/dut/u_datapath/pc
    /tb_cpu_core/dut/u_datapath/pc_plus_one
    /tb_cpu_core/dut/u_datapath/pc_next
    /tb_cpu_core/dut/u_datapath/branch_taken
    /tb_cpu_core/dut/u_datapath/rd_data
    /tb_cpu_core/dut/u_datapath/rs_data
    /tb_cpu_core/dut/u_datapath/immediate
    /tb_cpu_core/dut/u_datapath/alu_b
    /tb_cpu_core/dut/u_datapath/alu_result
    /tb_cpu_core/dut/u_datapath/writeback_data
    /tb_cpu_core/dut/u_datapath/rf_write_enable
} {
    add_trace_signal $signal
}

foreach signal {
    {/tb_cpu_core/dut/u_datapath/u_register_file/registers[0]}
    {/tb_cpu_core/dut/u_datapath/u_register_file/registers[1]}
    {/tb_cpu_core/dut/u_datapath/u_register_file/registers[2]}
    {/tb_cpu_core/dut/u_datapath/u_register_file/registers[3]}
    /tb_cpu_core/dut/u_datapath/z_flag
    /tb_cpu_core/dut/u_datapath/n_flag
    /tb_cpu_core/dut/u_datapath/c_flag
    /tb_cpu_core/dut/u_datapath/v_flag
} {
    add_trace_signal $signal
}

foreach signal {
    /tb_cpu_core/io_re
    /tb_cpu_core/io_we
    /tb_cpu_core/io_addr
    /tb_cpu_core/io_rdata
    /tb_cpu_core/io_wdata
} {
    add_trace_signal $signal
}

run all
puts "INSTRUCTION_WAVEFORM_READY"
