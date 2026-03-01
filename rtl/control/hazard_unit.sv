`ifndef SYNTHESIS
timeunit 1ns;
timeprecision 1ps;
`endif

import riscv_pkg::*;

module hazard_unit (
    // From ID/EX register
    input  logic [REG_ADDR_WIDTH-1:0] id_ex_rs1_addr,
    input  logic [REG_ADDR_WIDTH-1:0] id_ex_rs2_addr,
    input  logic [REG_ADDR_WIDTH-1:0] id_ex_rd_addr,
    input  logic                       id_ex_mem_read,
    input  logic                       id_ex_valid,

    // From IF/ID register
    input  logic [REG_ADDR_WIDTH-1:0] if_id_rs1_addr,
    input  logic [REG_ADDR_WIDTH-1:0] if_id_rs2_addr,

    // From EX stage
    input  logic branch_taken,
    input  logic ex_stall,         // Division stall

    // Pipeline control outputs
    output logic pc_stall,
    output logic if_id_stall, if_id_flush,
    output logic id_ex_stall, id_ex_flush,
    output logic ex_mem_stall, ex_mem_flush,
    output logic mem_wb_stall, mem_wb_flush,

    // Exposed for debug / performance counters
    output logic load_use_hazard
);

    assign load_use_hazard =
        id_ex_valid && id_ex_mem_read &&
        ((id_ex_rd_addr == if_id_rs1_addr && if_id_rs1_addr != '0) ||
         (id_ex_rd_addr == if_id_rs2_addr && if_id_rs2_addr != '0));

    always_comb begin
        // Default: no stall / flush
        pc_stall     = 1'b0;
        if_id_stall  = 1'b0;  if_id_flush  = 1'b0;
        id_ex_stall  = 1'b0;  id_ex_flush  = 1'b0;
        ex_mem_stall = 1'b0;  ex_mem_flush = 1'b0;
        mem_wb_stall = 1'b0;  mem_wb_flush = 1'b0;

        if (ex_stall) begin
            // Division stall: freeze entire pipeline in place
            pc_stall     = 1'b1;
            if_id_stall  = 1'b1;
            id_ex_stall  = 1'b1;
            ex_mem_stall = 1'b1;
            mem_wb_stall = 1'b1;
        end else if (load_use_hazard) begin
            // Load-use: stall IF+ID, insert bubble into EX
            pc_stall    = 1'b1;
            if_id_stall = 1'b1;
            id_ex_flush = 1'b1;
        end else if (branch_taken) begin
            // Control hazard: flush IF and ID (two wrong-path instructions)
            if_id_flush = 1'b1;
            id_ex_flush = 1'b1;
        end
    end

endmodule