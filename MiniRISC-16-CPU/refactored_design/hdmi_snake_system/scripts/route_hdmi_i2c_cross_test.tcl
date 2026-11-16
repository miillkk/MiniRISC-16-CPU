set script_dir [file dirname [info script]]
set_param general.maxThreads 1
set design_root [file join $script_dir ..]
set output_dir [file join $design_root reports diagnostics i2c_cross_test]

open_checkpoint [file join $output_dir i2c_cross_placed.dcp]
reset_timing
read_xdc [file join $design_root constraints EES331_hdmi_i2c_electrical_test.xdc]
route_design -directive Quick

report_route_status -file [file join $output_dir route_status.rpt]
write_checkpoint -force [file join $output_dir i2c_cross_routed.dcp]
report_drc -file [file join $output_dir drc.rpt]
report_utilization -file [file join $output_dir utilization.rpt]

set drc_errors [get_drc_violations -quiet -filter {SEVERITY == Error}]
if {[llength $drc_errors] != 0} { error "HDMI I2C cross test DRC contains errors." }
set unrouted [get_nets -quiet -filter {ROUTE_STATUS == UNROUTED || ROUTE_STATUS == PARTIAL}]
if {[llength $unrouted] != 0} { error "HDMI I2C cross test has [llength $unrouted] unrouted nets." }

set output_bit [file join $output_dir MiniRISC16_HDMI_I2C_CrossTest.bit]
write_bitstream -force $output_bit
report_timing_summary -file [file join $output_dir timing.rpt]

puts "HDMI I2C CROSS TEST BITSTREAM PASS"
puts "OUTPUT=$output_bit"
puts "LED7..6=phase; LED3..0={SDA pad,SDA release,SCL pad,SCL release}"
