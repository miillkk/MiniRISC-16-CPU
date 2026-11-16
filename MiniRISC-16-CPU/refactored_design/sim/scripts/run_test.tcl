set vcd_is_open 0

if {[info exists ::env(MINIRISC_VCD)] && $::env(MINIRISC_VCD) ne ""} {
    if {[catch {
        open_vcd $::env(MINIRISC_VCD)
        log_vcd [get_objects -r /*]
        set vcd_is_open 1
    } message]} {
        puts "WAVEFORM ERROR: VCD setup failed: $message"
    }
}

run all

if {$vcd_is_open} {
    close_vcd
}

quit
