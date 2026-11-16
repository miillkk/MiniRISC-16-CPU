set script_dir [file dirname [info script]]
set_param general.maxThreads 1
set design_root [file join $script_dir ..]
set source_checkpoint [file join $design_root reports diagnostics link_drive_eco link_drive_eco_routed.dcp]
set output_dir [file join $design_root reports diagnostics i2c_manual_eco]
file mkdir $output_dir

open_checkpoint $source_checkpoint

set sw0_net [get_nets -quiet {switches_IBUF[0]}]
set resetn_net [get_nets -quiet -of_objects [get_pins -quiet {resetn_IBUF_inst/O}]]
set scl_t_pin [get_pins -quiet {iic_scl_hdmi_IOBUF_inst/T}]
set sda_t_pin [get_pins -quiet {iic_sda_hdmi_IOBUF_inst/T}]
set scl_input_net [get_nets -quiet -of_objects [get_pins -quiet {iic_scl_hdmi_IOBUF_inst/O}]]
set sda_input_net [get_nets -quiet -of_objects [get_pins -quiet {iic_sda_hdmi_IOBUF_inst/O}]]

foreach item [list $sw0_net $resetn_net $scl_t_pin $sda_t_pin $scl_input_net $sda_input_net] {
    if {[llength $item] != 1} { error "Manual I2C ECO could not resolve a unique required object." }
}

proc reconnect_pin {pin new_net} {
    set old_net [get_nets -quiet -of_objects $pin]
    if {[llength $old_net] == 1} {
        disconnect_net -net $old_net -objects $pin
    }
    connect_net -hierarchical -net $new_net -objects $pin
}

# IOBUF T=1 releases the open-drain line; T=0 drives it low.
reconnect_pin $scl_t_pin $sw0_net
reconnect_pin $sda_t_pin $resetn_net

# L0=SCL release command, L1=SCL pad, L2=SDA pad, L3=SDA release command.
reconnect_pin [get_pins -quiet {led_OBUF[0]_inst/I}] $sw0_net
reconnect_pin [get_pins -quiet {led_OBUF[1]_inst/I}] $scl_input_net
reconnect_pin [get_pins -quiet {led_OBUF[2]_inst/I}] $sda_input_net
reconnect_pin [get_pins -quiet {led_OBUF[3]_inst/I}] $resetn_net

# Only four already-routed nets gained new sink pins.  Routing the whole design
# can make Vivado 2026.1 rebuild the global route database and has caused an
# access violation on this machine.  UG835 explicitly supports routing a
# selected net list while preserving the existing completed routes.
set eco_nets [list $sw0_net $resetn_net $scl_input_net $sda_input_net]
write_checkpoint -force [file join $output_dir i2c_manual_eco_unrouted.dcp]
route_design -nets $eco_nets

report_timing_summary -file [file join $output_dir timing.rpt]
report_drc -file [file join $output_dir drc.rpt]
report_route_status -file [file join $output_dir route_status.rpt]
report_utilization -file [file join $output_dir utilization.rpt]
write_checkpoint -force [file join $output_dir i2c_manual_eco_routed.dcp]

set worst_path [get_timing_paths -delay_type max -max_paths 1 -nworst 1]
if {[llength $worst_path] == 0} { error "No setup timing path was reported." }
set worst_slack [get_property SLACK [lindex $worst_path 0]]
if {$worst_slack < 0.0} { error "HDMI I2C manual ECO timing failed: WNS=$worst_slack ns" }
set drc_errors [get_drc_violations -quiet -filter {SEVERITY == Error}]
if {[llength $drc_errors] != 0} { error "HDMI I2C manual ECO DRC contains errors." }

set output_bit [file join $output_dir MiniRISC16_HDMI_I2C_ManualTest.bit]
write_bitstream -force $output_bit
puts "HDMI I2C MANUAL ECO BITSTREAM PASS: WNS=$worst_slack ns"
puts "OUTPUT=$output_bit"
puts "RELEASE S1; TOGGLE SW0. L0=SW0, L1=SCL pad, L2=SDA pad, L3=resetn/SDA release."
