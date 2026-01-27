import riscv_pkg::*;


module forwarding_unit (
    input logic [REG_ADDR_WIDTH-1:0] id_ex_rs1_addr, id_ex_rs2_addr,
    input logic [REG_ADDR_WIDTH-1:0] ex_mem_rd_addr,
    input logic ex_mem_reg_write,

    input logic [REG_ADDR_WIDTH-1:0] mem_wb_rd_addr,
    input logic mem_wb_reg_write,

    output forward_src_e forward_a, // rs1
    output forward_src_e forward_b // rs2
);

    timeunit 1ns;
    timeprecision 1ps;

    

    // rs1 (alu op a)
    always_comb begin
        forward_a = FWD_NONE;

        // Ex/MEM > MEM/WB
        if (ex_mem_reg_write && (ex_mem_rd_addr != 0) && (ex_mem_rd_addr == id_ex_rs1_addr)) begin
            forward_a = FWD_MEM;
        end else if (mem_wb_reg_write && (mem_wb_rd_addr != 0) && (mem_wb_rd_addr == id_ex_rs1_addr)) begin
            forward_a = FWD_WB;
        end
    end

    // rs2 (alu op b or store)
    always_comb begin
        forward_b = FWD_NONE;

        if (ex_mem_reg_write && (ex_mem_rd_addr != 0) && (ex_mem_rd_addr == id_ex_rs2_addr)) begin
            forward_b = FWD_MEM;
        end else if (mem_wb_reg_write && (mem_wb_rd_addr != 0) && (mem_wb_rd_addr == id_ex_rs2_addr)) begin
            forward_b = FWD_WB;
        end

    end

endmodule