set script_dir [file dirname [info script]]
set_param general.maxThreads 1
set design_root [file join $script_dir ..]
set source_checkpoint [file join $design_root reports implementation hdmi_snake_routed.dcp]
set output_dir [file join $design_root reports diagnostics i2c_electrical_eco]
file mkdir $output_dir

open_checkpoint $source_checkpoint

set half_tick_net [get_nets -quiet {u_runtime_soc/u_peripheral_subsystem/u_tick_timer/half_tick}]
set half_tick_ce_pin [get_pins -quiet {u_runtime_soc/u_peripheral_subsystem/u_tick_timer/half_tick_reg/CE}]
set const1_net [get_nets -quiet -of_objects $half_tick_ce_pin]
set scl_t_pin [get_pins -quiet {iic_scl_hdmi_IOBUF_inst/T}]
set sda_t_pin [get_pins -quiet {iic_sda_hdmi_IOBUF_inst/T}]
set scl_i_pin [get_pins -quiet {iic_scl_hdmi_IOBUF_inst/O}]
set sda_i_pin [get_pins -quiet {iic_sda_hdmi_IOBUF_inst/O}]
set scl_input_net [get_nets -quiet -of_objects $scl_i_pin]
set sda_input_net [get_nets -quiet -of_objects $sda_i_pin]
set const0_net [get_nets -quiet -of_objects [get_pins -quiet {iic_scl_hdmi_IOBUF_inst/I}]]

foreach item [list $half_tick_net $const1_net $scl_t_pin $sda_t_pin $scl_input_net $sda_input_net $const0_net] {
    if {[llength $item] != 1} { error "Electrical-test ECO could not resolve a unique required object." }
}

proc reconnect_pin {pin new_net} {
    set old_net [get_nets -quiet -of_objects $pin]
    if {[llength $old_net] == 1} {
        disconnect_net -net $old_net -objects $pin
    }
    connect_net -hierarchical -net $new_net -objects $pin
}

# half_tick=0 drives SCL low; half_tick=1 releases it. SDA is always released.
reconnect_pin $scl_t_pin $half_tick_net
reconnect_pin $sda_t_pin $const1_net

# L0=release command, L1=sampled SCL, L2=sampled SDA, L3 forced off.
reconnect_pin [get_pins -quiet {led_OBUF[0]_inst/I}] $half_tick_net
reconnect_pin [get_pins -quiet {led_OBUF[1]_inst/I}] $scl_input_net
reconnect_pin [get_pins -quiet {led_OBUF[2]_inst/I}] $sda_input_net
reconnect_pin [get_pins -quiet {led_OBUF[3]_inst/I}] $const0_net

route_design -preserve

report_timing_summary -file [file join $output_dir timing.rpt]
report_drc -file [file join $output_dir drc.rpt]
report_route_status -file [file join $output_dir route_status.rpt]
report_utilization -file [file join $output_dir utilization.rpt]
write_checkpoint -force [file join $output_dir i2c_electrical_eco_routed.dcp]

set worst_path [get_timing_paths -delay_type max -max_paths 1 -nworst 1]
if {[llength $worst_path] == 0} { error "No setup timing path was reported." }
set worst_slack [get_property SLACK [lindex $worst_path 0]]
if {$worst_slack < 0.0} { error "HDMI I2C electrical ECO timing failed: WNS=$worst_slack ns" }
set drc_errors [get_drc_violations -quiet -filter {SEVERITY == Error}]
if {[llength $drc_errors] != 0} { error "HDMI I2C electrical ECO DRC contains errors." }

set output_bit [file join $output_dir MiniRISC16_HDMI_I2C_ElectricalTest.bit]
write_bitstream -force $output_bit
puts "HDMI I2C ELECTRICAL ECO BITSTREAM PASS: WNS=$worst_slack ns"
puts "OUTPUT=$output_bit"
puts "L0=release command, L1=sampled SCL, L2=sampled SDA"
