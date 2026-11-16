set script_dir [file dirname [file normalize [info script]]]
set wave_root [file normalize [file join $script_dir ..]]
set project_file [file join $wave_root project instruction_waveforms_project.xpr]
set wave_db [file join $wave_root output move.wdb]
set wave_cfg [file join $wave_root output move.wcfg]

open_project $project_file
open_wave_database $wave_db
open_wave_config $wave_cfg

puts "OPEN_WAVE_READY: move"
