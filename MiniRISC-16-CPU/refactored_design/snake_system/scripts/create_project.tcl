set script_dir [file dirname [info script]]
if {[info exists ::env(SNAKE_SYSTEM_ROOT)] && $::env(SNAKE_SYSTEM_ROOT) ne ""} {
    set design_root $::env(SNAKE_SYSTEM_ROOT)
} else { set design_root [file join $script_dir ..] }
set project_dir [file join $design_root vivado_project]
set project_name MiniRISC16_Snake

create_project $project_name $project_dir -force -part xc7z020clg484-1
set_property target_language Verilog [current_project]
set_property simulator_language Verilog [current_project]
set_property target_simulator XSim [current_project]
set design_files [list]
foreach pattern [list [file join $design_root rtl core *.v] \
                           [file join $design_root rtl memory *.v] \
                           [file join $design_root rtl peripherals *.v] \
                           [file join $design_root rtl board *.v] \
                           [file join $design_root rtl top *.v]] {
    foreach file_name [glob -nocomplain $pattern] { lappend design_files $file_name }
}
add_files -norecurse -fileset sources_1 $design_files
set_property top snake_board_top [get_filesets sources_1]
set xdc_file [file join $design_root constraints EES331_snake.xdc]
add_files -norecurse -fileset constrs_1 $xdc_file
set simulation_files [glob -nocomplain [file join $design_root tb *.v]]
add_files -norecurse -fileset sim_1 $simulation_files
set_property top tb_snake_system [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
puts "SNAKE PROJECT CREATED: [file join $project_dir ${project_name}.xpr]"
