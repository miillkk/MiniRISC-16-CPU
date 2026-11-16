set script_dir [file dirname [info script]]
if {[info exists ::env(CALCULATOR_SYSTEM_ROOT)] && $::env(CALCULATOR_SYSTEM_ROOT) ne ""} {
    set design_root $::env(CALCULATOR_SYSTEM_ROOT)
} else {
    set design_root [file join $script_dir ..]
}
set implementation_dir [file join $design_root reports implementation]
set board_dir [file join $design_root reports board]
file mkdir $implementation_dir
file mkdir $board_dir

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
opt_design
place_design
phys_opt_design
route_design

report_utilization -file [file join $implementation_dir calculator-implemented-utilization.rpt]
report_timing_summary -file [file join $implementation_dir calculator-implemented-timing.rpt]
report_drc -file [file join $implementation_dir calculator-implemented-drc.rpt]
report_io -file [file join $implementation_dir calculator-io.rpt]
report_methodology -file [file join $implementation_dir calculator-methodology.rpt]
write_checkpoint -force [file join $implementation_dir calculator_routed.dcp]

set worst_path [get_timing_paths -delay_type max -max_paths 1 -nworst 1]
if {[llength $worst_path] == 0} { error "No setup timing path was reported." }
set worst_slack [get_property SLACK [lindex $worst_path 0]]
if {$worst_slack < 0.0} { error "Timing failed: WNS=$worst_slack ns" }

write_bitstream -force [file join $board_dir MiniRISC16_Calculator.bit]
puts "CALCULATOR BITSTREAM PASS: WNS=$worst_slack ns"
