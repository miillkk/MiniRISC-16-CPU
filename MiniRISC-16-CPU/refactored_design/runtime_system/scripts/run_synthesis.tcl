set script_dir [file dirname [info script]]
set_param general.maxThreads 1
if {[info exists ::env(RUNTIME_SYSTEM_ROOT)] && $::env(RUNTIME_SYSTEM_ROOT) ne ""} {
    set design_root $::env(RUNTIME_SYSTEM_ROOT)
} else { set design_root [file join $script_dir ..] }
set report_dir [file join $design_root reports synthesis]
file mkdir $report_dir
set design_files [list]
foreach pattern [list [file join $design_root rtl core *.v] \
                           [file join $design_root rtl memory *.v] \
                           [file join $design_root rtl peripherals *.v] \
                           [file join $design_root rtl board *.v] \
                           [file join $design_root rtl top *.v]] {
    foreach file_name [glob -nocomplain $pattern] { lappend design_files $file_name }
}
read_verilog $design_files
read_xdc [file join $design_root constraints EES331_runtime.xdc]
synth_design -top runtime_board_top -part xc7z020clg484-1
report_utilization -file [file join $report_dir runtime-synthesis-utilization.rpt]
report_timing_summary -file [file join $report_dir runtime-synthesis-timing.rpt]
write_checkpoint -force [file join $report_dir runtime_synth.dcp]
puts "RUNTIME SYNTHESIS PASS"
