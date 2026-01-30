import riscv_pkg::*;

module ex_stage (
    input logic clk,
    input logic reset,
    input id_ex_reg_t id_ex_in,
    
    // Forwarding from MEM
    input logic [XLEN-1:0] mem_alu_result,
    input logic [REG_ADDR_WIDTH-1:0] mem_rd_addr,
    input logic mem_reg_write,

    // Forwarding from WB
    input logic [XLEN-1:0] wb_write_data,
    input logic [REG_ADDR_WIDTH-1:0] wb_rd_addr,
    input logic wb_reg_write,

    // BTB update
    output logic btb_update_en,
    output logic [XLEN-1:0] btb_pc_update,
    output logic [XLEN-1:0] btb_target_actual,
    output logic btb_is_branch_or_jmp,

    // Branch predictor update
    output logic bp_update_en,
    output logic [XLEN-1:0] bp_update_pc,
    output logic bp_actual_taken,
    output logic [XLEN-1:0] bp_actual_target,
    output logic bp_is_branch,

    // Branch resolution
    output logic branch_taken,
    output logic [XLEN-1:0] branch_target,

    output ex_mem_reg_t ex_mem_out,
    output logic ex_stall
);
    timeunit 1ns; timeprecision 1ps;

    logic [XLEN-1:0] alu_a, alu_b;
    logic [XLEN-1:0] alu_result;
    logic alu_zero, alu_ready;

    logic [XLEN-1:0] rs1_fwd, rs2_fwd;

    // forwarding
    forward_src_e forward_a, forward_b;

    opcode_e opcode;
    funct3_branch_e funct3_branch;
    logic is_jump, is_branch;

    assign is_jump = id_ex_in.ctrl.is_jump;
    assign is_branch = id_ex_in.ctrl.is_branch;
    assign opcode = opcode_e'(is_jump ? (id_ex_in.ctrl.is_jalr ? OP_JALR : OP_JAL) : is_branch ? OP_BRANCH : OP_IMM);
    assign funct3_branch = funct3_branch_e'(id_ex_in.funct3_for_branch);

    forwarding_unit fwd_unit (
        .id_ex_rs1_addr(id_ex_in.rs1_addr),
        .id_ex_rs2_addr(id_ex_in.rs2_addr),
        .ex_mem_rd_addr(mem_rd_addr),
        .ex_mem_reg_write(mem_reg_write),
        .mem_wb_rd_addr(wb_rd_addr),
        .mem_wb_reg_write(wb_reg_write),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    // forward to rs1
    always_comb begin
        case (forward_a)
            FWD_MEM: rs1_fwd = mem_alu_result;
            FWD_WB: rs1_fwd = wb_write_data;
            default: rs1_fwd = id_ex_in.rs1_data;
        endcase
    end

    // forward to rs2
    always_comb begin
        case (forward_b)
            FWD_MEM: rs2_fwd = mem_alu_result;
            FWD_WB: rs2_fwd = wb_write_data;
            default: rs2_fwd = id_ex_in.rs2_data;
        endcase
    end

    // ALU input select
    logic [XLEN-1:0] pc_plus_4;
    assign pc_plus_4 = id_ex_in.pc + 32'd4;

    always_comb begin
        if (opcode == OP_AUIPC) begin
            alu_a = id_ex_in.pc;
        end else if (is_jump) begin
            alu_a = pc_plus_4;
        end else begin
            alu_a = rs1_fwd;
        end
    end

    always_comb begin
        if (is_jump) begin
            alu_b = 32'h00000000;
        end else begin
            alu_b = id_ex_in.ctrl.alu_src ? id_ex_in.immediate : rs2_fwd;
        end
    end

    alu alu_inst (
        .clk(clk),
        .reset(reset),
        .a(alu_a),
        .b(alu_b),
        .op(id_ex_in.ctrl.alu_op),
        .zero(alu_zero),
        .result(alu_result),
        .ready(alu_ready)
    );

    branch_unit branch_unit_inst (
        .rs1_data(rs1_fwd),
        .rs2_data(rs2_fwd),
        .pc(id_ex_in.pc),
        .imm(id_ex_in.immediate),
        .funct3(funct3_branch),
        .opcode(opcode),
        .branch_taken(branch_taken),
        .branch_target(branch_target)
    );
    assign ex_stall = !alu_ready;

    // btb update
    assign btb_update_en = id_ex_in.valid_id_ex && (is_branch || is_jump);
    assign btb_pc_update = id_ex_in.pc;
    assign btb_target_actual = branch_target;
    assign btb_is_branch_or_jmp = branch_taken;

    // branch predictor update
    assign bp_update_en = id_ex_in.valid_id_ex && (is_branch || is_jump);
    assign bp_update_pc = id_ex_in.pc;
    assign bp_actual_taken = branch_taken;
    assign bp_actual_target = branch_target;
    assign bp_is_branch = is_branch;

    // Pack outputs for EX/MEM register
    always_comb begin
        ex_mem_out.alu_result = alu_result;
        ex_mem_out.rs2_data_str = rs2_fwd;
        ex_mem_out.rd_addr = id_ex_in.rd_addr;
        ex_mem_out.ctrl = id_ex_in.ctrl;
        ex_mem_out.valid_ex_mem = id_ex_in.valid_id_ex && alu_ready;
    end

endmodule