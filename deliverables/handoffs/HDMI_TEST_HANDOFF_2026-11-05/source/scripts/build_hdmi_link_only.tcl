set script_dir [file dirname [info script]]
set_param general.maxThreads 1
if {[info exists ::env(HDMI_SNAKE_ROOT)] && $::env(HDMI_SNAKE_ROOT) ne ""} {
    set design_root $::env(HDMI_SNAKE_ROOT)
} else {
    set design_root [file join $script_dir ..]
}
set diag_dir [file join $design_root reports diagnostics link_drive]
file mkdir $diag_dir
# Keep the link diagnostic genuinely isolated. Loading the CPU, memories and
# unrelated peripherals adds no logic to this top and makes Vivado's unstable
# synthesis front end do unnecessary work.
set design_files [list \
    [file join $design_root rtl board reset_conditioner.v] \
    [file join $design_root rtl video pixel_clock_generator.v] \
    [file join $design_root rtl video video_timing_640x480.v] \
    [file join $design_root rtl video video_frame_bridge.v] \
    [file join $design_root rtl video font5x7.v] \
    [file join $design_root rtl video snake_renderer.v] \
    [file join $design_root rtl video hdmi_output_registers.v] \
    [file join $design_root rtl video i2c_master.v] \
    [file join $design_root rtl video adv7511_controller.v] \
    [file join $design_root rtl video hdmi_video_subsystem.v] \
    [file join $design_root rtl top hdmi_link_diagnostic_top.v]]
read_verilog $design_files
read_xdc [file join $design_root constraints EES331_hdmi_snake.xdc]
synth_design -top hdmi_link_diagnostic_top -part xc7z020clg484-1
write_checkpoint -force [file join $diag_dir link_synth.dcp]
opt_design
place_design -directive Default
route_design
report_timing_summary -file [file join $diag_dir timing.rpt]
report_drc -file [file join $diag_dir drc.rpt]
report_utilization -file [file join $diag_dir utilization.rpt]
write_checkpoint -force [file join $diag_dir link_routed.dcp]
set worst_path [get_timing_paths -delay_type max -max_paths 1 -nworst 1]
if {[llength $worst_path] == 0} { error "No setup timing path was reported." }
set worst_slack [get_property SLACK [lindex $worst_path 0]]
if {$worst_slack < 0.0} { error "HDMI link diagnostic timing failed: WNS=$worst_slack ns" }
set drc_errors [get_drc_violations -quiet -filter {SEVERITY == Error}]
if {[llength $drc_errors] != 0} { error "HDMI link diagnostic DRC contains errors." }
write_bitstream -force [file join $diag_dir MiniRISC16_HDMI_DriveDiagnostic.bit]
puts "HDMI DRIVE DIAGNOSTIC BITSTREAM PASS: WNS=$worst_slack ns"
