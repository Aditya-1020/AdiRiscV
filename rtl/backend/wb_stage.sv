import riscv_pkg::*;

module wb_stage (
    input logic clk,
    input logic reset,
    input mem_wb_reg_t mem_wb_in, // from mem/wb
    // to ID (regwrite)
    output logic [REG_ADDR_WIDTH-1:0] wb_rd_addr,
    output logic [XLEN-1:0] wb_write_data,
    output logic wb_reg_write
);

    timeunit 1ns;
    timeprecision 1ps;

    // mem data vs alu result
    always_comb begin
        unique case (mem_wb_in.mem_to_reg)
            1'b1: wb_write_data = mem_wb_in.mem_data; // loads
            1'b0: wb_write_data = mem_wb_in.alu_result; // ALU/JAL/LUI/etc
            default: wb_write_data = '0;
        endcase
    end

    // Reg write
    // written if reg_write, valid_mem_wb, not x0
    assign wb_write_data = mem_wb_in.ctrl.reg_write && mem_wb_in.valid_mem_wb;

    // Desitination register
    assign wb_rd_addr = mem_wb_in.rd_addr;


endmodule