`timescale 1ps/1ps
`default_nettype none
`include "rtl/isa.vh"

module imm_gen (
    input wire [`XLEN-1:0] instruction,
    output reg [`XLEN-1:0] immediate
);
    
    wire [6:0] opcode;
    assign opcode = instruction[6:0];

    wire [`XLEN-1:0] i_imm = {{20{instruction[31]}}, instruction[31:20]};
    wire [`XLEN-1:0] s_imm = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
    wire [`XLEN-1:0] b_imm = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
    wire [`XLEN-1:0] u_imm = {instruction[31:12], 12'b0};
    wire [`XLEN-1:0] j_imm = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};

    always @(*) begin
        case (opcode)
            `OP_IMM, `OP_IMM_LOAD, `OP_J_JALR: immediate = i_imm;
            // `OP_IMM, `OP_IMM_LOAD: immediate = i_imm;
            `OP_S_TYPE: immediate = s_imm;
            `OP_B_TYPE: immediate = b_imm;
            `OP_U_LUI, `OP_U_AUIPC: immediate = u_imm;
            `OP_J_JAL: immediate = j_imm;
            default: immediate = {`XLEN{1'b0}};
        endcase
    end
    
endmodule