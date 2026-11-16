if {[info exists ::env(SNAKE_VCD)] && $::env(SNAKE_VCD) ne ""} {
    open_vcd $::env(SNAKE_VCD)
    log_vcd *
}
run all
if {[info exists ::env(SNAKE_VCD)] && $::env(SNAKE_VCD) ne ""} { close_vcd }
quit
