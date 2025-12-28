`timescale 1ps/1ps
`default_nettype none
`include "rtl/isa.v"

module alu_control (
    input wire [1:0] ALUOp,
    input wire instr_30,
    input wire [2:0] funct3,
    output reg [3:0] ALUControl
);

    always @(*) begin
        ALUControl = `ALU_ADD;

        case (ALUOp)
            2'b00: ALUControl = `ALU_ADD;
            2'b01: ALUControl = `ALU_SUB;
            2'b10: begin
                case (funct3)
                    `FUNCT3_ADD_SUB: begin
                        if (instr_30) begin
                            ALUControl = `ALU_SUB;
                        end else begin
                            ALUControl = `ALU_ADD;
                        end
                    end
                    `FUNCT3_SLL:  ALUControl = `ALU_SLL;
                    `FUNCT3_SLT:  ALUControl = `ALU_SLT;
                    `FUNCT3_SLTU: ALUControl = `ALU_SLTU;
                    `FUNCT3_XOR:  ALUControl = `ALU_XOR;
                    `FUNCT3_SRL_SRA: begin
                        if (instr_30) begin
                            ALUControl = `ALU_SRA;
                        end else begin
                            ALUControl = `ALU_SRL;
                        end
                    end
                    `FUNCT3_OR:  ALUControl = `ALU_OR;
                    `FUNCT3_AND: ALUControl = `ALU_AND;
                    default:     ALUControl = `ALU_ADD;
                endcase
            end
            2'b11:   ALUControl = `ALU_ADD;
            default: ALUControl = `ALU_ADD;
        endcase
    end
    
endmodule