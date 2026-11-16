if {[info exists ::env(RUNTIME_VCD)] && $::env(RUNTIME_VCD) ne ""} {
    open_vcd $::env(RUNTIME_VCD)
    log_vcd *
}
run all
if {[info exists ::env(RUNTIME_VCD)] && $::env(RUNTIME_VCD) ne ""} { close_vcd }
quit
