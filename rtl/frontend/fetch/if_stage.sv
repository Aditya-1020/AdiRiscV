import riscv_pkg::*;

module if_stage (
    input logic clk,
    input logic reset,
    input logic branch_taken, // from EX
    input logic [XLEN-1:0] branch_target, // From EX
    input logic pc_stall, // hazard unit
    output if_id_reg_t if_id_out
);

    timeunit 1ns;
    timeprecision 1ps;

    logic [XLEN-1:0] pc, pc_next, pc_plus4;
    logic [XLEN-1:0] instruction;
    logic [WORD_ADDR_WIDTH-1:0] imem_addr;
    logic pc_en;

    // PC
    assign pc_plus4 = pc + 32'd4;
    assign pc_next = branch_taken ? branch_target : pc_plus4;
    assign pc_en = !pc_stall;

    pc pc_inst (
        .clk(clk),
        .reset(reset),
        .pc_en(pc_en),
        .pc_next(pc_next),
        .pc(pc)
    );

    // imem
    assign imem_addr = pc[WORD_ADDR_WIDTH+1:2]; // convert byte address to word address

    imem imem_inst (
        .address(imem_addr),
        .instruction(instruction)
    );

    // pack outputs
    always_comb begin
        if_id_out.pc = pc;
        if_id_out.instruction = instruction;
        if_id_out.pc_plus4 = pc_plus4;
        if_id_out.valid_if_id = 1'b1; // valid until flush activated
    end

endmodule