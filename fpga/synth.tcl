set part "xc7a100tcsg324-1"
set top  "fpga_top"

# Read sources IN ORDER (package must be first)
read_verilog -sv [glob rtl/backend/*]
read_verilog -sv [glob rtl/common/*]
read_verilog -sv [glob rtl/control/*]
read_verilog -sv [glob rtl/core/*]
read_verilog -sv [glob rtl/frontend/*]
read_verilog -sv [glob rtl/memory/*]

# read_verilog -sv [glob rtl/csr/*]
# read_verilog -sv [glob rtl/interfaces/*]

read_verilog -sv fpga/fpga_top.sv
read_xdc     fpga/constraints.xdc

# Add SYNTHESIS define to guard sim-only code
set_property verilog_define SYNTHESIS [current_fileset]

synth_design -top $top -part $part \
    -flatten_hierarchy rebuilt \
    -fsm_extraction one_hot

opt_design
place_design
route_design

write_bitstream -force adiriscv_nexys_a7.bit