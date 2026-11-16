set script_dir [file dirname [info script]]
set_param general.maxThreads 1
if {[info exists ::env(HDMI_SNAKE_ROOT)] && $::env(HDMI_SNAKE_ROOT) ne ""} {
    set design_root $::env(HDMI_SNAKE_ROOT)
} else {
    set design_root [file join $script_dir ..]
}
set diag_dir [file join $design_root reports diagnostics]
file mkdir $diag_dir

set design_files [list]
foreach pattern [list [file join $design_root rtl core *.v] \
                           [file join $design_root rtl memory *.v] \
                           [file join $design_root rtl peripherals *.v] \
                           [file join $design_root rtl board *.v] \
                           [file join $design_root rtl video *.v] \
                           [file join $design_root rtl top *.v]] {
    foreach file_name [glob -nocomplain $pattern] { lappend design_files $file_name }
}
read_verilog $design_files
read_xdc [file join $design_root constraints EES331_hdmi_snake.xdc]
synth_design -top hdmi_snake_board_top -part xc7z020clg484-1 -generic {HDMI_DIAGNOSTIC_LEDS=1}
read_xdc [file join $design_root constraints video_frame_cdc.xdc]
write_checkpoint -force [file join $diag_dir diagnostic_synth.dcp]
opt_design
place_design -directive Explore
phys_opt_design -directive AggressiveExplore
route_design
phys_opt_design -directive Explore
report_timing_summary -file [file join $diag_dir timing.rpt]
report_drc -file [file join $diag_dir drc.rpt]
report_utilization -file [file join $diag_dir utilization.rpt]
write_checkpoint -force [file join $diag_dir diagnostic_routed.dcp]

set worst_path [get_timing_paths -delay_type max -max_paths 1 -nworst 1]
if {[llength $worst_path] == 0} { error "No setup timing path was reported." }
set worst_slack [get_property SLACK [lindex $worst_path 0]]
if {$worst_slack < 0.0} { error "Diagnostic timing failed: WNS=$worst_slack ns" }
set drc_errors [get_drc_violations -quiet -filter {SEVERITY == Error}]
if {[llength $drc_errors] != 0} { error "Diagnostic DRC contains errors." }
write_bitstream -force [file join $diag_dir MiniRISC16_HDMI_Diagnostic.bit]
puts "HDMI DIAGNOSTIC BITSTREAM PASS: WNS=$worst_slack ns"
