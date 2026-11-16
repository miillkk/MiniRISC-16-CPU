set script_dir [file dirname [info script]]
set design_root [file join $script_dir ..]
open_checkpoint [file join $design_root reports diagnostics link_detail link_routed.dcp]

puts "SWITCH0_BEGIN"
foreach cell [get_cells -hier -quiet -filter {NAME =~ *switches*0*}] {
    puts "CELL [get_property NAME $cell] REF=[get_property REF_NAME $cell]"
    foreach pin [get_pins -quiet -of_objects $cell] {
        puts " PIN [get_property NAME $pin] DIR=[get_property DIRECTION $pin] NET=[get_property NAME [get_nets -quiet -of_objects $pin]]"
    }
}
puts "SWITCH0_END"

puts "CONST1_BEGIN"
foreach net [get_nets -hier -quiet -filter {NAME =~ *<const1>*}] {
    puts "NET [get_property NAME $net]"
}
puts "CONST1_END"
