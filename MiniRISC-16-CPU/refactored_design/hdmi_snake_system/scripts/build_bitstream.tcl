set script_dir [file dirname [info script]]
set_param general.maxThreads 1
if {[info exists ::env(HDMI_SNAKE_ROOT)] && $::env(HDMI_SNAKE_ROOT) ne ""} {
    set design_root $::env(HDMI_SNAKE_ROOT)
} else { set design_root [file join $script_dir ..] }
set implementation_dir [file join $design_root reports implementation]
set board_dir [file join $design_root reports board]
file mkdir $implementation_dir
file mkdir $board_dir
open_checkpoint [file join $implementation_dir hdmi_snake_synth.dcp]
opt_design
# The 1K asynchronous program RAM is the longest single-cycle path. Explicit
# timing-driven directives give the placer/router enough effort to close the
# 100 MHz target without changing the CPU into a pipelined architecture.
place_design -directive Explore
phys_opt_design -directive AggressiveExplore
route_design
write_checkpoint -force [file join $implementation_dir hdmi_snake_routed.dcp]
phys_opt_design -directive Explore
report_utilization -file [file join $implementation_dir hdmi-snake-implemented-utilization.rpt]
report_timing_summary -file [file join $implementation_dir hdmi-snake-implemented-timing.rpt]
report_drc -file [file join $implementation_dir hdmi-snake-implemented-drc.rpt]
report_io -file [file join $implementation_dir hdmi-snake-io.rpt]
report_methodology -file [file join $implementation_dir hdmi-snake-methodology.rpt]
write_checkpoint -force [file join $implementation_dir hdmi_snake_timing_closed.dcp]
set worst_path [get_timing_paths -delay_type max -max_paths 1 -nworst 1]
if {[llength $worst_path] == 0} { error "No setup timing path was reported." }
set worst_slack [get_property SLACK [lindex $worst_path 0]]
if {$worst_slack < 0.0} { error "Timing failed: WNS=$worst_slack ns" }
write_bitstream -force [file join $board_dir MiniRISC16_HDMISnake.bit]
puts "HDMI SNAKE BITSTREAM PASS: WNS=$worst_slack ns"
