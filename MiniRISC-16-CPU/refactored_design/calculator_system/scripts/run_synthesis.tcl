set script_dir [file dirname [info script]]
if {[info exists ::env(CALCULATOR_SYSTEM_ROOT)] && $::env(CALCULATOR_SYSTEM_ROOT) ne ""} {
    set design_root $::env(CALCULATOR_SYSTEM_ROOT)
} else {
    set design_root [file join $script_dir ..]
}
set report_dir [file join $design_root reports synthesis]
file mkdir $report_dir

set design_files [list]
foreach pattern [list \
    [file join $design_root rtl core *.v] \
    [file join $design_root rtl memory *.v] \
    [file join $design_root rtl peripherals *.v] \
    [file join $design_root rtl board *.v] \
    [file join $design_root rtl top *.v] \
] {
    foreach file_name [glob -nocomplain $pattern] { lappend design_files $file_name }
}
read_verilog $design_files
read_xdc [file join $design_root constraints EES331_calculator.xdc]
set program_file [file join $design_root program calculator.mem]
synth_design -top calculator_board_top -part xc7z020clg484-1 \
    -generic [list INIT_FILE=$program_file]
report_utilization -file [file join $report_dir calculator-synthesis-utilization.rpt]
report_timing_summary -file [file join $report_dir calculator-synthesis-timing.rpt]
report_drc -file [file join $report_dir calculator-synthesis-drc.rpt]
write_checkpoint -force [file join $report_dir calculator_synth.dcp]
puts "CALCULATOR SYNTHESIS PASS"
