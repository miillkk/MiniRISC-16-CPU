set_param general.maxThreads 1
set root [file normalize [file join [file dirname [info script]] ../../..]]
set game [file join $root games chess]
set output [file join $game reports]
file mkdir $output
create_project -in_memory -part xc7z020clg484-1
set overrides {program_counter next_pc_mux cpu_core datapath runtime_soc program_loader runtime_program_memory runtime_board_top}
foreach dir {core memory peripherals board top} {
    foreach f [glob [file join $root rtl $dir *.v]] {
        if {[lsearch -exact $overrides [file rootname [file tail $f]]] < 0} {read_verilog $f}
    }
}
foreach f [glob [file join $game hardware *.v]] {if {![string match tb_* [file tail $f]]} {read_verilog $f}}
read_xdc [file join $root constraints EES331_runtime.xdc]
synth_design -top runtime_board_top -part xc7z020clg484-1
write_checkpoint -force [file join $output chess4k_synth.dcp]
opt_design
place_design
phys_opt_design
route_design
report_timing_summary -file [file join $output timing.rpt]
report_utilization -file [file join $output utilization.rpt]
report_drc -file [file join $output drc.rpt]
write_checkpoint -force [file join $output chess4k_routed.dcp]
set worst [get_timing_paths -delay_type max -max_paths 1]
if {[llength $worst] == 0 || [get_property SLACK $worst] < 0} {error "Timing failed; bitstream not released"}
set hold [get_timing_paths -delay_type min -max_paths 1]
if {[llength $hold] == 0 || [get_property SLACK $hold] < 0} {error "Hold timing failed; bitstream not released"}
write_bitstream -force [file join $output MiniRISC16_Arcade4K.bit]
puts "CHESS 4K BITSTREAM PASS"



