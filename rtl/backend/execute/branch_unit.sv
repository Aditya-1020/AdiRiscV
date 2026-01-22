import riscv_pkg::*;

module branch_unit(
    input logic [XLEN-1:0] rs1_data,
    input logic [XLEN-1:0] rs2_data,
    input logic [XLEN-1:0] pc,
    input logic [XLEN-1:0] imm,
    input funct3_branch_e funct3,
    input opcode_e opcode,
    output logic branch_taken,
    output logic [XLEN-1:0] branch_target
);
    timeunit 1ns;
    timeprecision 1ps;

    localparam logic [XLEN-1:0] JALR_ALIGN_MASK = ~32'h1;

    logic condition_met;
    logic is_branch;
    logic is_jal;
    logic is_jalr;
    logic is_jump;

    assign is_branch = (opcode == OP_BRANCH);
    assign is_jal = (opcode == OP_JAL);
    assign is_jalr = (opcode == OP_JALR);
    assign is_jump = (is_jal || is_jalr);

    always_comb begin
        condition_met = 1'b0;

        if (is_branch) begin
            case (funct3)
                F3_BEQ: condition_met = (rs1_data == rs2_data);
                F3_BNE: condition_met = (rs1_data != rs2_data);
                F3_BLT: condition_met = (signed'(rs1_data) < signed'(rs2_data));
                F3_BGE: condition_met = (signed'(rs1_data) >= signed'(rs2_data));
                F3_BLTU: condition_met = (rs1_data < rs2_data);
                F3_BGEU: condition_met = (rs1_data >= rs2_data);
                default: condition_met = 1'b0;
            endcase
        end
    end

    // always_comb begin
    //     if (is_jalr) begin
    //         branch_target = (rs1_data + imm) & ~32'h1; // clearn lsb for alignment
    //     end else begin
    //         branch_target = pc + imm;
    //     end
    // end

    // Jump target
    assign branch_target = is_jalr ? ((rs1_data + imm) & JALR_ALIGN_MASK) : (pc + imm);

    // decision
    assign branch_taken = is_jump || (is_branch && condition_met);
    
endmodule