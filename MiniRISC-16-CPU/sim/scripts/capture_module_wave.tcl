# Capture one existing module testbench without changing the Vivado project.
set tb_name $::env(MINIRISC_MODULE_TB)
set wcfg_path $::env(MINIRISC_MODULE_WCFG)
set vcd_path $::env(MINIRISC_MODULE_VCD)

create_wave_config $tb_name
add_wave -r [get_objects -r /$tb_name/*]
log_wave -r [get_objects -r /$tb_name/*]
save_wave_config $wcfg_path

open_vcd $vcd_path
log_vcd [get_objects -r /$tb_name/*]

run all
close_vcd
quit
