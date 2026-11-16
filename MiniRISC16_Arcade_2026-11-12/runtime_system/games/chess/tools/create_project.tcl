# Run with "source .../create_project.tcl" in the Vivado Tcl Console.
set root [file normalize [file join [file dirname [info script]] ../../..]]
set game [file join $root games chess]
set project_dir [file join $game vivado_project_4k]
set project_file [file join $project_dir MiniRISC16_Arcade4K.xpr]
if {[llength [get_projects -quiet]] != 0} {
    error "Close the current project first (File > Close Project), then source this script again."
}
if {[file exists $project_file]} {
    open_project $project_file
} else {
    create_project MiniRISC16_Arcade4K $project_dir -part xc7z020clg484-1
    set_property target_language Verilog [current_project]
    set_property simulator_language Verilog [current_project]
    set_property target_simulator XSim [current_project]
    set overrides {program_counter next_pc_mux cpu_core datapath runtime_soc program_loader runtime_program_memory runtime_board_top}
    foreach dir {core memory peripherals board top} {
        foreach f [glob [file join $root rtl $dir *.v]] {
            if {[lsearch -exact $overrides [file rootname [file tail $f]]] < 0} {
                add_files -norecurse -fileset sources_1 $f
            }
        }
    }
    foreach f [glob [file join $game hardware *.v]] {
        if {[string match tb_* [file tail $f]]} {
            add_files -norecurse -fileset sim_1 $f
        } else {
            add_files -norecurse -fileset sources_1 $f
        }
    }
    add_files -norecurse -fileset constrs_1 [file join $root constraints EES331_runtime.xdc]
    set_property top runtime_board_top [get_filesets sources_1]
    set_property top tb_chess4k [get_filesets sim_1]
    update_compile_order -fileset sources_1
    update_compile_order -fileset sim_1
}
set_param general.maxThreads 1
puts "4K ARCADE PROJECT OPEN: $project_file"
puts "Top: runtime_board_top; device: xc7z020clg484-1; internal system clock: 50 MHz."
