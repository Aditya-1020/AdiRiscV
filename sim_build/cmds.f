# Package
rtl/core/riscv_pkg.sv

# Core Top Level
# rtl/core/riscv_single_cycle_core.sv
# tb/tb_single_cycle.sv
rtl/core/riscv_pipelined_core.sv
# tb/tb_pipelined.sv

# ALU + M Extension
rtl/backend/execute/alu.sv
rtl/backend/execute/divider.sv
# tb/tb_alu.sv
tb/tb_mtype.sv

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

# Pipeline Registers
rtl/pipeline/ex_mem_reg.sv
rtl/pipeline/mem_wb_reg.sv
rtl/pipeline/if_id_reg.sv
rtl/pipeline/id_ex_reg.sv
rtl/pipeline/forwarding_unit.sv
rtl/pipeline/hazard_unit.sv

# Pipeline Stages
rtl/frontend/fetch/if_stage.sv
rtl/frontend/decode/id_stage.sv
rtl/backend/memory/mem_stage.sv
rtl/backend/execute/ex_stage.sv
rtl/backend/writeback/wb_stage.sv