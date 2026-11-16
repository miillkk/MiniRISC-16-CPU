# Capture nine module-oriented views of one integrated instruction trace.
# Each view begins with the clock and the PC/instruction sampled at the
# committing rising edge, followed by the relevant module's data and controls.
set wave_dir $::env(MINIRISC_CYCLE_WAVE_DIR)
file mkdir $wave_dir

set common_signals {
    clk
    trace_cycle_valid
    trace_cycle_pc
    trace_cycle_instruction
    trace_cycle_opcode
}

set views [list \
    [list system_top {
        resetn trace_rst trace_pc trace_instruction trace_z
        trace_io_addr trace_io_wdata trace_io_rdata trace_io_re trace_io_we
        trace_gpio_pins
    }] \
    [list instruction_memory {
        trace_pc trace_instruction trace_cycle_pc_next
    }] \
    [list cpu_core {
        trace_cycle_rd_addr trace_cycle_rs_addr trace_cycle_imm8
        trace_cycle_alu_op trace_cycle_alu_src trace_cycle_reg_write
        trace_cycle_z_write trace_cycle_branch_z trace_cycle_jump
        trace_cycle_wb_sel trace_cycle_rd_data trace_cycle_rs_data
        trace_cycle_alu_result trace_cycle_writeback_data
        trace_cycle_pc_next trace_cycle_z_before
        trace_cycle_io_addr trace_cycle_io_wdata trace_cycle_io_rdata
        trace_cycle_io_re trace_cycle_io_we
    }] \
    [list alu {
        trace_cycle_rd_data trace_cycle_alu_b trace_cycle_alu_op
        trace_cycle_alu_result trace_cycle_z_before trace_z
    }] \
    [list controller {
        trace_cycle_rd_addr trace_cycle_rs_addr trace_cycle_imm8
        trace_cycle_alu_op trace_cycle_alu_src trace_cycle_reg_write
        trace_cycle_z_write trace_cycle_branch_z trace_cycle_jump
        trace_cycle_wb_sel trace_cycle_control_io_re trace_cycle_control_io_we
    }] \
    [list datapath {
        trace_cycle_rd_addr trace_cycle_rs_addr trace_cycle_rd_data
        trace_cycle_rs_data trace_cycle_imm8 trace_cycle_alu_b
        trace_cycle_alu_result trace_cycle_writeback_data
        trace_cycle_rf_write_enable trace_cycle_pc_next trace_cycle_z_before
        trace_pc trace_z trace_r0 trace_r1 trace_r2 trace_r3
    }] \
    [list register_file {
        trace_cycle_rd_addr trace_cycle_rs_addr trace_cycle_rd_data
        trace_cycle_rs_data trace_cycle_rf_write_enable
        trace_cycle_writeback_data trace_r0 trace_r1 trace_r2 trace_r3
    }] \
    [list reset {
        resetn trace_release_sync trace_rst trace_pc
    }] \
    [list gpio {
        trace_cycle_io_addr trace_cycle_io_wdata trace_cycle_io_rdata
        trace_cycle_io_re trace_cycle_io_we trace_cycle_gpio_pins
        trace_cycle_gpio_out_before trace_cycle_gpio_dir_before
        trace_cycle_gpio_in_sync trace_gpio_out trace_gpio_dir
        trace_gpio_in trace_gpio_pins
    }]]

log_wave -r [get_objects -r /tb_system/*]
open_vcd [file join $wave_dir tb_system_cycle.vcd]
log_vcd [get_objects -r /tb_system/*]

foreach view $views {
    set view_name [lindex $view 0]
    set signals [concat $common_signals [lindex $view 1]]
    create_wave_config $view_name
    foreach signal $signals {
        set path /tb_system/$signal
        set objects [get_objects $path]
        if {[llength $objects] != 1} {
            error "Expected one signal for $view_name: $path (got [llength $objects])"
        }
        add_wave $objects
    }
    save_wave_config [file join $wave_dir ${view_name}_cycle.wcfg]
    puts "CYCLE_VIEW_SAVED $view_name"
}

run all
close_vcd
quit
