# Source this in the Vivado Tcl Console to inspect all nine views of the
# same tb_system execution. The final selected tab is the GPIO view.
set project_root [file dirname [file dirname [file dirname [file normalize [info script]]]]]
set wave_dir [file join $project_root reports waveforms cycle_views]
set wdb_path [file join $wave_dir tb_system_cycle.wdb]
if {![file exists $wdb_path]} {
    error "Missing cycle waveform database: $wdb_path"
}
open_wave_database $wdb_path
foreach view_name {
    system_top instruction_memory cpu_core controller datapath
    register_file alu reset gpio
} {
    set wcfg_path [file join $wave_dir ${view_name}_cycle.wcfg]
    if {![file exists $wcfg_path]} {
        error "Missing cycle waveform configuration: $wcfg_path"
    }
    open_wave_config $wcfg_path
    puts "CYCLE_VIEW_OPENED $view_name"
}
