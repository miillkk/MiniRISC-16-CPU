set script_dir [file dirname [info script]]
if {[info exists ::env(MINIRISC_REFACTORED_ROOT)] && $::env(MINIRISC_REFACTORED_ROOT) ne ""} {
    set design_root $::env(MINIRISC_REFACTORED_ROOT)
} else {
    set design_root [file join $script_dir .. ..]
}
set report_dir [file join $design_root reports board]
file mkdir $report_dir

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

read_verilog $design_files
read_xdc [file join $design_root constraints EES331.xdc]
set program_file [file join $design_root sim programs board_demo.mem]
synth_design -top board_top -part xc7z020clg484-1 -generic [list INIT_FILE=$program_file]
opt_design
place_design
phys_opt_design
route_design

report_utilization -file [file join $report_dir board-implemented-utilization.rpt]
report_timing_summary -file [file join $report_dir board-implemented-timing.rpt]
report_drc -file [file join $report_dir board-implemented-drc.rpt]
report_io -file [file join $report_dir board-io.rpt]
write_checkpoint -force [file join $report_dir board_top_routed.dcp]
write_bitstream -force [file join $report_dir MiniRISC16_EES331.bit]
puts "BOARD BITSTREAM PASS"
