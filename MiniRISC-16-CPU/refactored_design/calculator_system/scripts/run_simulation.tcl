if {[info exists ::env(CALCULATOR_VCD)] && $::env(CALCULATOR_VCD) ne ""} {
    open_vcd $::env(CALCULATOR_VCD)
    log_vcd *
}
run all
if {[info exists ::env(CALCULATOR_VCD)] && $::env(CALCULATOR_VCD) ne ""} {
    close_vcd
}
quit
