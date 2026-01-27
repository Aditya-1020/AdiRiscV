import riscv_pkg::*;

module id_stage (
    input logic clk,
    input logic reset,
    input if_id_reg_t if_id_in,
    
    // WB (regifle)
    input logic [REG_ADDR_WIDTH-1:0] wb_rd_addr,
    input logic [XLEN-1:0] wb_write_data,
    input logic wb_reg_write,
    
    output id_ex_reg_t id_ex_out
);

    timeunit 1ns;
    timeprecision 1ps;

    logic [4:0] rs1_addr, rs2_addr, rd_addr;
    logic [XLEN-1:0] rs1_data, rs2_data, immediate;
    ctrl_signals_t ctrl;
    logic [2:0] funct3_branch;


    assign rs1_addr = if_id_in.instruction[19:15];
    assign rs2_addr = if_id_in.instruction[24:20];
    assign rd_addr = if_id_in.instruction[11:7];

    assign funct3_branch = if_id_in.instruction[14:12];

    // Regfile
    regfile regfile_inst (
        .clk(clk),
        .reset(reset),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd(wb_rd_addr), // WB
        .write_data(wb_write_data), // WB
        .wr_en(wb_reg_write), // WB
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );
    
    // decoder
    decoder decoder_inst (
        .instruction(if_id_in.instruction),
        .ctrl(ctrl)
    );


    // imm_gen
    imm_gen imm_gen_inst (
        .instruction(if_id_in.instruction),
        .immediate(immediate)
    );

    always_comb begin
        id_ex_out.pc = if_id_in.pc;
        id_ex_out.rs1_data = rs1_data;
        id_ex_out.rs2_data = rs2_data;
        id_ex_out.immediate = immediate;
        id_ex_out.funct3_for_branch = funct3_branch;
        id_ex_out.rs1_addr = rs1_addr;
        id_ex_out.rs2_addr = rs2_addr;
        id_ex_out.rd_addr = rd_addr;
        id_ex_out.ctrl = ctrl;
        id_ex_out.valid_id_ex = if_id_in.valid_if_id; // propogate valid bit (To track da bubbles dawg)
    end

endmodule