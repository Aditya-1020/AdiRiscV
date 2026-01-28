import riscv_pkg::*;

module riscv_pipelined_core (
    input logic clk,
    input logic reset
);

    timeunit 1ns;
    timeprecision 1ps;

    // Pipeline register outputs
    if_id_reg_t if_id_out;
    id_ex_reg_t id_ex_out;
    ex_mem_reg_t ex_mem_out;
    mem_wb_reg_t mem_wb_out;

    // Branch signals
    logic branch_taken;
    logic [XLEN-1:0] branch_target;

    // BTB update signals from EX
    logic btb_update_en;
    logic [XLEN-1:0] btb_pc_update;
    logic [XLEN-1:0] btb_target_actual;
    logic btb_is_branch_or_jmp;

    // Hazard control signals
    logic if_id_stall, if_id_flush;
    logic id_ex_stall, id_ex_flush;
    logic ex_mem_stall, ex_mem_flush;
    logic mem_wb_stall, mem_wb_flush;
    logic pc_stall;
    logic ex_stall; // Division stall signal
    logic mem_stall; // Memory stall (unused for now)

    // WB stage outputs
    logic [REG_ADDR_WIDTH-1:0] wb_rd_addr;
    logic [XLEN-1:0] wb_write_data;
    logic wb_reg_write;

    // Pipeline register outputs
    if_id_reg_t if_id_reg_out;
    id_ex_reg_t id_ex_reg_out;
    mem_wb_reg_t mem_stage_out;
    ex_mem_reg_t ex_stage_out;

    // Memory controller interfaces
    logic [XLEN-1:0] imem_addr, imem_rdata;
    logic [XLEN-1:0] dmem_addr, dmem_wdata, dmem_rdata;
    logic [3:0] dmem_byte_en;
    logic dmem_wr_en, dmem_rd_en;

    // MEMORY CONTROLLER
    memory_controller mem_ctrl (
        .clk(clk),
        .reset(reset),
        // Instruction memory
        .imem_addr(imem_addr),
        .imem_rdata(imem_rdata),
        // Data memory
        .dmem_addr(dmem_addr),
        .dmem_wdata(dmem_wdata),
        .dmem_byte_en(dmem_byte_en),
        .dmem_wr_en(dmem_wr_en),
        .dmem_rd_en(dmem_rd_en),
        .dmem_rdata(dmem_rdata)
    );

    // IF STAGE
    if_stage if_stage_inst (
        .clk(clk),
        .reset(reset),
        .pc_stall(pc_stall),
        .branch_taken(branch_taken),
        .branch_target(branch_target),
        // BTB update signals from EX
        .btb_update_en(btb_update_en),
        .btb_pc_update(btb_pc_update),
        .btb_target_actual(btb_target_actual),
        .btb_is_branch_or_jmp(btb_is_branch_or_jmp),
        // Memory interface
        .imem_addr(imem_addr),
        .imem_rdata(imem_rdata),
        .if_id_out(if_id_out)
    );

    // IF/ID Pipeline Register
    if_id_reg if_id_reg_inst (
        .clk(clk),
        .reset(reset),
        .stall(if_id_stall),
        .flush(if_id_flush),
        .in(if_id_out),
        .out(if_id_reg_out)
    );

    // ID STAGE
    id_stage id_stage_inst (
        .clk(clk),
        .reset(reset),
        .if_id_in(if_id_reg_out),
        .wb_rd_addr(wb_rd_addr),
        .wb_write_data(wb_write_data),
        .wb_reg_write(wb_reg_write),
        .id_ex_out(id_ex_out)
    );

    // ID/EX Pipeline Register
    id_ex_reg id_ex_reg_inst (
        .clk(clk),
        .reset(reset),
        .stall(id_ex_stall),
        .flush(id_ex_flush),
        .in(id_ex_out),
        .out(id_ex_reg_out)
    );

    // EX STAGE
    ex_stage ex_stage_inst (
        .clk(clk),
        .reset(reset),
        .id_ex_in(id_ex_reg_out),
        
        // Forwarding from MEM
        .mem_alu_result(ex_mem_out.alu_result),
        .mem_rd_addr(ex_mem_out.rd_addr),
        .mem_reg_write(ex_mem_out.ctrl.reg_write),
        
        // Forwarding from WB
        .wb_write_data(wb_write_data),
        .wb_rd_addr(wb_rd_addr),
        .wb_reg_write(wb_reg_write),
        
        // BTB update outputs
        .btb_update_en(btb_update_en),
        .btb_pc_update(btb_pc_update),
        .btb_target_actual(btb_target_actual),
        .btb_is_branch_or_jmp(btb_is_branch_or_jmp),
        
        // Branch resolution
        .branch_taken(branch_taken),
        .branch_target(branch_target),
        
        .ex_mem_out(ex_stage_out),
        .ex_stall(ex_stall)
    );

    // EX/MEM Pipeline Register
    ex_mem_reg ex_mem_reg_inst (
        .clk(clk),
        .reset(reset),
        .stall(ex_mem_stall),
        .flush(ex_mem_flush),
        .in(ex_stage_out),
        .out(ex_mem_out)
    );

    // MEM STAGE
    mem_stage mem_stage_inst (
        .clk(clk),
        .reset(reset),
        .ex_mem_in(ex_mem_out),
        // Memory controller interface
        .dmem_addr(dmem_addr),
        .dmem_wdata(dmem_wdata),
        .dmem_byte_en(dmem_byte_en),
        .dmem_wr_en(dmem_wr_en),
        .dmem_rd_en(dmem_rd_en),
        .dmem_rdata(dmem_rdata),
        .mem_wb_out(mem_stage_out),
        .mem_stall(mem_stall)
    );

    // MEM/WB Pipeline Register
    mem_wb_reg mem_wb_reg_inst (
        .clk(clk),
        .reset(reset),
        .stall(mem_wb_stall),
        .flush(mem_wb_flush),
        .in(mem_stage_out),
        .out(mem_wb_out)
    );

    // WB STAGE
    wb_stage wb_stage_inst (
        .clk(clk),
        .reset(reset),
        .mem_wb_in(mem_wb_out),
        .wb_rd_addr(wb_rd_addr),
        .wb_write_data(wb_write_data),
        .wb_reg_write(wb_reg_write)
    );

    // HAZARD DETECTION
    hazard_unit hazard_unit_inst (
        .id_ex_rs1_addr(id_ex_reg_out.rs1_addr),
        .id_ex_rs2_addr(id_ex_reg_out.rs2_addr),
        .id_ex_rd_addr(id_ex_reg_out.rd_addr),
        .id_ex_mem_read(id_ex_reg_out.ctrl.mem_read),
        .id_ex_valid(id_ex_reg_out.valid_id_ex),
        .if_id_rs1_addr(if_id_reg_out.instruction[19:15]),
        .if_id_rs2_addr(if_id_reg_out.instruction[24:20]),
        .branch_taken(branch_taken),
        .ex_stall(ex_stall),
        .pc_stall(pc_stall),
        .if_id_stall(if_id_stall),
        .if_id_flush(if_id_flush),
        .id_ex_stall(id_ex_stall),
        .id_ex_flush(id_ex_flush),
        .ex_mem_stall(ex_mem_stall),
        .ex_mem_flush(ex_mem_flush),
        .mem_wb_stall(mem_wb_stall),
        .mem_wb_flush(mem_wb_flush)
    );

endmodule