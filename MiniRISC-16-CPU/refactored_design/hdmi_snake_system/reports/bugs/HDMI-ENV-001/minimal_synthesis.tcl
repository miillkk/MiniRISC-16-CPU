set_param general.maxThreads 1
set here [file dirname [info script]]
read_verilog [file join $here minimal_top.v]
synth_design -top minimal_top -part xc7z020clg484-1
report_utilization -file [file join $here minimal_utilization.rpt]
puts "MINIMAL SYNTHESIS PASS"
