set script_dir [file dirname [info script]]
if {[info exists ::env(HDMI_SNAKE_ROOT)] && $::env(HDMI_SNAKE_ROOT) ne ""} {
    set design_root $::env(HDMI_SNAKE_ROOT)
} else { set design_root [file join $script_dir ..] }
set checkpoint [file join $design_root reports diagnostics link_detail link_routed.dcp]
open_checkpoint $checkpoint
puts "CHECKPOINT=$checkpoint"
puts "SCL_LOW_NETS_BEGIN"
foreach item [get_nets -hier -quiet -filter {NAME =~ *scl_low*}] { puts [get_property NAME $item] }
puts "SCL_LOW_NETS_END"
puts "LED0_CELLS_BEGIN"
foreach item [get_cells -hier -quiet -filter {NAME =~ *led_OBUF*}] { puts "[get_property NAME $item] [get_property REF_NAME $item]" }
puts "LED0_CELLS_END"
puts "LED0_NETS_BEGIN"
foreach item [get_nets -hier -quiet -of_objects [get_ports {led[0]}]] { puts [get_property NAME $item] }
puts "LED0_NETS_END"
puts "SCL_LOW_DETAIL_BEGIN"
foreach net [get_nets -hier -quiet -filter {NAME =~ *scl_low3_out}] {
    puts "NET [get_property NAME $net]"
    foreach pin [get_pins -quiet -of_objects $net] {
        puts "PIN [get_property NAME $pin] DIR=[get_property DIRECTION $pin] REF=[get_property REF_PIN_NAME $pin]"
    }
}
puts "SCL_LOW_DETAIL_END"
puts "LED0_INPUT_DETAIL_BEGIN"
set led0 [get_cells -quiet {led_OBUF[0]_inst}]
foreach pin [get_pins -quiet -of_objects $led0] {
    puts "PIN [get_property NAME $pin] DIR=[get_property DIRECTION $pin] NET=[get_property NAME [get_nets -quiet -of_objects $pin]]"
}
puts "LED0_INPUT_DETAIL_END"
puts "SCL_IOBUF_DETAIL_BEGIN"
foreach cell [get_cells -hier -quiet -filter {NAME =~ *iic_scl_hdmi*}] {
    puts "CELL [get_property NAME $cell] REF=[get_property REF_NAME $cell]"
    foreach pin [get_pins -quiet -of_objects $cell] {
        puts "PIN [get_property NAME $pin] DIR=[get_property DIRECTION $pin] NET=[get_property NAME [get_nets -quiet -of_objects $pin]]"
    }
}
puts "SCL_IOBUF_DETAIL_END"
puts "SCL_TRI_DETAIL_BEGIN"
set scl_tri [get_nets -quiet {iic_scl_hdmi_TRI}]
foreach pin [get_pins -quiet -of_objects $scl_tri] {
    puts "PIN [get_property NAME $pin] DIR=[get_property DIRECTION $pin] NET=[get_property NAME [get_nets -quiet -of_objects $pin]]"
}
puts "SCL_TRI_DETAIL_END"
