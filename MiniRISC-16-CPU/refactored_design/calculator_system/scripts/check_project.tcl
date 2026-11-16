set script_dir [file dirname [info script]]
set design_root [file normalize [file join $script_dir ..]]
set project_file [file join $design_root vivado_project MiniRISC16_Calculator.xpr]

open_project $project_file
reset_run synth_1
launch_runs synth_1 -jobs 1
wait_on_run synth_1
set run_status [get_property STATUS [get_runs synth_1]]
if {![string match "*Complete*" $run_status]} {
    error "Project-mode synthesis failed: $run_status"
}
puts "CALCULATOR PROJECT CHECK PASS: $run_status"
close_project
