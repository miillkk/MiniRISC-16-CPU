set script_dir [file dirname [info script]]
if {[info exists ::env(HDMI_SNAKE_ROOT)] && $::env(HDMI_SNAKE_ROOT) ne ""} {
    set design_root $::env(HDMI_SNAKE_ROOT)
} else {
    set design_root [file join $script_dir ..]
}

set source_checkpoint [file join $design_root reports diagnostics link_detail link_routed.dcp]
set output_dir [file join $design_root reports diagnostics link_drive_eco]
file mkdir $output_dir

open_checkpoint $source_checkpoint

# The routed link-detail image already puts sampled SCL on LED2.  Replace only
# LED0 (previously ACK error) with the SCL IOBUF T control: 1=released, 0=driven low.
set led0_pin [get_pins -quiet {led_OBUF[0]_inst/I}]
set old_led0_net [get_nets -quiet -of_objects $led0_pin]
set scl_release_net [get_nets -quiet {iic_scl_hdmi_TRI}]
if {[llength $led0_pin] != 1 || [llength $old_led0_net] != 1 || [llength $scl_release_net] != 1} {
    error "Unable to locate unique LED0 or HDMI SCL tristate net for ECO."
}

disconnect_net -net $old_led0_net -objects $led0_pin
connect_net -hierarchical -net $scl_release_net -objects $led0_pin
route_design -preserve

report_timing_summary -file [file join $output_dir timing.rpt]
report_drc -file [file join $output_dir drc.rpt]
report_utilization -file [file join $output_dir utilization.rpt]
write_checkpoint -force [file join $output_dir link_drive_eco_routed.dcp]

set worst_path [get_timing_paths -delay_type max -max_paths 1 -nworst 1]
if {[llength $worst_path] == 0} { error "No setup timing path was reported." }
set worst_slack [get_property SLACK [lindex $worst_path 0]]
if {$worst_slack < 0.0} { error "HDMI SCL ECO timing failed: WNS=$worst_slack ns" }
set drc_errors [get_drc_violations -quiet -filter {SEVERITY == Error}]
if {[llength $drc_errors] != 0} { error "HDMI SCL ECO DRC contains errors." }

set output_bit [file join $output_dir MiniRISC16_HDMI_SCLDiagnostic.bit]
write_bitstream -force $output_bit
puts "HDMI SCL ECO BITSTREAM PASS: WNS=$worst_slack ns"
puts "OUTPUT=$output_bit"
puts "LED MAP WITH SW0=1: LED7..3=I2C state, LED2=sampled SCL, LED1=sampled SDA, LED0=SCL released"
