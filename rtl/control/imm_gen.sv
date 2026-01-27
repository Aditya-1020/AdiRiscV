import riscv_pkg::*;

module imm_gen(
    input logic [XLEN-1:0] instruction,
    output logic [XLEN-1:0] immediate
);
    timeunit 1ns;
    timeprecision 1ps;

    logic [6:0] opcode;
    assign opcode = instruction[6:0];

    logic [XLEN-1:0] i_imm, s_imm, b_imm, u_imm, j_imm;

    assign i_imm = {{20{instruction[31]}}, instruction[31:20]};
    assign s_imm = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
    assign b_imm = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
    assign u_imm = {instruction[31:12], 12'b0};
    assign j_imm = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};

    always_comb begin
        case (opcode)
            OP_IMM, OP_LOAD, OP_JALR:  immediate = i_imm;
            OP_STORE:                   immediate = s_imm;
            OP_BRANCH:                  immediate = b_imm;
            OP_LUI, OP_AUIPC:          immediate = u_imm;
            OP_JAL:                     immediate = j_imm;
            default:                    immediate = 32'b0;
        endcase
    end

endmodule