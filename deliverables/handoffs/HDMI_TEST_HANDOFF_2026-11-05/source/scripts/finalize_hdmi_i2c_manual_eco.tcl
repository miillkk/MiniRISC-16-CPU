set script_dir [file dirname [info script]]
set_param general.maxThreads 1
set design_root [file join $script_dir ..]
set output_dir [file join $design_root reports diagnostics i2c_manual_eco]
set input_checkpoint [file join $output_dir i2c_manual_eco_unrouted.dcp]

open_checkpoint $input_checkpoint

set eco_nets [get_nets -quiet [list \
    {switches_IBUF[0]} \
    {resetn_IBUF} \
    {iic_scl_hdmi_IBUF} \
    {iic_sda_hdmi_IBUF}]]
if {[llength $eco_nets] != 4} {
    error "Expected four HDMI I2C manual-test ECO nets, found [llength $eco_nets]."
}

# Route only the four nets that gained new sink pins.  All unrelated routing in
# the source checkpoint remains untouched.
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
