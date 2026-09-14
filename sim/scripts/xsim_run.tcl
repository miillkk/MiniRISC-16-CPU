set vcd_is_open 0

if {[info exists ::env(MINIRISC_VCD)] && $::env(MINIRISC_VCD) ne ""} {
    if {[catch {
        open_vcd $::env(MINIRISC_VCD)
        log_vcd [get_objects -r /tb_system/*]
        set vcd_is_open 1
    } message]} {
        puts "WAVEFORM ERROR: VCD setup failed: $message"
    }
}

if {[info exists ::env(MINIRISC_WCFG)] && $::env(MINIRISC_WCFG) ne ""} {
    if {[catch {
        create_wave_config minirisc16_system
        add_wave -r /tb_system/*
        save_wave_config $::env(MINIRISC_WCFG)
    } message]} {
        puts "WAVEFORM ERROR: WCFG setup failed: $message"
    }
}

run all

if {$vcd_is_open} {
    close_vcd
}

quit
