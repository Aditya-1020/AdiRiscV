`timescale 1ps/1ps
import isa_defs::*;

module control_unit(
    input  opcode_e   opcode,
    input  funct3_e   funct3,
    input  funct7_e   funct7,
    input  logic      zero, // takes zeero from the alu input

    output logic      RegWrite,
    output logic      ALUSrc,
    output logic      MemWrite,
    output logic[1:0]  ResultSrc
    output imm_gen_e  ImmSrc,
    output logic      PCSrc,
    output alu_op_e   ALUControl
);


endmodule