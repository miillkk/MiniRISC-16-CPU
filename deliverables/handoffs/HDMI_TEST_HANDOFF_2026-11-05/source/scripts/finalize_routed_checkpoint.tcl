set script_dir [file dirname [info script]]
set_param general.maxThreads 1
if {[info exists ::env(HDMI_SNAKE_ROOT)] && $::env(HDMI_SNAKE_ROOT) ne ""} {
    set design_root $::env(HDMI_SNAKE_ROOT)
} else { set design_root [file join $script_dir ..] }
set implementation_dir [file join $design_root reports implementation]
set board_dir [file join $design_root reports board]
file mkdir $board_dir
open_checkpoint [file join $implementation_dir hdmi_snake_routed.dcp]
set frame_sources [get_cells -hier -filter {NAME =~ *u_video_frame_bridge/held_frame_reg*}]
set frame_destinations [get_cells -hier -filter {NAME =~ *u_video_frame_bridge/pixel_frame_reg*}]
if {[llength $frame_sources] == 0 || [llength $frame_destinations] == 0} {
    error "CDC constraint targets were not found in the routed checkpoint."
}
puts "VIDEO FRAME CDC: [llength $frame_sources] sources, [llength $frame_destinations] destinations"
read_xdc [file join $design_root constraints video_frame_cdc.xdc]
report_timing_summary -file [file join $implementation_dir hdmi-snake-cdc-timing.rpt]
phys_opt_design -directive Explore
report_timing_summary -file [file join $implementation_dir hdmi-snake-postroute-timing.rpt]
report_drc -file [file join $implementation_dir hdmi-snake-postroute-drc.rpt]
set worst_path [get_timing_paths -delay_type max -max_paths 1 -nworst 1]
if {[llength $worst_path] == 0} { error "No setup timing path was reported." }
set worst_slack [get_property SLACK [lindex $worst_path 0]]
if {$worst_slack < 0.0} { error "Post-route timing failed: WNS=$worst_slack ns" }
write_checkpoint -force [file join $implementation_dir hdmi_snake_timing_closed.dcp]
write_bitstream -force [file join $board_dir MiniRISC16_HDMISnake.bit]
puts "HDMI SNAKE BITSTREAM PASS: WNS=$worst_slack ns"
