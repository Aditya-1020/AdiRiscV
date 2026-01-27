import riscv_pkg::*;

module mem_stage (
    input logic clk,
    input logic reset,
    input ex_mem_reg_t ex_mem_in,
    output mem_wb_reg_t mem_wb_out
);

    timeunit 1ns;
    timeprecision 1ps;

    logic [XLEN-1:0] mem_rdata;

    dmem dmem_inst (
        .clk(clk),
        .addr(ex_mem_in.alu_result),
        .wdata(ex_mem_in.rs2_data_str),
        .wr_en(ex_mem_in.ctrl.mem_write),
        .rd_en(ex_mem_in.ctrl.mem_read),
        .mem_op(ex_mem_in.ctrl.mem_op),
        .rdata(mem_rdata)
    );

    // pack for MEM/wb
    always_comb begin
        mem_wb_out.alu_result = ex_mem_in.alu_result;
        mem_wb_out.mem_data = mem_rdata;
        mem_wb_out.rd_addr = ex_mem_in.rd_addr;
        mem_wb_out.ctrl = ex_mem_in.ctrl;
        mem_wb_out.valid_mem_wb = ex_mem_in.valid_ex_mem;
    end
endmodule