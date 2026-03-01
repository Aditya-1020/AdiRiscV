`ifndef SYNTHESIS
timeunit 1ns;
timeprecision 1ps;
`endif

import riscv_pkg::*;

module riscv_pipelined_core (
    input  logic clk,
    input  logic reset,

    // Debug outputs for FPGA top-level
    output logic [XLEN-1:0] debug_pc,
    output logic [XLEN-1:0] debug_instr,
    output logic            debug_stall,
    output logic            debug_branch,
    output logic            debug_load_use,
    output logic            debug_ex_stall,
    output logic            debug_alu_ready
);

    // Pipeline register types
    if_id_reg_t  if_id_out;
    id_ex_reg_t  id_ex_out;
    ex_mem_reg_t ex_mem_out;
    mem_wb_reg_t mem_wb_out;

    if_id_reg_t  if_id_reg_out;
    id_ex_reg_t  id_ex_reg_out;
    ex_mem_reg_t ex_stage_out;   // combinational from EX
    ex_mem_reg_t ex_mem_reg_out; // registered EX/MEM output
    mem_wb_reg_t mem_stage_out;

    // Control signals
    logic branch_taken;
    logic [XLEN-1:0] branch_target;

    logic btb_update_en;
    logic [XLEN-1:0] btb_pc_update, btb_target_actual;
    logic btb_is_branch_or_jmp;

    logic bp_update_en;
    logic [XLEN-1:0] bp_update_pc, bp_actual_target;
    logic bp_actual_taken;
    logic bp_is_branch;

    logic if_id_stall,  if_id_flush;
    logic id_ex_stall,  id_ex_flush;
    logic ex_mem_stall, ex_mem_flush;
    logic mem_wb_stall, mem_wb_flush;
    logic pc_stall;
    logic ex_stall;
    logic mem_stall;

    logic [REG_ADDR_WIDTH-1:0] wb_rd_addr;
    logic [XLEN-1:0]           wb_write_data;
    logic                       wb_reg_write;

    logic [XLEN-1:0] imem_addr, imem_rdata;
    logic [XLEN-1:0] dmem_addr, dmem_wdata, dmem_rdata;
    logic [3:0]      dmem_byte_en;
    logic            dmem_wr_en, dmem_rd_en;

    // Performance counter signals
    logic perf_instruction_retired;
    logic perf_branch_taken;
    logic perf_branch_mispredicted;
    logic perf_load_use_stall;
    logic perf_div_stall;

    logic [PERF_COUNTER_WIDTH-1:0] perf_cycles;
    logic [PERF_COUNTER_WIDTH-1:0] perf_instructions;
    logic [PERF_COUNTER_WIDTH-1:0] perf_branches;
    logic [PERF_COUNTER_WIDTH-1:0] perf_branch_misses;
    logic [PERF_COUNTER_WIDTH-1:0] perf_stalls;

    // Hazard unit internals exposed for debug
    logic hazard_load_use;

    // Debug output assignments (replaces hierarchical probing)
    assign debug_pc       = if_id_reg_out.pc;
    assign debug_instr    = if_id_reg_out.instruction;
    assign debug_stall    = pc_stall;
    assign debug_branch   = branch_taken;
    assign debug_load_use = hazard_load_use;
    assign debug_ex_stall = ex_stall;
    assign debug_alu_ready = !ex_stall;

    // Memory Controller
    memory_controller mem_ctrl (
        .clk          (clk),
        .reset        (reset),
        .imem_addr    (imem_addr),
        .imem_rdata   (imem_rdata),
        .dmem_addr    (dmem_addr),
        .dmem_wdata   (dmem_wdata),
        .dmem_byte_en (dmem_byte_en),
        .dmem_wr_en   (dmem_wr_en),
        .dmem_rd_en   (dmem_rd_en),
        .dmem_rdata   (dmem_rdata)
    );

    // IF Stage
    if_stage if_stage_inst (
        .clk               (clk),
        .reset             (reset),
        .pc_stall          (pc_stall),
        .branch_taken      (branch_taken),
        .branch_target     (branch_target),
        .btb_update_en     (btb_update_en),
        .btb_pc_update     (btb_pc_update),
        .btb_target_actual (btb_target_actual),
        .btb_is_branch_or_jmp(btb_is_branch_or_jmp),
        .bp_update_en      (bp_update_en),
        .bp_update_pc      (bp_update_pc),
        .bp_actual_taken   (bp_actual_taken),
        .bp_actual_target  (bp_actual_target),
        .bp_is_branch      (bp_is_branch),
        .imem_addr         (imem_addr),
        .imem_rdata        (imem_rdata),
        .if_id_out         (if_id_out)
    );

    if_id_reg if_id_reg_inst (
        .clk   (clk), .reset (reset),
        .stall (if_id_stall), .flush (if_id_flush),
        .in    (if_id_out),   .out   (if_id_reg_out)
    );

    // ID Stage
    id_stage id_stage_inst (
        .clk           (clk),
        .reset         (reset),
        .if_id_in      (if_id_reg_out),
        .wb_rd_addr    (wb_rd_addr),
        .wb_write_data (wb_write_data),
        .wb_reg_write  (wb_reg_write),
        .id_ex_out     (id_ex_out)
    );

    id_ex_reg id_ex_reg_inst (
        .clk   (clk), .reset (reset),
        .stall (id_ex_stall), .flush (id_ex_flush),
        .in    (id_ex_out),   .out   (id_ex_reg_out)
    );

    // EX Stage
    ex_stage ex_stage_inst (
        .clk               (clk),
        .reset             (reset),
        .id_ex_in          (id_ex_reg_out),
        .mem_alu_result    (ex_mem_reg_out.alu_result),
        .mem_rd_addr       (ex_mem_reg_out.rd_addr),
        .mem_reg_write     (ex_mem_reg_out.ctrl.reg_write),
        .wb_write_data     (wb_write_data),
        .wb_rd_addr        (wb_rd_addr),
        .wb_reg_write      (wb_reg_write),
        .btb_update_en     (btb_update_en),
        .btb_pc_update     (btb_pc_update),
        .btb_target_actual (btb_target_actual),
        .btb_is_branch_or_jmp(btb_is_branch_or_jmp),
        .bp_update_en      (bp_update_en),
        .bp_update_pc      (bp_update_pc),
        .bp_actual_taken   (bp_actual_taken),
        .bp_actual_target  (bp_actual_target),
        .bp_is_branch      (bp_is_branch),
        .branch_taken      (branch_taken),
        .branch_target     (branch_target),
        .ex_mem_out        (ex_stage_out),
        .ex_stall          (ex_stall)
    );

    ex_mem_reg ex_mem_reg_inst (
        .clk   (clk), .reset (reset),
        .stall (ex_mem_stall), .flush (ex_mem_flush),
        .in    (ex_stage_out),  .out   (ex_mem_reg_out)
    );

    // Alias for forwarding — the registered output is what MEM/WB sees
    assign ex_mem_out = ex_mem_reg_out;

    // MEM Stage
    mem_stage mem_stage_inst (
        .clk         (clk),
        .reset       (reset),
        .ex_mem_in   (ex_mem_reg_out),
        .dmem_addr   (dmem_addr),
        .dmem_wdata  (dmem_wdata),
        .dmem_byte_en(dmem_byte_en),
        .dmem_wr_en  (dmem_wr_en),
        .dmem_rd_en  (dmem_rd_en),
        .dmem_rdata  (dmem_rdata),
        .mem_wb_out  (mem_stage_out),
        .mem_stall   (mem_stall)
    );

    mem_wb_reg mem_wb_reg_inst (
        .clk   (clk), .reset (reset),
        .stall (mem_wb_stall), .flush (mem_wb_flush),
        .in    (mem_stage_out), .out   (mem_wb_out)
    );

    // WB Stage
    wb_stage wb_stage_inst (
        .clk          (clk),
        .reset        (reset),
        .mem_wb_in    (mem_wb_out),
        .wb_rd_addr   (wb_rd_addr),
        .wb_write_data(wb_write_data),
        .wb_reg_write (wb_reg_write)
    );

    // Hazard Detection
    hazard_unit hazard_unit_inst (
        .id_ex_rs1_addr  (id_ex_reg_out.rs1_addr),
        .id_ex_rs2_addr  (id_ex_reg_out.rs2_addr),
        .id_ex_rd_addr   (id_ex_reg_out.rd_addr),
        .id_ex_mem_read  (id_ex_reg_out.ctrl.mem_read),
        .id_ex_valid     (id_ex_reg_out.valid_id_ex),
        .if_id_rs1_addr  (if_id_reg_out.instruction[19:15]),
        .if_id_rs2_addr  (if_id_reg_out.instruction[24:20]),
        .branch_taken    (branch_taken),
        .ex_stall        (ex_stall),
        .pc_stall        (pc_stall),
        .if_id_stall     (if_id_stall),
        .if_id_flush     (if_id_flush),
        .id_ex_stall     (id_ex_stall),
        .id_ex_flush     (id_ex_flush),
        .ex_mem_stall    (ex_mem_stall),
        .ex_mem_flush    (ex_mem_flush),
        .mem_wb_stall    (mem_wb_stall),
        .mem_wb_flush    (mem_wb_flush),
        .load_use_hazard (hazard_load_use)   // new output for debug
    );

    // Performance Counters
    performance_counters perf_counters_inst (
        .clk                  (clk),
        .reset                (reset),
        .instruction_retired  (perf_instruction_retired),
        .branch_taken         (perf_branch_taken),
        .branch_mispredicted  (perf_branch_mispredicted),
        .load_use_stall       (perf_load_use_stall),
        .div_stall            (perf_div_stall),
        .cycles               (perf_cycles),
        .instructions         (perf_instructions),
        .branches             (perf_branches),
        .branch_misses        (perf_branch_misses),
        .stalls               (perf_stalls)
    );

    always_comb begin
        perf_instruction_retired = wb_reg_write && mem_wb_out.valid_mem_wb;
        perf_branch_taken        = branch_taken && id_ex_reg_out.valid_id_ex;
        perf_branch_mispredicted = branch_taken && if_id_flush;
        perf_load_use_stall      = id_ex_flush && !branch_taken && id_ex_reg_out.ctrl.mem_read;
        perf_div_stall           = ex_stall;
    end

endmodule