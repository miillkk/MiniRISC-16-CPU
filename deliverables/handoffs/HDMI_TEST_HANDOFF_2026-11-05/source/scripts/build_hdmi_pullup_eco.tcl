set script_dir [file dirname [info script]]
if {[info exists ::env(HDMI_SNAKE_ROOT)] && $::env(HDMI_SNAKE_ROOT) ne ""} {
    set design_root $::env(HDMI_SNAKE_ROOT)
} else {
    set design_root [file join $script_dir ..]
}

# Preserve the SCL-release LED diagnostic added by build_hdmi_scl_eco.tcl.
set source_checkpoint [file join $design_root reports diagnostics link_drive_eco link_drive_eco_routed.dcp]
set output_dir [file join $design_root reports diagnostics link_pullup_eco]
file mkdir $output_dir

open_checkpoint $source_checkpoint

set i2c_ports [get_ports -quiet {iic_scl_hdmi iic_sda_hdmi}]
if {[llength $i2c_ports] != 2} {
    error "Expected exactly two HDMI I2C ports, found [llength $i2c_ports]."
}

# Diagnostic-only weak pull-ups. The open-drain RTL remains unchanged.
set_property PULLUP true $i2c_ports
foreach port $i2c_ports {
    puts "PULLUP [get_property NAME $port]=[get_property PULLUP $port]"
}

# PULLUP is an IOB configuration property. It adds no logical connection and
# does not invalidate the already completed placement/routing in this DCP.
# Avoid rerunning route_design because Vivado 2026.1 is intermittently crashing
# in router initialization on this host.

report_timing_summary -file [file join $output_dir timing.rpt]
report_drc -file [file join $output_dir drc.rpt]
report_route_status -file [file join $output_dir route_status.rpt]
report_utilization -file [file join $output_dir utilization.rpt]
write_checkpoint -force [file join $output_dir link_pullup_eco_routed.dcp]

set worst_path [get_timing_paths -delay_type max -max_paths 1 -nworst 1]
if {[llength $worst_path] == 0} { error "No setup timing path was reported." }
set worst_slack [get_property SLACK [lindex $worst_path 0]]
if {$worst_slack < 0.0} { error "HDMI pull-up ECO timing failed: WNS=$worst_slack ns" }

set drc_errors [get_drc_violations -quiet -filter {SEVERITY == Error}]
if {[llength $drc_errors] != 0} { error "HDMI pull-up ECO DRC contains errors." }

set output_bit [file join $output_dir MiniRISC16_HDMI_PullupDiagnostic.bit]
write_bitstream -force $output_bit
puts "HDMI PULLUP DIAGNOSTIC BITSTREAM PASS: WNS=$worst_slack ns"
puts "OUTPUT=$output_bit"
puts "LED MAP WITH SW0=1: LED7..3=I2C state, LED2=sampled SCL, LED1=sampled SDA, LED0=SCL released"
