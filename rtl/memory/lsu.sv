import riscv_pkg::*;

module lsu (
    input logic clk,
    input logic reset,
    
    // from Ex stage
    input logic [XLEN-1:0] addr,
    input logic [XLEN-1:0] wdata,
    input mem_op_e mem_op,
    input logic mem_read,
    input logic mem_write,

    // to-from dcache
    input logic [XLEN-1:0] mem_rdata_raw,
    output logic [XLEN-1:0] mem_addr,
    output logic [XLEN-1:0] mem_wdata,
    output logic [3:0] mem_byte_en,
    output logic mem_wr_en,
    output logic mem_rd_en,

    // to pipeline
    output logic [XLEN-1:0] rdata,
    output logic lsu_ready,
    output logic misaligned_error
);

    timeunit 1ns; timeprecision 1ps;

    logic [XLEN-1:0] rdata_aligned;
    logic [XLEN-1:0] wdata_aligned;
    logic [3:0] byte_enable;


    // Misaligned check
    always_comb begin
        misaligned_error = 1'b0;
        case (mem_op)
            MEM_HALF, MEM_HALF_U: misaligned_error = addr[0];
            MEM_WORD: misaligned_error = (addr[1:0] != 2'b00);
            default: misaligned_error = 1'b0;
        endcase
    end

    load_unit load_inst (
        .addr(addr),
        .mem_rdata_raw(mem_rdata_raw),
        .mem_op(mem_op),
        .rdata_aligned(rdata_aligned)
    );

    store_unit store_inst (
        .addr(addr),
        .wdata(wdata),
        .mem_op(mem_op),
        .wdata_aligned(wdata_aligned),
        .byte_enable(byte_enable)
    );

    assign mem_addr = addr;
    assign mem_wdata = wdata_aligned;
    assign mem_byte_en = byte_enable;
    assign mem_wr_en = mem_write && !misaligned_error;
    assign mem_rd_en = mem_read && !misaligned_error;
    assign rdata = rdata_aligned;
    assign lsu_ready = 1'b1; // ready for now changes when dcache is implemneted

endmodule