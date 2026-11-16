## EES331 HDMI-I2C electrical diagnostic. No internal pull-up is enabled:
## this deliberately tests the board's R110/R140 2.2 kOhm pull-ups.

set_property PACKAGE_PIN M19 [get_ports clk_100mhz]
set_property IOSTANDARD LVCMOS33 [get_ports clk_100mhz]
create_clock -name clk_100mhz -period 10.000 [get_ports clk_100mhz]

set_property PACKAGE_PIN L18 [get_ports resetn]
set_property IOSTANDARD LVCMOS33 [get_ports resetn]

set_property PACKAGE_PIN V4 [get_ports {led[0]}]
set_property PACKAGE_PIN U6 [get_ports {led[1]}]
set_property PACKAGE_PIN U5 [get_ports {led[2]}]
set_property PACKAGE_PIN V7 [get_ports {led[3]}]
set_property PACKAGE_PIN W7 [get_ports {led[4]}]
set_property PACKAGE_PIN W6 [get_ports {led[5]}]
set_property PACKAGE_PIN W5 [get_ports {led[6]}]
set_property PACKAGE_PIN U7 [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]
set_property DRIVE 8 [get_ports {led[*]}]
set_property SLEW SLOW [get_ports {led[*]}]

set_property PACKAGE_PIN AB10 [get_ports iic_scl_hdmi]
set_property PACKAGE_PIN AB9  [get_ports iic_sda_hdmi]
set_property IOSTANDARD LVCMOS33 [get_ports {iic_scl_hdmi iic_sda_hdmi}]
