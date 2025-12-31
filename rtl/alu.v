`timescale 1ps/1ps
`default_nettype none
`include "rtl/isa.vh"

module alu (
    input wire [`XLEN-1:0] a,
    input wire [`XLEN-1:0] b,
    input wire [3:0] ALUControl,
    output reg zero,
    output reg [`XLEN-1:0] result
);
    
    wire [4:0] shift_amount;
    assign shift_amount = b[4:0];

    wire signed [`XLEN-1:0] signed_a = $signed(a);
    wire signed [`XLEN-1:0] signed_b = $signed(b);

    always @(*) begin
        case (ALUControl)
            `ALU_ADD: result = a + b;
            `ALU_SUB: result = a - b;
            `ALU_SLL: result = a << shift_amount;
            `ALU_SLT: result = (signed_a < signed_b) ? 32'd1 : 32'd0;
            `ALU_SLTU: result = (a < b) ? 32'd0 : 32'd1;
            `ALU_XOR: result = a ^ b;
            `ALU_SRL: result = a >> shift_amount;
            `ALU_SRA: result = signed_a >>> shift_amount;
            `ALU_OR: result = a | b;
            `ALU_AND: result = a & b;
            `ALU_PASS_A: result = a;
            `ALU_PASS_B: result = b;
            default: result = a + b;
        endcase

        zero = (result == 32'h0) ? 1'b1 : 1'b0;
    end

endmodule