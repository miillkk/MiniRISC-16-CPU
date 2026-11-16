## EES331 v1.0, xc7z020clg484-1, PL banks at 3.3 V.
## Verified board mapping reused by the isolated calculator system.

set_property PACKAGE_PIN M19 [get_ports clk_100mhz]
set_property IOSTANDARD LVCMOS33 [get_ports clk_100mhz]
create_clock -name clk_100mhz -period 10.000 [get_ports clk_100mhz]

## S1 active-low PL reset button.
## The legacy port name resetn is retained so the verified pin mapping remains stable.
set_property PACKAGE_PIN L18 [get_ports resetn]
set_property IOSTANDARD LVCMOS33 [get_ports resetn]

## PL UART through the upper J8 USB connector (CP2103), 115200 8N1.
set_property PACKAGE_PIN A16 [get_ports uart_rx]
set_property PACKAGE_PIN A17 [get_ports uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports {uart_rx uart_tx}]

set_property PACKAGE_PIN AB6 [get_ports {switches[0]}]
set_property PACKAGE_PIN Y4  [get_ports {switches[1]}]
set_property PACKAGE_PIN AA4 [get_ports {switches[2]}]
set_property PACKAGE_PIN R6  [get_ports {switches[3]}]
set_property PACKAGE_PIN T6  [get_ports {switches[4]}]
set_property PACKAGE_PIN T4  [get_ports {switches[5]}]
set_property PACKAGE_PIN U4  [get_ports {switches[6]}]
set_property PACKAGE_PIN V5  [get_ports {switches[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {switches[*]}]

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

set_property PACKAGE_PIN R21 [get_ports {seg_low[0]}]
set_property PACKAGE_PIN P20 [get_ports {seg_low[1]}]
set_property PACKAGE_PIN P21 [get_ports {seg_low[2]}]
set_property PACKAGE_PIN N15 [get_ports {seg_low[3]}]
set_property PACKAGE_PIN P15 [get_ports {seg_low[4]}]
set_property PACKAGE_PIN P17 [get_ports {seg_low[5]}]
set_property PACKAGE_PIN P18 [get_ports {seg_low[6]}]
set_property PACKAGE_PIN T16 [get_ports {seg_low[7]}]

set_property PACKAGE_PIN T17 [get_ports {seg_high[0]}]
set_property PACKAGE_PIN R19 [get_ports {seg_high[1]}]
set_property PACKAGE_PIN T19 [get_ports {seg_high[2]}]
set_property PACKAGE_PIN R18 [get_ports {seg_high[3]}]
set_property PACKAGE_PIN T18 [get_ports {seg_high[4]}]
set_property PACKAGE_PIN P16 [get_ports {seg_high[5]}]
set_property PACKAGE_PIN R16 [get_ports {seg_high[6]}]
set_property PACKAGE_PIN R15 [get_ports {seg_high[7]}]

set_property PACKAGE_PIN M20 [get_ports {digit_enable[0]}]
set_property PACKAGE_PIN N19 [get_ports {digit_enable[1]}]
set_property PACKAGE_PIN N20 [get_ports {digit_enable[2]}]
set_property PACKAGE_PIN M21 [get_ports {digit_enable[3]}]
set_property PACKAGE_PIN M22 [get_ports {digit_enable[4]}]
set_property PACKAGE_PIN N22 [get_ports {digit_enable[5]}]
set_property PACKAGE_PIN P22 [get_ports {digit_enable[6]}]
set_property PACKAGE_PIN R20 [get_ports {digit_enable[7]}]

set_property IOSTANDARD LVCMOS33 [get_ports {seg_low[*] seg_high[*] digit_enable[*]}]
set_property DRIVE 8 [get_ports {seg_low[*] seg_high[*] digit_enable[*]}]
set_property SLEW SLOW [get_ports {seg_low[*] seg_high[*] digit_enable[*]}]

## Human-operated asynchronous inputs and human-visible display outputs do not
## participate in a source-synchronous board interface. The synchronizer's
## internal stage-to-stage paths remain timed by clk_100mhz.
set_false_path -from [get_ports {resetn switches[*] uart_rx}]
set_false_path -to [get_ports {led[*] seg_low[*] seg_high[*] digit_enable[*] uart_tx}]
