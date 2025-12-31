// `ifdef DECODE_FUNCT7_V
// `define DECODE_FUNCT7_V

`timescale 1ps/1ps
`default_nettype none
`include "rtl/isa.vh"

module decode_funct7 (
    input [6:0] funct7,
    output reg [3:0] alu_op
);

    always @(*) begin
        if (funct7 == `FUNCT7_ADD_SLL_SLT_SLTU_XOR_SRL_OR_AND)
            alu_op = `ALU_ADD;
        else if (funct7 == `FUNCT7_SUB_SRA)
            alu_op = `ALU_SUB;
        else
            alu_op = `ALU_ADD;
    end

endmodule

//`endif