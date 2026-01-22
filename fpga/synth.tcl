#!/usr/bin/tclsh
# Simplified AdiRiscV FPGA Synthesis Script
# This version is optimized to avoid getting stuck

# Configuration
set project_name "adiriscv_fpga"
set top_module "fpga_top"
set part "xc7a100tcsg324-1"

# Create build directory
file mkdir build
cd build

puts "\n========================================="
puts "AdiRiscV FPGA Synthesis"
puts "Target: Arty A7-100T"
puts "=========================================\n"

# Read all RTL files
puts "Reading RTL files..."

set rtl_files [list \
    ../rtl/core/riscv_pkg.sv \
    ../rtl/frontend/fetch/pc.sv \
    ../rtl/frontend/fetch/imem.sv \
    ../rtl/frontend/fetch/if_stage.sv \
    ../rtl/frontend/decode/imm_gen.sv \
    ../rtl/frontend/decode/regfile.sv \
    ../rtl/frontend/decode/decoder.sv \
    ../rtl/frontend/decode/id_stage.sv \
    ../rtl/backend/execute/alu.sv \
    ../rtl/backend/execute/divider.sv \
    ../rtl/backend/execute/branch_unit.sv \
    ../rtl/backend/execute/ex_stage.sv \
    ../rtl/backend/memory/dmem.sv \
    ../rtl/backend/memory/mem_stage.sv \
    ../rtl/backend/writeback/wb_stage.sv \
    ../rtl/pipeline/if_id_reg.sv \
    ../rtl/pipeline/id_ex_reg.sv \
    ../rtl/pipeline/ex_mem_reg.sv \
    ../rtl/pipeline/mem_wb_reg.sv \
    ../rtl/pipeline/forwarding_unit.sv \
    ../rtl/pipeline/hazard_unit.sv \
    ../rtl/core/riscv_pipelined_core.sv \
    ../fpga/fpga_top.sv \
]

foreach file $rtl_files {
    if {[file exists $file]} {
        read_verilog -sv $file
        puts "  Added: $file"
    } else {
        puts "  WARNING: Not found: $file"
    }
}

# Read constraints (basic timing only)
puts "\nReading constraints..."
if {[file exists ../fpga/constraints.xdc]} {
    read_xdc ../fpga/constraints.xdc
    puts "  Added: constraints.xdc"
}

# Synthesis with simpler options
puts "\n========================================="
puts "Starting Synthesis..."
puts "=========================================\n"

synth_design -top $top_module -part $part \
    -mode out_of_context \
    -flatten_hierarchy rebuilt \
    -verbose

puts "\n========================================="
puts "Synthesis Complete!"
puts "=========================================\n"

# Generate reports
puts "Generating reports..."

report_utilization -file utilization_synth.rpt
report_timing_summary -file timing_synth.rpt -max_paths 10

puts "\nReports generated:"
puts "  - utilization_synth.rpt"
puts "  - timing_synth.rpt"

# Summary
puts "\n========================================="
puts "RESOURCE UTILIZATION"
puts "=========================================\n"

set util_rpt [open "utilization_synth.rpt" r]
set print_section 0
while {[gets $util_rpt line] >= 0} {
    if {[string match "*Slice Logic*" $line]} {
        set print_section 1
    }
    if {$print_section && [string match "*DSPs*" $line]} {
        puts $line
        break
    }
    if {$print_section} {
        puts $line
    }
}
close $util_rpt

puts "\n========================================="
puts "Build directory: build/"
puts "Next steps:"
puts "  1. Check utilization_synth.rpt"
puts "  2. Check timing_synth.rpt"
puts "  3. Run full implementation if needed"
puts "=========================================\n"