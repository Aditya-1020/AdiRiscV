`timescale 1ns / 1ps
`include "defines.sv"

module decoder (
    
    input logic [31:0] instructions,
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    input logic [4:0] rd,
    input logic [4:0] immediate,

    // input logic [6:0] opcode,
    // input logic [2:0] funct3,
    // input logic [6:0] funct7,
    output control_t control
)

logic [6:0] opcode;
logic [2:0] funct3;
logic [6:0] funct7;

assign opcode = instructions[6:0];
assign rd = instructions[11:7];
assing rs1 = instructions[19:15];
assing rs2 = instructions[24:20];
assign funct3 = instructions[14:12];
assign funct7 = instructions[31:25];

// immediate
always_comb begin
    case(opcode)
        `OPCODE_LUI, `OPCODE_AUIPC: begin
            // U_TYPE
            immediate = {instructions[31:12], 12'b0};
        end

        `OPCODE_JAL: begin
            // J_TYPE
            immediate = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};
        end

        `OPCODE_JALR, `OPCODE_LOAD, `OPCODE_IMM: begin
            // I_TYPE
            immediate = {{20{instruction[31]}}, instruction[31:20]};
        end

        `OPCODE_STORE begin
            // S_TYPe
            immediate = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
        end

        `OPCODE_BRANCH begin
            // B_TPYE
            immediate = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
        end

        default: immediate = 32'b0;
    endcase
end

// CONStrol signal
always_comb begin
    control.reg_write = 1'b0;
    control.mem_read = 1'b0;
    control.mem_write = 1'b0;
    control.alu_src = 1'b0;
    control.mem_to_reg = 1'b0;
    control.alu_op = = `ALU_ADD;
    control.branch = 1'b0;
    control.jump = 1'b0;

    case(opcode)
        `OPCODE_LUI: begin
            control.reg_write = 1'b1;
            control.alu_src = 1'b1;
            control.alu_op = `ALU_ADD; // 0+imm
        end
        
        `OPCODE_AUIPC: begin
            control.reg_write = 1'b1;
            control.alu_src = 1'b1;
            control.alu_op = `ALU_ADD; // PC+imm
        end

        `OPCODE_JAL: begin
            control.reg_write = 1'b1;
            control.jump = 1'b1;
        end

        `OPCODE_JALR: begin
            control.reg_write = 1'b1;
            control.alu_src = 1'b1;
            control.jump = 1'b1;
            control.alu_op = `ALU_ADD; // rs1 + imm for targt
        end
        
        `OPCODE_LOAD: begin
            control.reg_write  = 1'b1;
            control.mem_read   = 1'b1;
            control.alu_src    = 1'b1;
            control.mem_to_reg = 1'b1;
            control.alu_op     = `ALU_ADD;  // rs1 + imm for address
        end
        
        `OPCODE_STORE: begin
            control.mem_write = 1'b1;
            control.alu_src   = 1'b1;
            control.alu_op    = `ALU_ADD;  // rs1 + imm for address
        end

        `OPCODE_BRANCH: begin
            control.branch = 1'b1;
            case(funct3)
                3'b000: control.alu_op = `ALU_SUB;  // BEQ
                3'b001: control.alu_op = `ALU_SUB;  // BNE
                3'b100: control.alu_op = `ALU_SLT;  // BLT
                3'b101: control.alu_op = `ALU_SLT;  // BGE (negated)
                3'b110: control.alu_op = `ALU_SLTU; // BLTU
                3'b111: control.alu_op = `ALU_SLTU; // BGEU (negated)
                default: control.alu_op = `ALU_SUB;
            endcase
        end

        `OPCODE_IMM: begin
            control.reg_write = 1'b1;
            control.alu_src   = 1'b1;
            case(funct3)
                3'b000: control.alu_op = `ALU_ADD;  // ADDI
                3'b010: control.alu_op = `ALU_SLT;  // SLTI
                3'b011: control.alu_op = `ALU_SLTU; // SLTIU
                3'b100: control.alu_op = `ALU_XOR;  // XORI
                3'b110: control.alu_op = `ALU_OR;   // ORI
                3'b111: control.alu_op = `ALU_AND;  // ANDI
                3'b001: control.alu_op = `ALU_SLL;  // SLLI
                3'b101: begin
                    if (instruction[30])
                        control.alu_op = `ALU_SRA;  // SRAI
                    else
                        control.alu_op = `ALU_SRL;  // SRLI
                end
                default: control.alu_op = `ALU_ADD;
            endcase
        end

        `OPCODE_OP: begin
            control.reg_write = 1'b1;
            control.alu_src   = 1'b0;  // Use register for second operand
            case(funct3)
                3'b000: begin
                    // ADD or SUB - check bit 30
                    if (funct7[5])
                        control.alu_op = `ALU_SUB;  // SUB
                    else
                        control.alu_op = `ALU_ADD;  // ADD
                end
                3'b001: control.alu_op = `ALU_SLL;  // SLL
                3'b010: control.alu_op = `ALU_SLT;  // SLT
                3'b011: control.alu_op = `ALU_SLTU; // SLTU
                3'b100: control.alu_op = `ALU_XOR;  // XOR
                3'b101: begin
                    // SRL or SRA - check bit 30
                    if (funct7[5])
                        control.alu_op = `ALU_SRA;  // SRA
                    else
                        control.alu_op = `ALU_SRL;  // SRL
                end
                3'b110: control.alu_op = `ALU_OR;   // OR
                3'b111: control.alu_op = `ALU_AND;  // AND
                default: control.alu_op = `ALU_ADD;
            endcase
        end
        default: begin
            // all set to 0 pre case
        end
    endcase
end

endmodule