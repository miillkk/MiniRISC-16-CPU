set script_dir [file dirname [file normalize [info script]]]
set waveform_root [file normalize [file join $script_dir ..]]
set design_root [file normalize [file join $waveform_root ..]]
set output_dir [file join $waveform_root output]
set project_dir [file join $waveform_root project]
file mkdir $output_dir
file mkdir $project_dir

create_project instruction_waveforms_project $project_dir -force -part xc7z020clg484-1
set_property target_simulator XSim [current_project]

set rtl_dir [file join $design_root rtl core]
set rtl_files [list \
    [file join $rtl_dir alu.v] \
    [file join $rtl_dir alu_operand_mux.v] \
    [file join $rtl_dir controller.v] \
    [file join $rtl_dir cpu_core.v] \
    [file join $rtl_dir datapath.v] \
    [file join $rtl_dir next_pc_mux.v] \
    [file join $rtl_dir program_counter.v] \
    [file join $rtl_dir register_file.v] \
    [file join $rtl_dir status_register.v] \
    [file join $rtl_dir writeback_mux.v] \
    [file join $rtl_dir zero_extender_8_to_16.v]]
add_files -norecurse $rtl_files
add_files -norecurse -fileset sim_1 [file join $waveform_root tb tb_instruction_classes.v]

set simset [get_filesets sim_1]
set_property xsim.elaborate.debug_level typical $simset
set_property xsim.simulate.runtime {} $simset

set common_signals {clk mem_addr instruction dut/u_controller/opcode}

set class_specs [list \
    [list move tb_class_move \
        {dut/rd_addr dut/rs_addr dut/imm8 dut/alu_src dut/u_datapath/rs_data dut/u_datapath/alu_result dut/reg_write dut/u_datapath/writeback_data r0 r1 r2 r3}] \
    [list arithmetic tb_class_arithmetic \
        {dut/u_datapath/rd_data dut/u_datapath/rs_data dut/imm8 dut/alu_src dut/alu_op dut/u_datapath/alu_result dut/reg_write dut/flags_write dut/u_datapath/z_flag dut/u_datapath/c_flag r0 r1}] \
    [list logic tb_class_logic \
        {dut/u_datapath/rd_data dut/u_datapath/rs_data dut/alu_op dut/u_datapath/alu_result dut/reg_write dut/u_datapath/writeback_data r0 r1}] \
    [list branch tb_class_branch \
        {dut/imm8 dut/u_datapath/z_flag dut/branch_z dut/jump dut/u_datapath/branch_taken dut/u_datapath/pc_plus_one dut/u_datapath/pc_next r2 r3}] \
    [list io tb_class_io \
        {io_re io_we io_addr io_rdata io_wdata dut/wb_sel dut/reg_write r0}]]

foreach spec $class_specs {
    lassign $spec class_name top_name class_signals
    puts "=== START $class_name ($top_name) ==="

    set_property top $top_name $simset
    set_property xsim.simulate.wdb [file join $output_dir ${class_name}.wdb] $simset
    update_compile_order -fileset sources_1
    update_compile_order -fileset sim_1
    catch {close_sim -force}
    launch_simulation -simset $simset -mode behavioral

    set prefix /${top_name}/u_test
    set common_objects {}
    foreach signal $common_signals {
        set found [get_objects -quiet ${prefix}/${signal}]
        if {[llength $found] == 0} {
            error "Missing common signal ${prefix}/${signal}"
        }
        lappend common_objects {*}$found
    }

    set class_objects {}
    foreach signal $class_signals {
        set found [get_objects -quiet ${prefix}/${signal}]
        if {[llength $found] == 0} {
            error "Missing class signal ${prefix}/${signal}"
        }
        lappend class_objects {*}$found
    }
    set all_objects [concat $common_objects $class_objects]

    set vcd_path [file join $output_dir ${class_name}.vcd]
    open_vcd $vcd_path
    log_vcd $all_objects
    log_wave $all_objects

    create_wave_config ${class_name}_focused
    set common_group [add_wave_group {Instruction context}]
    foreach signal $common_signals object $common_objects {
        if {[string match */clk $object]} {
            add_wave -into $common_group -radix bin -name [file tail $signal] $object
        } else {
            add_wave -into $common_group -radix hex -name [file tail $signal] $object
        }
    }
    set class_group [add_wave_group {Class-specific changing signals}]
    foreach signal $class_signals object $class_objects {
        set leaf [file tail $signal]
        if {$leaf in {alu_src reg_write flags_write branch_z jump branch_taken z_flag n_flag c_flag v_flag io_re io_we wb_sel}} {
            add_wave -into $class_group -radix bin -name $leaf $object
        } else {
            add_wave -into $class_group -radix hex -name $leaf $object
        }
    }
    save_wave_config [file join $output_dir ${class_name}.wcfg]

    run all
    close_vcd

    set sim_log [file join $project_dir instruction_waveforms_project.sim sim_1 behav xsim simulate.log]
    if {[file exists $sim_log]} {
        file copy -force $sim_log [file join $output_dir ${class_name}_simulate.log]
    }
    puts "=== COMPLETE $class_name ==="
}

catch {close_sim -force}
close_project
puts "FIVE_WAVEFORMS_COMPLETE"
