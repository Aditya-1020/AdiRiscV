
# Package
rtl/core/riscv_pkg.sv


# Frontend — Fetch
rtl/frontend/fetch/pc.sv
rtl/frontend/fetch/imem.sv
rtl/frontend/fetch/if_stage.sv

# tb/tb_pc.sv
# tb/tb_pc_plus4.sv
# tb/tb_imem.sv


# Frontend — Decode
rtl/frontend/decode/imm_gen.sv
rtl/frontend/decode/regfile.sv
rtl/frontend/decode/decoder.sv
rtl/frontend/decode/id_stage.sv

# tb/tb_imm_gen.sv
# tb/tb_regfile.sv
# tb/tb_decoder.sv


# Backend — Execute
rtl/backend/execute/alu.sv
rtl/backend/execute/divider.sv
rtl/backend/execute/branch_unit.sv
rtl/backend/execute/ex_stage.sv

# tb/tb_alu.sv
# tb/tb_mtype.sv
# tb/tb_branch_unit.sv


# Backend — Memory
rtl/backend/memory/dmem.sv
rtl/backend/memory/mem_stage.sv

# tb/tb_dmem.sv


# Backend — Writeback
rtl/backend/writeback/wb_stage.sv


# Pipeline Registers
rtl/pipeline/if_id_reg.sv
rtl/pipeline/id_ex_reg.sv
rtl/pipeline/ex_mem_reg.sv
rtl/pipeline/mem_wb_reg.sv


# Pipeline Control Units
rtl/pipeline/forwarding_unit.sv
rtl/pipeline/hazard_unit.sv


# Core Top Level
rtl/core/riscv_single_cycle_core.sv
rtl/core/riscv_pipelined_core.sv

# tb/tb_single_cycle.sv
# tb/tb_pipelined.sv