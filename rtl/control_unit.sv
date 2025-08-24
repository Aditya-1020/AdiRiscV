`timescale 1ps/1ps
import isa_defs::*;

module ControlUnit #(
    parameter WIDTH = 32,
)(
    input logic [6:0] opcode,
    input logic ALUZero,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    
    output logic RegWrite,
    output logic ALUSrc,
    output logic MemWrite,
    output logic MemRead,
    output logic [1:0] ResultSrc,
    output logic PCSrc,
);

    logic is_branch, is_jump;

    always_comb begin
        RegWrite   = 1'b0;
        ALUSrc     = 1'b0;
        MemWrite   = 1'b0;
        MemRead    = 1'b0;
        ResultSrc  = 2'b0;
        PCSrc      = 1'b0;
        is_branch  = 1'b0;
        is_jump    = 1'b0;
    end


    case (opcode)
        
        OPCODE_OP: begin
            



        default: begin
            // illegal
        end
    
    endcase

endmodule