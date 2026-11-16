set script_dir [file dirname [info script]]
set_param general.maxThreads 1
set design_root [file join $script_dir ..]
set output_dir [file join $design_root reports diagnostics i2c_cross_test]
file mkdir $output_dir

read_verilog [file join $design_root rtl board reset_conditioner.v]
read_verilog [file join $design_root rtl top hdmi_i2c_cross_test_top.v]
read_xdc [file join $design_root constraints EES331_hdmi_i2c_electrical_test.xdc]

synth_design -top hdmi_i2c_cross_test_top -part xc7z020clg484-1
write_checkpoint -force [file join $output_dir i2c_cross_synth.dcp]
opt_design
write_checkpoint -force [file join $output_dir i2c_cross_opt.dcp]
place_design
write_checkpoint -force [file join $output_dir i2c_cross_placed.dcp]

puts "HDMI I2C CROSS TEST PLACED CHECKPOINT PASS"
puts "OUTPUT=[file join $output_dir i2c_cross_placed.dcp]"

