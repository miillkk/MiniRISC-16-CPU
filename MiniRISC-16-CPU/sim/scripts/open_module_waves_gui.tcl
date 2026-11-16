# Run from the Vivado Tcl Console after capturing the five module waveforms.
set project_root [file dirname [file dirname [file dirname [file normalize [info script]]]]]
set wave_dir [file join $project_root reports waveforms modules]

foreach tb_name {tb_alu tb_controller tb_datapath tb_reset_conditioner tb_gpio8} {
    set wdb_path [file join $wave_dir $tb_name.wdb]
    set wcfg_path [file join $wave_dir $tb_name.wcfg]
    if {![file exists $wdb_path] || ![file exists $wcfg_path]} {
        error "Missing waveform files for $tb_name in $wave_dir"
    }
    open_wave_database $wdb_path
    open_wave_config $wcfg_path
    puts "MODULE_WAVE_OPENED $tb_name"
}
