set script_dir [file dirname [info script]]
set_param general.maxThreads 1
if {[info exists ::env(HDMI_SNAKE_ROOT)] && $::env(HDMI_SNAKE_ROOT) ne ""} {
    set design_root $::env(HDMI_SNAKE_ROOT)
} else { set design_root [file join $script_dir ..] }
set synthesis_dir [file join $design_root reports synthesis]
set implementation_dir [file join $design_root reports implementation]
file mkdir $synthesis_dir
file mkdir $implementation_dir
set design_files [list]
foreach pattern [list [file join $design_root rtl core *.v] \
                           [file join $design_root rtl memory *.v] \
                           [file join $design_root rtl peripherals *.v] \
                           [file join $design_root rtl board *.v] \
                           [file join $design_root rtl video *.v] \
                           [file join $design_root rtl top *.v]] {
    foreach file_name [glob -nocomplain $pattern] { lappend design_files $file_name }
}
read_verilog $design_files
read_xdc [file join $design_root constraints EES331_hdmi_snake.xdc]
synth_design -top hdmi_snake_board_top -part xc7z020clg484-1
read_xdc [file join $design_root constraints video_frame_cdc.xdc]
report_utilization -file [file join $synthesis_dir hdmi-snake-synth-utilization.rpt]
report_timing_summary -file [file join $synthesis_dir hdmi-snake-synth-timing.rpt]
write_checkpoint -force [file join $implementation_dir hdmi_snake_synth.dcp]
puts "HDMI SNAKE SYNTHESIS CHECKPOINT PASS"
