set script_dir [file dirname [info script]]
set design_root [file join $script_dir ..]
set checkpoint [file join $design_root reports implementation hdmi_snake_timing_closed.dcp]
open_checkpoint $checkpoint

puts "HALF_TICK_CELLS_BEGIN"
foreach cell [get_cells -hier -quiet -filter {NAME =~ *half_tick*}] {
    puts "CELL [get_property NAME $cell] REF=[get_property REF_NAME $cell]"
    foreach pin [get_pins -quiet -of_objects $cell] {
        puts " PIN [get_property NAME $pin] DIR=[get_property DIRECTION $pin] NET=[get_property NAME [get_nets -quiet -of_objects $pin]]"
    }
}
puts "HALF_TICK_CELLS_END"

puts "HALF_TICK_NETS_BEGIN"
foreach net [get_nets -hier -quiet -filter {NAME =~ *half_tick*}] {
    puts "NET [get_property NAME $net]"
}
puts "HALF_TICK_NETS_END"

puts "I2C_IOBUF_BEGIN"
foreach cell [get_cells -hier -quiet -filter {NAME =~ iic_scl_hdmi_IOBUF_inst || NAME =~ iic_sda_hdmi_IOBUF_inst}] {
    puts "CELL [get_property NAME $cell] REF=[get_property REF_NAME $cell]"
    foreach pin [get_pins -quiet -of_objects $cell] {
        puts " PIN [get_property NAME $pin] DIR=[get_property DIRECTION $pin] NET=[get_property NAME [get_nets -quiet -of_objects $pin]]"
    }
}
puts "I2C_IOBUF_END"

puts "LED_IOBUF_BEGIN"
foreach cell [get_cells -quiet {led_OBUF[0]_inst led_OBUF[1]_inst led_OBUF[2]_inst led_OBUF[3]_inst}] {
    puts "CELL [get_property NAME $cell]"
    foreach pin [get_pins -quiet -of_objects $cell] {
        puts " PIN [get_property NAME $pin] DIR=[get_property DIRECTION $pin] NET=[get_property NAME [get_nets -quiet -of_objects $pin]]"
    }
}
puts "LED_IOBUF_END"
