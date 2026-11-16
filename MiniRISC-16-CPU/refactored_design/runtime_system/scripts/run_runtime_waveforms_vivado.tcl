set script_dir [file dirname [file normalize [info script]]]
set design_root [file normalize [file join $script_dir ..]]
set output_dir [file join $design_root reports waveforms current_terminal vivado]
set project_dir [file join $design_root waveform_project]
file mkdir $output_dir
file mkdir $project_dir

create_project runtime_waveforms_project $project_dir -force -part xc7z020clg484-1
set_property target_simulator XSim [current_project]

# Vivado 2026.1 ships an old Windows MinGW under tps/mingw/6.2.0.  On
# hosts where that gcc.exe cannot start, UG900 supports selecting a working
# compiler through GCC_SIM_EXE_PATH / launch_simulation -gcc_install_path.
set gcc_install_path {}
if {[info exists ::env(GCC_SIM_EXE_PATH)] && $::env(GCC_SIM_EXE_PATH) ne {}} {
    set gcc_install_path [file normalize $::env(GCC_SIM_EXE_PATH)]
    if {![file exists [file join $gcc_install_path gcc.exe]]} {
        error "GCC_SIM_EXE_PATH does not contain gcc.exe: $gcc_install_path"
    }
    puts "Using XSim GCC: $gcc_install_path"
}

set rtl_files [glob -nocomplain [file join $design_root rtl * *.v]]
add_files -norecurse $rtl_files
add_files -norecurse -fileset sim_1 [file join $design_root tb tb_runtime_waveforms.v]

set simset [get_filesets sim_1]
set_property xsim.elaborate.debug_level typical $simset
set_property xsim.simulate.runtime {} $simset

set test_specs [list \
    [list running_light tb_runtime_running_light_wave \
        {clk rst pc instruction io_we io_addr io_wdata led}] \
    [list extended_isa tb_runtime_extended_isa_wave \
        {clk rst pc pc_next instruction opcode data_we data_re data_addr data_wdata data_rdata reg_write flags_write branch_z branch_taken jump long_jump io_we io_addr io_wdata z_flag rd_data rs_data alu_result writeback_data r0 r1 r2 r3}]]

foreach spec $test_specs {
    lassign $spec test_name top_name signals
    puts "=== START $test_name ($top_name) ==="
    set_property top $top_name $simset
    set_property xsim.simulate.wdb [file join $output_dir ${test_name}.wdb] $simset
    if {$test_name eq "running_light"} {
        set running_light_mem [file normalize [file join $design_root games running_light program running_light.mem]]
        set_property -name xsim.simulate.xsim.more_options \
            -value "-testplusarg NO_TB_VCD -testplusarg RUNNING_LIGHT_MEM=$running_light_mem" -objects $simset
    } else {
        set_property -name xsim.simulate.xsim.more_options \
            -value "-testplusarg NO_TB_VCD" -objects $simset
    }
    update_compile_order -fileset sources_1
    update_compile_order -fileset sim_1
    catch {close_sim -force}
    if {$gcc_install_path eq {}} {
        launch_simulation -simset $simset -mode behavioral
    } else {
        launch_simulation -simset $simset -mode behavioral \
            -gcc_install_path $gcc_install_path
    }

    set objects {}
    foreach signal $signals {
        set found [get_objects -quiet /${top_name}/${signal}]
        if {[llength $found] == 0} {
            error "Missing waveform signal /${top_name}/${signal}"
        }
        lappend objects {*}$found
    }

    set vcd_path [file join $output_dir ${test_name}.vcd]
    open_vcd $vcd_path
    log_vcd $objects
    log_wave $objects

    create_wave_config ${test_name}_focused
    foreach signal $signals object $objects {
        set leaf [file tail $signal]
        if {$leaf in {clk rst io_we data_we data_re long_jump z_flag}} {
            add_wave -radix bin -name $leaf $object
        } else {
            add_wave -radix hex -name $leaf $object
        }
    }
    save_wave_config [file join $output_dir ${test_name}.wcfg]
    run all
    close_vcd

    set sim_log [file join $project_dir runtime_waveforms_project.sim sim_1 behav xsim simulate.log]
    if {[file exists $sim_log]} {
        set copied_log [file join $output_dir ${test_name}_simulate.log]
        file copy -force $sim_log $copied_log
        set log_handle [open $copied_log r]
        set log_text [read $log_handle]
        close $log_handle
        if {![string match {*TEST PASS*} $log_text]} {
            error "XSim did not report TEST PASS for $test_name"
        }
    } else {
        error "Missing XSim simulate.log for $test_name"
    }
    foreach artifact [list \
        [file join $output_dir ${test_name}.wdb] \
        [file join $output_dir ${test_name}.vcd] \
        [file join $output_dir ${test_name}.wcfg]] {
        if {![file exists $artifact] || [file size $artifact] == 0} {
            error "Missing or empty XSim artifact: $artifact"
        }
    }
    puts "=== COMPLETE $test_name ==="
}

catch {close_sim -force}
close_project
puts "RUNTIME_WAVEFORMS_COMPLETE"
