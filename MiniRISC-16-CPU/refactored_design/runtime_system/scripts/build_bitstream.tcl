set script_dir [file dirname [info script]]
set_param general.maxThreads 1
if {[info exists ::env(RUNTIME_SYSTEM_ROOT)] && $::env(RUNTIME_SYSTEM_ROOT) ne ""} {
    set design_root $::env(RUNTIME_SYSTEM_ROOT)
} else { set design_root [file join $script_dir ..] }
set implementation_dir [file join $design_root reports implementation]
set board_dir [file join $design_root reports board]
file mkdir $implementation_dir
file mkdir $board_dir
set design_files [list]
foreach pattern [list [file join $design_root rtl core *.v] \
                           [file join $design_root rtl memory *.v] \
                           [file join $design_root rtl peripherals *.v] \
                           [file join $design_root rtl board *.v] \
                           [file join $design_root rtl top *.v]] {
    foreach file_name [glob -nocomplain $pattern] { lappend design_files $file_name }
}
read_verilog $design_files
read_xdc [file join $design_root constraints EES331_runtime.xdc]
synth_design -top runtime_board_top -part xc7z020clg484-1
opt_design
# The 1K asynchronous program RAM is the longest single-cycle path. Explicit
# timing-driven directives give the placer/router enough effort to close the
# 100 MHz target without changing the CPU into a pipelined architecture.
place_design -directive Explore
phys_opt_design -directive AggressiveExplore
route_design
report_utilization -file [file join $implementation_dir runtime-implemented-utilization.rpt]
report_timing_summary -file [file join $implementation_dir runtime-implemented-timing.rpt]
report_drc -file [file join $implementation_dir runtime-implemented-drc.rpt]
report_io -file [file join $implementation_dir runtime-io.rpt]
report_methodology -file [file join $implementation_dir runtime-methodology.rpt]
write_checkpoint -force [file join $implementation_dir runtime_routed.dcp]
set worst_path [get_timing_paths -delay_type max -max_paths 1 -nworst 1]
if {[llength $worst_path] == 0} { error "No setup timing path was reported." }
set worst_slack [get_property SLACK [lindex $worst_path 0]]
if {$worst_slack < 0.0} { error "Timing failed: WNS=$worst_slack ns" }
write_bitstream -force [file join $board_dir MiniRISC16_Runtime.bit]
puts "RUNTIME BITSTREAM PASS: WNS=$worst_slack ns"
