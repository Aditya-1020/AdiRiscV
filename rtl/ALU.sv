`timescale 1ns / 1ps
`include "defines.sv"

module alu (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [3:0] alu_op,
    output logic [31:0] alu_result,
    output logic zero
);

assign zero = (alu_result == 0);

logic [4:0] shift_ammount;
assign shift_ammount = b[4:0];

always_comb begin
    case(alu_op)
        `ALU_ADD: alu_result = a + b;
        `ALU_SUB: alu_result = a - b;
        
        `ALU_AND: alu_result = a & b;
        `ALU_OR:  alu_result = a | b;
        `ALU_XOR: alu_result = a ^ b;
        
        `ALU_SLL: alu_result = a << shift_ammount;
        `ALU_SRL: alu_result = a >> shift_ammount;
        `ALU_SRA: alu_result = $signed(a) >>> shift_ammount;

        `ALU_SLT: begin
            alu_result = ($singed(a) < $signed(b)) ? 32'b1 : 32'b0;
        end

        `ALU_SLTU: begin
            alu_result = (a < b) ? 32'b1 : 31'b0;
        end
        default: alu_result = 32'bx;

    endcase
end

endmodule