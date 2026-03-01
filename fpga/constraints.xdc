## Nexys A7-100T Constraints

# Clock (100 MHz on E3)
set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -name sys_clk -period 10.000 [get_ports clk]

# Reset - CPU Reset button (C12, active LOW)
set_property -dict { PACKAGE_PIN C12 IOSTANDARD LVCMOS33 } [get_ports reset_n]

# LEDs (T14, T15, L1, M1, H17, H18 — 16 LEDs on Nexys A7)
set_property -dict { PACKAGE_PIN H17 IOSTANDARD LVCMOS33 } [get_ports {led[0]}]
set_property -dict { PACKAGE_PIN K15 IOSTANDARD LVCMOS33 } [get_ports {led[1]}]
set_property -dict { PACKAGE_PIN J13 IOSTANDARD LVCMOS33 } [get_ports {led[2]}]
set_property -dict { PACKAGE_PIN N14 IOSTANDARD LVCMOS33 } [get_ports {led[3]}]

# Switches (J15, L16, M13, R15 — 16 switches on Nexys A7)
set_property -dict { PACKAGE_PIN J15 IOSTANDARD LVCMOS33 } [get_ports {sw[0]}]
set_property -dict { PACKAGE_PIN L16 IOSTANDARD LVCMOS33 } [get_ports {sw[1]}]
set_property -dict { PACKAGE_PIN M13 IOSTANDARD LVCMOS33 } [get_ports {sw[2]}]
set_property -dict { PACKAGE_PIN R15 IOSTANDARD LVCMOS33 } [get_ports {sw[3]}]

# Buttons (BTNC=N17, BTNU=M18, BTNL=P17, BTNR=M17, BTND=P18)
set_property -dict { PACKAGE_PIN N17 IOSTANDARD LVCMOS33 } [get_ports {btn[0]}]
set_property -dict { PACKAGE_PIN M18 IOSTANDARD LVCMOS33 } [get_ports {btn[1]}]

# UART (USB-UART via FTDI — C4=TX to host, D4=RX from host)
set_property -dict { PACKAGE_PIN C4 IOSTANDARD LVCMOS33 } [get_ports uart_txd]
set_property -dict { PACKAGE_PIN D4 IOSTANDARD LVCMOS33 } [get_ports uart_rxd]

# Timing
set_false_path -from [get_ports reset_n]
set_input_delay  -clock sys_clk -max 5.0 [get_ports {sw[*] btn[*]}]
set_output_delay -clock sys_clk -max 5.0 [get_ports {led[*]}]

# Bitstream config
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]