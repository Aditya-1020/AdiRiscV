import riscv_pkg::*;

module ex_stage (
    input logic clk,
    input logic reset,
    input id_ex_reg_t id_ex_in, // id/ex
    
    // fwd from MEM
    input logic [XLEN-1:0] mem_alu_result,
    input logic [REG_ADDR_WIDTH-1:0] mem_rd_addr,
    input logic mem_reg_write,

    // fwd from wb
    input logic [XLEN-1:0] wb_wr_data,
    input logic [REG_ADDR_WIDTH-1:0] wb_rd_addr,
    input logic wb_reg_wr,

    // brach out -> IF and hazard
    output logic branch_taken,
    output logic [XLEN-1:0] branch_target,

    output ex_mem_reg_t ex_mem_out
);

    timeunit 1ns;
    timeprecision 1ps;


    logic [XLEN-1:0] alu_a, alu_b, 
    logic [XLEN-1:0] alu_result;
    logic alu_zero;

    logic [XLEN-1:0] rs1_fwd, rs2_fwd;
    // logic [XLEN-1:0] rs2_data_str; // rs2 after forwarding

    // forwarding control singals
    forward_src_e forward_a, forward_b;


    // From id/ex
    opcode_e opcode;
    funct3_branch_e funct3_branch;
    logic is_jump;

    assign is_jump = id_ex_in.ctrl.is_jump;
    assign opcode = opcode_e'(is_jump ? (id_ex_in.is_jalr ? OP_JALR : OP_JAL) : id_ex_in.is_branch ? OP_BRANCH : OP_IMM);
    assign funct3_branch = funct3_branch_e'(id_ex_in.funct3_for_branch);

    // forwarding unit
    forwarding_unit fwd_unit (
        .id_ex_rs1_addr(id_ex_in.rs1_addr),
        .id_ex_rs2_addr(id_ex_in.rs2_addr),
        .ex_mem_rd_addr(mem_rd_addr),
        .ex_mem_reg_wr(mem_reg_write),
        .mem_wb_rd_addr(wb_rd_addr),
        .mem_wb_reg_wr(wb_reg_wr),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    // forward to rs1
    always_comb begin
        case (forward_a)
            FWD_MEM: rs1_fwd: mem_alu_result; // from EX/MEM
            FWD_WB: rs1_fwd: wb_wr_data; // from MEM/WB
            default: rs1_fwd: id_ex_in.rs1_data; // no forward
        endcase
    end

    // forward to rs2
    always_comb begin
        case (forward_b)
            FWD_MEM: rs2_fwd: mem_alu_result; // from EX/MEM
            FWD_WB: rs2_fwd: wb_wr_data; // from MEM/WB
            default: rs2_fwd: id_ex_in.rs2_data; // no forward
        endcase
    end


    // alu
    always_comb begin
        // ALU A: PC for AUIPC else fwd rs1
        if (opcode == OP_AUIPC) begin
            alu_a = id_ex_in.pc;
        end else begin
            alu_a = rs1_fwd;
        end
    end

    assign alu_b = id_ex_in.ctrl.alu_src ? id_ex_in.immediate : rs2_fwd;

    alu alu_inst (
        .a(alu_a),
        .b(alu_b),
        .op(id_ex_in.ctrl.alu_op),
        .zero(alu_zero),
        .reset(alu_result)
    );

    branch_unit branch_unit_inst (
        .rs1_data(rs1_fwd),
        .rs2_data(rs2_fwd),
        .pc(id_ex_in.pc),
        .imm(id_ex_in.immediate),
        .funct3(funct3_branch),
        .opcode(opcode),
        .branch_taken(branch_taken),
        .branch_target(branch_target),
        .is_jump(is_jump)
    );

    // pack dis up
    // assign rs2_data_str = rs2_fwd;
    always_comb begin
        ex_mem_out.alu_result = alu_result;
        ex_mem_out.rs2_data_str = rs2_fwd; // for stores
        ex_mem_out.rd_addr = id_ex_in.rd_addr;
        ex_mem_out.ctrl = id_ex_in.ctrl;
        ex_mem_out.valid_ex_mem = id_ex_in.valid_id_ex;
    end

endmodule