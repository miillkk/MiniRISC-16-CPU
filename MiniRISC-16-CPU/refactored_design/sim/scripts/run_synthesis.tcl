set script_dir [file dirname [info script]]
if {[info exists ::env(MINIRISC_REFACTORED_ROOT)] && $::env(MINIRISC_REFACTORED_ROOT) ne ""} {
    set design_root $::env(MINIRISC_REFACTORED_ROOT)
} else {
    set design_root [file join $script_dir .. ..]
}
set report_dir [file join $design_root reports synthesis]
file mkdir $report_dir

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

read_verilog $design_files
set program_file [file join $design_root sim programs system_demo.mem]
synth_design -top system_top -part xc7z020clg484-1 -generic [list INIT_FILE=$program_file]
report_utilization -file [file join $report_dir utilization.rpt]
report_drc -file [file join $report_dir drc.rpt]
report_methodology -file [file join $report_dir methodology.rpt]
write_checkpoint -force [file join $report_dir system_top_synth.dcp]
puts "SYNTHESIS PASS"
