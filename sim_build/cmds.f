# package
rtl/common/riscv_pkg.sv

# frontend fetch + prediction
rtl/frontend/pc.sv
rtl/frontend/if_stage.sv

rtl/frontend/btb.sv
rtl/frontend/ras.sv
rtl/frontend/branch_predictor.sv

# decode + control
rtl/control/imm_gen.sv
rtl/control/decoder.sv
rtl/control/id_stage.sv
rtl/common/regfile.sv

# backend execute + WB
rtl/backend/alu.sv
rtl/backend/divider.sv
rtl/backend/branch_unit.sv
rtl/backend/ex_stage.sv
rtl/backend/wb_stage.sv

# memory
rtl/memory/load_unit.sv
rtl/memory/store_unit.sv
rtl/memory/lsu.sv
rtl/memory/mem_stage.sv
rtl/memory/memory_controller.sv

# pipeline reg
rtl/common/if_id_reg.sv
rtl/common/id_ex_reg.sv
rtl/common/ex_mem_reg.sv
rtl/common/mem_wb_reg.sv

# pipeline control
rtl/control/forwarding_unit.sv
rtl/control/hazard_unit.sv

# Core top level
# rtl/core/riscv_single_cycle_core.sv
rtl/core/riscv_pipelined_core.sv

# Performance
rtl/core/performance_counters.sv

# Testbenches
tb/tb_pipelined.sv
# tb/tb_tracex5.sv
