## Arty A7-100T Constraints for AdiRiscV

# Clock and Reset
## Clock signal (100 MHz)
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { clk }];
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { clk }];

## Reset button (active low)
set_property -dict { PACKAGE_PIN C2    IOSTANDARD LVCMOS33 } [get_ports { reset_n }];

# LEDs (status/debug output)
set_property -dict { PACKAGE_PIN H5    IOSTANDARD LVCMOS33 } [get_ports { led[0] }];
set_property -dict { PACKAGE_PIN J5    IOSTANDARD LVCMOS33 } [get_ports { led[1] }];
set_property -dict { PACKAGE_PIN T9    IOSTANDARD LVCMOS33 } [get_ports { led[2] }];
set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33 } [get_ports { led[3] }];

# RGB LEDs (pipeline stage status)
set_property -dict { PACKAGE_PIN G6    IOSTANDARD LVCMOS33 } [get_ports { led_r[0] }];
set_property -dict { PACKAGE_PIN F6    IOSTANDARD LVCMOS33 } [get_ports { led_g[0] }];
set_property -dict { PACKAGE_PIN E1    IOSTANDARD LVCMOS33 } [get_ports { led_b[0] }];

set_property -dict { PACKAGE_PIN G3    IOSTANDARD LVCMOS33 } [get_ports { led_r[1] }];
set_property -dict { PACKAGE_PIN J4    IOSTANDARD LVCMOS33 } [get_ports { led_g[1] }];
set_property -dict { PACKAGE_PIN G4    IOSTANDARD LVCMOS33 } [get_ports { led_b[1] }];

# Switches (control/input)
set_property -dict { PACKAGE_PIN A8    IOSTANDARD LVCMOS33 } [get_ports { sw[0] }];
set_property -dict { PACKAGE_PIN C11   IOSTANDARD LVCMOS33 } [get_ports { sw[1] }];
set_property -dict { PACKAGE_PIN C10   IOSTANDARD LVCMOS33 } [get_ports { sw[2] }];
set_property -dict { PACKAGE_PIN A10   IOSTANDARD LVCMOS33 } [get_ports { sw[3] }];


# Buttons
set_property -dict { PACKAGE_PIN D9    IOSTANDARD LVCMOS33 } [get_ports { btn[0] }];
set_property -dict { PACKAGE_PIN C9    IOSTANDARD LVCMOS33 } [get_ports { btn[1] }];
set_property -dict { PACKAGE_PIN B9    IOSTANDARD LVCMOS33 } [get_ports { btn[2] }];
set_property -dict { PACKAGE_PIN B8    IOSTANDARD LVCMOS33 } [get_ports { btn[3] }];


# UART (external communication)
set_property -dict { PACKAGE_PIN D10   IOSTANDARD LVCMOS33 } [get_ports { uart_rxd }];
set_property -dict { PACKAGE_PIN A9    IOSTANDARD LVCMOS33 } [get_ports { uart_txd }];


# Timing Constraints

## Input delays for external inputs (relative to clock)
set_input_delay -clock [get_clocks sys_clk_pin] -min 2.0 [get_ports {reset_n btn[*] sw[*]}]
set_input_delay -clock [get_clocks sys_clk_pin] -max 5.0 [get_ports {reset_n btn[*] sw[*]}]

## Output delays for external outputs
set_output_delay -clock [get_clocks sys_clk_pin] -min -1.0 [get_ports {led[*] led_r[*] led_g[*] led_b[*]}]
set_output_delay -clock [get_clocks sys_clk_pin] -max 5.0 [get_ports {led[*] led_r[*] led_g[*] led_b[*]}]

## UART timing
set_input_delay -clock [get_clocks sys_clk_pin] 2.0 [get_ports uart_rxd]
set_output_delay -clock [get_clocks sys_clk_pin] 2.0 [get_ports uart_txd]

## Maximum delay constraints for critical paths
set_max_delay -from [all_inputs] -to [all_outputs] 15.0

# Memory Configuration

# set_property RAM_STYLE block [get_cells -hierarchical -filter {NAME =~ "*imem_inst/imem*"}]
# set_property RAM_STYLE block [get_cells -hierarchical -filter {NAME =~ "*dmem_inst/mem*"}]

## Register file implementation
# set_property RAM_STYLE distributed [get_cells -hierarchical -filter {NAME =~ "*regfile_inst/registers*"}]


# Additional Optimization Constraints

## False path from reset to all registers (async reset)
set_false_path -from [get_ports reset_n] -to [all_registers]

## Multicycle paths for division operations (33 cycles)
# set_multicycle_path -setup 33 -from [get_pins -hierarchical -filter {NAME =~ "*divider_inst/state_reg*/C"}] -to [get_pins -hierarchical -filter {NAME =~ "*divider_inst/*"}]
# set_multicycle_path -hold 32 -from [get_pins -hierarchical -filter {NAME =~ "*divider_inst/state_reg*/C"}] -to [get_pins -hierarchical -filter {NAME =~ "*divider_inst/*"}]


# Configuration Settings
## Bitstream generation
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]

## safety settings
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]