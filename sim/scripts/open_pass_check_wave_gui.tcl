set project_root [file normalize [file join [file dirname [info script]] ../..]]
set wdb_path [file join $project_root sim build tb_system tb_system_sim.wdb]
if {[info exists ::env(MINIRISC_GUI_WCFG)] && $::env(MINIRISC_GUI_WCFG) ne ""} {
    set wcfg_path [file normalize $::env(MINIRISC_GUI_WCFG)]
} else {
    set wcfg_path [file join $project_root reports waveforms system_pass_check.wcfg]
}

if {![file exists $wdb_path]} {
    error "Wave database not found: $wdb_path"
}
if {![file exists $wcfg_path]} {
    error "Wave configuration not found: $wcfg_path"
}

open_wave_database $wdb_path
open_wave_config $wcfg_path
