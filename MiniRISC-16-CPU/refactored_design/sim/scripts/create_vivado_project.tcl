set script_dir [file dirname [info script]]
if {[info exists ::env(MINIRISC_REFACTORED_ROOT)] && $::env(MINIRISC_REFACTORED_ROOT) ne ""} {
    set design_root $::env(MINIRISC_REFACTORED_ROOT)
} else {
    set design_root [file join $script_dir .. ..]
}
set project_dir [file join $design_root vivado_project]
set project_name MiniRISC16_Refactored

create_project $project_name $project_dir -force -part xc7z020clg484-1
set_property target_language Verilog [current_project]
set_property simulator_language Verilog [current_project]
set_property target_simulator XSim [current_project]

set design_files [list]
foreach pattern [list \
    [file join $design_root rtl core *.v] \
    [file join $design_root rtl peripherals *.v] \
    [file join $design_root rtl top *.v] \
] {
    foreach file_name [glob -nocomplain $pattern] {
        lappend design_files $file_name
    }
}
add_files -norecurse -fileset sources_1 $design_files
set_property top system_top [get_filesets sources_1]

set cpu_testbenches [list \
    tb_alu.v \
    tb_controller.v \
    tb_register_file.v \
    tb_program_counter.v \
    tb_next_pc_mux.v \
    tb_status_register.v \
    tb_zero_extender_8_to_16.v \
    tb_alu_operand_mux.v \
    tb_writeback_mux.v \
    tb_datapath.v \
    tb_cpu_core.v \
]
set sim_files [list]
foreach testbench $cpu_testbenches {
    lappend sim_files [file join $design_root sim tb $testbench]
}
add_files -norecurse -fileset sim_1 $sim_files
set program_file [file join $design_root sim programs system_demo.mem]
add_files -norecurse -fileset sources_1 $program_file
add_files -norecurse -fileset sim_1 $program_file
set_property file_type {Memory Initialization Files} [get_files $program_file]
set_property generic [list INIT_FILE=$program_file] [get_filesets sources_1]
set_property top tb_cpu_core [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
puts "PROJECT CREATED: [file join $project_dir ${project_name}.xpr]"
