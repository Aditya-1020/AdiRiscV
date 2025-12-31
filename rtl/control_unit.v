`timescale 1ps/1ps
`default_nettype none
`include "rtl/isa.vh"

module control_unit (
    input [`XLEN-1:0] instruction,
    output reg branch, MemRead, MemToReg,
    output reg [3:0] ALU_op,
    output reg MemWrite, ALUSrc, RegWrite,
    output reg is_branch, is_jump, is_jal, is_jalr, is_load, is_store
);

    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [6:0] funct7;

    assign opcode = instruction[6:0];
    assign funct3 = instruction[14:12];
    assign funct7 = instruction[31:25];

    always @(*) begin
        branch = 1'b0;
        MemRead = 1'b0;
        MemToReg = 1'b0;
        ALU_op = `ALU_ADD;
        MemWrite = 1'b0;
        ALUSrc = 1'b0;
        RegWrite = 1'b0;
        is_branch = 1'b0;
        is_jump = 1'b0;
        is_jal = 1'b0;
        is_jalr = 1'b0;
        is_load = 1'b0;
        is_store = 1'b0;

        case (opcode)
            `OP_R_TYPE: begin
                RegWrite = 1'b1;
                ALUSrc   = 1'b0;
                MemToReg = 1'b0;

            case (funct3)
                `FUNCT3_ADD_SUB: begin
                    if (funct7 == `FUNCT7_SUB_SRA)
                        ALU_op = `ALU_SUB;
                    else
                        ALU_op = `ALU_ADD;
                    end
                `FUNCT3_XOR:     ALU_op = `ALU_XOR;
                `FUNCT3_OR:      ALU_op = `ALU_OR;
                `FUNCT3_AND:     ALU_op = `ALU_AND;
                `FUNCT3_SLL:     ALU_op = `ALU_SLL;
                `FUNCT3_SRL_SRA: begin
                    if (funct7 == `FUNCT7_SUB_SRA)
                        ALU_op = `ALU_SRA;
                    else
                        ALU_op = `ALU_SRL;
                    end
                `FUNCT3_SLT:     ALU_op = `ALU_SLT;
                `FUNCT3_SLTU:    ALU_op = `ALU_SLTU;
                default:         ALU_op = `ALU_ADD;
            endcase
        end

            `OP_IMM: begin
                RegWrite = 1'b1;
                ALUSrc = 1'b1;
                MemToReg = 1'b0;

                case (funct3)
                    `FUNCT3_ADD_SUB: ALU_op = `ALU_ADD;
                    `FUNCT3_XOR:     ALU_op = `ALU_XOR;
                    `FUNCT3_OR:      ALU_op = `ALU_OR;
                    `FUNCT3_AND:     ALU_op = `ALU_AND;
                    `FUNCT3_SLL:     ALU_op = `ALU_SLL;
                    `FUNCT3_SRL_SRA: begin
                        if (funct7 == `FUNCT7_SUB_SRA)
                            ALU_op = `ALU_SRA;
                        else
                            ALU_op = `ALU_SRL;
                    end
                    `FUNCT3_SLT:     ALU_op = `ALU_SLT;
                    `FUNCT3_SLTU:    ALU_op = `ALU_SLTU;
                    default:         ALU_op = `ALU_ADD;
                endcase
            end

            `OP_IMM_LOAD: begin
                RegWrite = 1'b1;
                ALUSrc = 1'b1;
                MemRead = 1'b1;
                MemToReg = 1'b1;
                ALU_op = `ALU_ADD;
                is_load = 1'b1;
            end

            `OP_S_TYPE: begin
                RegWrite = 1'b0;
                ALUSrc   = 1'b1;
                MemWrite = 1'b1;
                ALU_op   = `ALU_ADD;
                is_store = 1'b1;
            end

            `OP_B_TYPE: begin
                branch   = 1'b1;
                RegWrite = 1'b0;
                ALUSrc   = 1'b0;
                ALU_op   = `ALU_SUB;
                is_branch = 1'b1;
            end

            `OP_U_LUI: begin
                RegWrite = 1'b1;
                ALU_op = `ALU_PASS_B;
                ALUSrc = 1'b1;
            end

            `OP_U_AUIPC: begin
                RegWrite = 1'b1;
                ALU_op = `ALU_ADD;
                ALUSrc = 1'b1;
            end

            `OP_J_JAL: begin
                RegWrite = 1'b1;
                ALU_op = `ALU_ADD;
                ALUSrc = 1'b1;
                is_jump = 1'b1;
                is_jal = 1'b1;
            end
            
            `OP_J_JALR: begin
                RegWrite = 1'b1;
                ALU_op = `ALU_ADD;
                ALUSrc = 1'b1;
                is_jump = 1'b1;
                is_jalr = 1'b1;
            end

            default: begin
                // NOP/invalid
            end
        endcase
    end

endmodule