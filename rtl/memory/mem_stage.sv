import riscv_pkg::*;

module mem_stage (
    input logic clk,
    input logic reset,
    input ex_mem_reg_t ex_mem_in,

    input logic [XLEN-1:0] dmem_rdata,

    output logic [XLEN-1:0] dmem_addr,
    output logic [XLEN-1:0] dmem_wdata,
    output logic [3:0] dmem_byte_en,
    output logic dmem_wr_en,
    output logic dmem_rd_en,
    output logic mem_stall, // dcache stall
    output mem_wb_reg_t mem_wb_out
);

    timeunit 1ns; timeprecision 1ps;

    logic [XLEN-1:0] mem_rdata_aligned;
    logic lsu_ready;
    logic misaligned_error;
    
    lsu lsu_inst (
        .clk(clk),
        .reset(reset),
        .addr(ex_mem_in.alu_result),
        .wdata(ex_mem_in.rs2_data_str),
        .mem_op(ex_mem_in.ctrl.mem_op),
        .mem_read(ex_mem_in.ctrl.mem_read),
        .mem_write(ex_mem_in.ctrl.mem_write),

        // To memory controller
        .mem_addr(dmem_addr),
        .mem_wdata(dmem_wdata),
        .mem_byte_en(dmem_byte_en),
        .mem_wr_en(dmem_wr_en),
        .mem_rd_en(dmem_rd_en),
        
        // From memory controller
        .mem_rdata_raw(dmem_rdata),

        // Back to pipeline
        .rdata(mem_rdata_aligned),
        .lsu_ready(lsu_ready),
        .misaligned_error(misaligned_error)
    );    

    assign mem_stall = !lsu_ready;


    // pack for MEM/wb
    always_comb begin
        mem_wb_out.alu_result = ex_mem_in.alu_result;
        mem_wb_out.mem_data = mem_rdata_aligned;
        mem_wb_out.rd_addr = ex_mem_in.rd_addr;
        mem_wb_out.ctrl = ex_mem_in.ctrl;
        mem_wb_out.valid_mem_wb = ex_mem_in.valid_ex_mem && !misaligned_error;
    end

endmodule