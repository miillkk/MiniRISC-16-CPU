set script_dir [file dirname [info script]]
if {[info exists ::env(MINIRISC_REFACTORED_ROOT)] && $::env(MINIRISC_REFACTORED_ROOT) ne ""} {
    set design_root $::env(MINIRISC_REFACTORED_ROOT)
} else {
    set design_root [file join $script_dir .. ..]
}
set project_dir [file join $design_root board_vivado_project]
set project_name MiniRISC16_EES331

create_project $project_name $project_dir -force -part xc7z020clg484-1
set_property target_language Verilog [current_project]
set_property simulator_language Verilog [current_project]
set_property target_simulator XSim [current_project]

set design_files [list]
foreach pattern [list \
    [file join $design_root rtl core *.v] \
    [file join $design_root rtl peripherals *.v] \
    [file join $design_root rtl board *.v] \
] {
    foreach file_name [glob -nocomplain $pattern] {
        lappend design_files $file_name
    }
}
add_files -norecurse -fileset sources_1 $design_files
set_property top board_top [get_filesets sources_1]

set xdc_file [file join $design_root constraints EES331.xdc]
add_files -norecurse -fileset constrs_1 $xdc_file

set program_file [file join $design_root sim programs board_demo.mem]
add_files -norecurse -fileset sources_1 $program_file
set_property file_type {Memory Initialization Files} [get_files $program_file]
set_property generic [list INIT_FILE=$program_file] [get_filesets sources_1]

set sim_files [glob -nocomplain [file join $design_root sim tb *.v]]
add_files -norecurse -fileset sim_1 $sim_files
add_files -norecurse -fileset sim_1 $program_file
set_property top tb_board_top_smoke [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
puts "BOARD PROJECT CREATED: [file join $project_dir ${project_name}.xpr]"
