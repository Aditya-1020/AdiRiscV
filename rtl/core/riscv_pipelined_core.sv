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

    // Hazard control signals
    logic if_id_stall, if_id_flush;
    logic id_ex_stall, id_ex_flush;
    logic ex_mem_stall, ex_mem_flush;
    logic mem_wb_stall, mem_wb_flush;
    logic pc_stall;

    // WB stage
    logic [REG_ADDR_WIDTH-1:0] wb_rd_addr;
    logic [XLEN-1:0] wb_write_data;
    logic wb_reg_write;

    // Reg outs
    if_id_reg_t if_id_reg_out;
    id_ex_reg_t id_ex_reg_out;
    mem_wb_reg_t mem_stage_out;
    ex_mem_reg_t ex_stage_out;

    // IF stage
    if_stage if_stage_inst (
        .clk(clk),
        .reset(reset),
        .branch_taken(branch_taken),
        .branch_target(branch_target),
        .pc_stall(pc_stall),
        .if_id_out(if_id_out)
    );

    // IF/ID register
    if_id_reg if_id_reg_inst (
        .clk(clk),
        .reset(reset),
        .stall(if_id_stall),
        .flush(if_id_flush),
        .in(if_id_out),
        .out(if_id_reg_out)
    );

    // ID Stage
    id_stage id_stage_inst (
        .clk(clk),
        .reset(reset),
        .if_id_in(if_id_reg_out),
        .wb_rd_addr(wb_rd_addr),
        .wb_write_data(wb_write_data),
        .wb_reg_write(wb_reg_write),
        .id_ex_out(id_ex_out)
    );

    // ID/EX register
    id_ex_reg id_ex_reg_inst (
        .clk(clk),
        .reset(reset),
        .stall(id_ex_stall),
        .flush(id_ex_flush),
        .in(id_ex_out),
        .out(id_ex_reg_out)
    );

    // EX Stage
    ex_stage ex_stage_inst (
        .clk(clk),
        .reset(reset),
        .id_ex_in(id_ex_reg_out),
        
        // Forward from MEM
        .mem_alu_result(ex_mem_out.alu_result),
        .mem_rd_addr(ex_mem_out.rd_addr),
        .mem_reg_write(ex_mem_out.ctrl.reg_write),
        
        // Forward from WB
        .wb_write_data(wb_write_data),
        .wb_rd_addr(wb_rd_addr),
        .wb_reg_write(wb_reg_write),
        
        .branch_taken(branch_taken),
        .branch_target(branch_target),
        .ex_mem_out(ex_stage_out)
    );

    // EX/MEM register
    ex_mem_reg ex_mem_reg_inst (
        .clk(clk),
        .reset(reset),
        .stall(ex_mem_stall),
        .flush(ex_mem_flush),
        .in(ex_stage_out),
        .out(ex_mem_out)
    );

    // MEM stage
    mem_stage mem_stage_inst (
        .clk(clk),
        .reset(reset),
        .ex_mem_in(ex_mem_out),
        .mem_wb_out(mem_stage_out)
    );

    // MEM/WB register
    mem_wb_reg mem_wb_reg_inst (
        .clk(clk),
        .reset(reset),
        .stall(mem_wb_stall),
        .flush(mem_wb_flush),
        .in(mem_stage_out),
        .out(mem_wb_out)
    );

    // WB stage
    wb_stage wb_stage_inst (
        .clk(clk),
        .reset(reset),
        .mem_wb_in(mem_wb_out),
        .wb_rd_addr(wb_rd_addr),
        .wb_write_data(wb_write_data),
        .wb_reg_write(wb_reg_write)
    );

    /*
    // Hazard detection unit (TODO - implement next)
    hazard_unit hazard_unit_inst (
      .id_ex_rs1_addr(id_ex_reg_out.rs1_addr),
      .id_ex_rs2_addr(id_ex_reg_out.rs2_addr),
      .id_ex_rd_addr(id_ex_reg_out.rd_addr),
      .id_ex_mem_read(id_ex_reg_out.ctrl.mem_read),
      .id_ex_valid(id_ex_reg_out.valid_id_ex),
      .if_id_rs1_addr(if_id_reg_out.instruction[19:15]),
      .if_id_rs2_addr(if_id_reg_out.instruction[24:20]),
      .branch_taken(branch_taken),
      .pc_stall(pc_stall),
      .if_id_stall(if_id_stall),
      .if_id_flush(if_id_flush),
      .id_ex_flush(id_ex_flush),
      .ex_mem_stall(ex_mem_stall),
      .ex_mem_flush(ex_mem_flush),
      .mem_wb_stall(mem_wb_stall),
      .mem_wb_flush(mem_wb_flush)
    );
    */

    // // TEMP DEBUG
    assign pc_stall = 1'b0;
    assign if_id_stall = 1'b0;
    assign if_id_flush = 1'b0;
    assign id_ex_flush = 1'b0;
    assign ex_mem_stall = 1'b0;
    assign ex_mem_flush = 1'b0;
    assign mem_wb_stall = 1'b0;
    assign mem_wb_flush = 1'b0;


endmodule