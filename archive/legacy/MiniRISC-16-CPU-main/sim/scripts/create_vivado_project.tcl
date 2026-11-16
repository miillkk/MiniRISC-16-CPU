set script_path [info script]
set script_dir [file dirname $script_path]
if {[info exists ::env(MINIRISC_PROJECT_ROOT)] && $::env(MINIRISC_PROJECT_ROOT) ne ""} {
    set project_root $::env(MINIRISC_PROJECT_ROOT)
} else {
    set project_root [file dirname [file dirname $script_dir]]
}
set project_dir [file join $project_root vivado_project]
set project_name MiniRISC16_CPU

puts "INFO: create_vivado_project.tcl script_path=$script_path"
puts "INFO: create_vivado_project.tcl project_root=$project_root"
puts "INFO: create_vivado_project.tcl project_dir=$project_dir"
file mkdir $project_dir
create_project $project_name $project_dir -force

if {[info exists ::env(MINIRISC_FPGA_PART)] && $::env(MINIRISC_FPGA_PART) ne ""} {
    set candidate_parts [list $::env(MINIRISC_FPGA_PART)]
} else {
    set candidate_parts {
    xc7z020clg400-1
    xc7a35tcpg236-1
    xc7a100tcsg324-1
}
}

set selected_part ""
foreach part_name $candidate_parts {
    if {[llength [get_parts -quiet $part_name]] > 0} {
        set selected_part $part_name
        break
    }
}

if {$selected_part ne ""} {
    set_property part $selected_part [current_project]
    puts "INFO: Selected temporary simulation/project part: $selected_part"
} else {
    puts "WARNING: No candidate FPGA part was found. Set the real board part manually before synthesis."
}

set_property target_language Verilog [current_project]
set_property simulator_language Verilog [current_project]
set_property target_simulator XSim [current_project]

set design_files [list]
foreach pattern [list \
    [file join $project_root rtl core *.v] \
    [file join $project_root rtl peripherals *.v] \
    [file join $project_root rtl top *.v] \
] {
    foreach file_name [glob -nocomplain $pattern] {
        lappend design_files $file_name
    }
}

add_files -norecurse -fileset sources_1 $design_files
set_property top system_top [get_filesets sources_1]

set sim_files [list]
foreach pattern [list \
    [file join $project_root sim tb *.v] \
    [file join $project_root sim programs *.mem] \
] {
    foreach file_name [glob -nocomplain $pattern] {
        lappend sim_files $file_name
    }
}

add_files -norecurse -fileset sim_1 $sim_files
set_property top tb_system [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

set mem_file [file join $project_root sim programs system_demo.mem]
if {[file exists $mem_file]} {
    set_property file_type {Memory Initialization Files} [get_files $mem_file]
}

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "INFO: Vivado project created:"
puts "INFO:   [file join $project_dir $project_name.xpr]"
puts "INFO: Design top: system_top"
puts "INFO: Simulation top: tb_system"
