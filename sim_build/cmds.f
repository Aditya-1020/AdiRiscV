# Package
rtl/core/riscv_pkg.sv

# Core Top Level
rtl/core/riscv_single_cycle_core.sv  
tb/tb_single_cycle.sv

# ALU
rtl/backend/execute/alu.sv  
# tb/tb_alu.sv

# Branch Unit
rtl/backend/execute/branch_unit.sv  
# tb/tb_branch_unit.sv

# Data Memory
rtl/backend/memory/dmem.sv  
# tb/tb_dmem.sv

# Decoder
rtl/frontend/decode/decoder.sv  
# tb/tb_decoder.sv

# Immediate Generator
rtl/frontend/decode/imm_gen.sv  
# tb/tb_imm_gen.sv

# Register File
rtl/frontend/decode/regfile.sv  
# tb/tb_regfile.sv

# Instruction Memory
rtl/frontend/fetch/imem.sv  
# tb/tb_imem.sv

# Program Counter
rtl/frontend/fetch/pc.sv  
# tb/tb_pc.sv  
# tb/tb_pc_plus4.sv
