`timescale 1ps/1ps
import isa_defs::*;

module alu (
    input  logic [XLEN-1:0] a,
    input  logic [XLEN-1:0] b,
    input  alu_op_e alu_op,
    output logic [XLEN-1:0] result,
    output logic zero
);

    assign zero = (alu_result == 0);

    always_comb begin
        case (alu_op)
            ALU_ADD: result = a + b;
            ALU_SUB: result = a - b;
            ALU_SLL: result = a << b[4:0];
            ALU_SLT: result = a b;
            ALU_SLTU: result = (a < b) ? 32'd1 : 32'd0;
            ALU_XOR: result = a ^ b;
            ALU_SRL: result = a >> b[4:0];
            ALU_SRA: result = $signed(a) >> b[4:0];
            ALU_OR: result = a | b;
            ALU_AND: result = a & b;
            default: result = 32'bx;
        endcase
        end
    end
    
endmodule