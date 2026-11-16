set script_dir [file dirname [info script]]
set_param general.maxThreads 1
if {[info exists ::env(HDMI_SNAKE_ROOT)] && $::env(HDMI_SNAKE_ROOT) ne ""} {
    set design_root $::env(HDMI_SNAKE_ROOT)
} else {
    set design_root [file join $script_dir ..]
}
set diag_dir [file join $design_root reports diagnostics]
open_checkpoint [file join $diag_dir diagnostic_synth.dcp]
opt_design
place_design -directive Default
route_design
write_checkpoint -force [file join $diag_dir diagnostic_routed_preopt.dcp]
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
