set script_dir [file dirname [info script]]
set_param general.maxThreads 1
set design_root [file join $script_dir ..]
set output_dir [file join $design_root reports diagnostics i2c_electrical]

open_checkpoint [file join $output_dir i2c_electrical_synth.dcp]
opt_design
write_checkpoint -force [file join $output_dir i2c_electrical_opt.dcp]
place_design
write_checkpoint -force [file join $output_dir i2c_electrical_placed.dcp]
route_design

report_timing_summary -file [file join $output_dir timing.rpt]
report_drc -file [file join $output_dir drc.rpt]
report_route_status -file [file join $output_dir route_status.rpt]
report_utilization -file [file join $output_dir utilization.rpt]
write_checkpoint -force [file join $output_dir i2c_electrical_routed.dcp]

set worst_path [get_timing_paths -delay_type max -max_paths 1 -nworst 1]
if {[llength $worst_path] == 0} { error "No setup timing path was reported." }
set worst_slack [get_property SLACK [lindex $worst_path 0]]
if {$worst_slack < 0.0} { error "HDMI I2C electrical test timing failed: WNS=$worst_slack ns" }
set drc_errors [get_drc_violations -quiet -filter {SEVERITY == Error}]
if {[llength $drc_errors] != 0} { error "HDMI I2C electrical test DRC contains errors." }

set output_bit [file join $output_dir MiniRISC16_HDMI_I2C_ElectricalTest.bit]
write_bitstream -force $output_bit
puts "HDMI I2C ELECTRICAL TEST BITSTREAM PASS: WNS=$worst_slack ns"
puts "OUTPUT=$output_bit"
puts "RELEASE: L2,L1,L0 ON; DRIVE-LOW: L3,L2 ON"
