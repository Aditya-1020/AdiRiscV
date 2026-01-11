import riscv_pkg::*;

module decoder(
    input logic [XLEN-1:0] instruction,
    output ctrl_signals_t ctrl
);

    timeunit 1ns;
    timeprecision 1ps;

    opcode_e opcode;
    logic [2:0] funct3_bits;
    logic [6:0] funct7_bits;

    assign opcode = opcode_e'(instruction[6:0]);
    assign funct3_bits = instruction[14:12];
    assign funct7_bits = instruction[31:25];

    always_comb begin
        ctrl = '{
            reg_write: 1'b0,
            mem_read: 1'b0,
            mem_write: 1'b0,
            mem_to_reg: 1'b0,
            alu_src: 1'b0,
            is_branch: 1'b0,
            is_jump: 1'b0,
            is_jalr: 1'b0,
            alu_op: ALU_ADD,
            mem_op: MEM_WORD
        };

        case (opcode)
            OP_OP: begin // R-type
                funct3_alu_e aluf3 = funct3_alu_e'(funct3_bits);
                    case (aluf3)
                        F3_ADD_SUB: ctrl.alu_op = (funct7_bits == F7_ALT) ? ALU_SUB : ALU_ADD;
                        F3_SLL: ctrl.alu_op = ALU_SLL;
                        F3_SLT: ctrl.alu_op = ALU_SLT;
                        F3_SLTU: ctrl.alu_op = ALU_SLTU;
                        F3_XOR: ctrl.alu_op = ALU_XOR;
                        F3_SRL_SRA: ctrl.alu_op = (funct7_bits == F7_ALT) ? ALU_SRA : ALU_SRL;
                        F3_OR: ctrl.alu_op = ALU_OR;
                        F3_AND: ctrl.alu_op = ALU_AND;
                        default: ALU_ADD;
                    endcase
                end

            OP_IMM: begin // I-type
                ctrl.reg_write = 1'b1;
                ctrl.alu_src = 1'b1; // use immediate
                funct3_alu_e aluf3 = funct3_alu_e'(funct3_bits);
                    case (aluf3)
                        F3_ADD_SUB: ctrl.alu_op = ALU_ADD; // ADDI
                        F3_SLL: ctrl.alu_op = ALU_SLL;
                        F3_SLT: ctrl.alu_op = ALU_SLT;
                        F3_SLTU: ctrl.alu_op = ALU_SLTU;
                        F3_XOR: ctrl.alu_op = ALU_XOR;
                        F3_SRL_SRA: ctrl.alu_op = (funct7_bits == F7_ALT) ? ALU_SRA : ALU_SRL;
                        F3_OR: ctrl.alu_op = ALU_OR;
                        F3_AND: ctrl.alu_op = ALU_AND;
                        default: ctrl.alu_op = ALU_ADD;
                    endcase
                end
            
            OP_LOAD: begin
                ctrl.reg_write = 1'b1;
                ctrl.mem_read = 1'b1;
                ctrl.mem_to_reg = 1'b1;
                ctrl.alu_src = 1'b1;
                ctrl.alu_op = ALU_ADD;

                funct3_load_e loadf3 = funct3_load_e'(funct3_bits);
                    case (loadf3)
                        F3_LB: crtl.mem_op = MEM_BYTE;
                        F3_LH: crtl.mem_op = MEM_HALF;
                        F3_LW: crtl.mem_op = MEM_WORD;
                        F3_LBU: crtl.mem_op = MEM_BYTE_U;
                        F3_LHU: crtl.mem_op = MEM_HALF_U;
                        default: ctrl.mem_op = MEM_WORD;
                    endcase
                end
            
            OP_STORE: begin
                ctrl.mem_write = 1'b1;
                ctrl.alu_src = 1'b1;
                ctrl.alu_op = ALU_ADD;

                funct3_store_e storef3 = funct3_store_e'(funct3_bits);
                    case (storef3)
                        F3_SB: ctrl.mem_op = MEM_BYTE;
                        F3_SH: ctrl.mem_op = MEM_HALF;
                        F3_SW: ctrl.mem_op = MEM_WORD;
                        default: ctrl.mem_op = MEM_WORD;
                    endcase
                end

            OP_BRANCH: begin
                ctrl.is_branch = 1'b1;
                ctrl.alu_src = 1'b0;
                // handled by branch_unit.sv for FUNCT3
            end

            OP_JAL: begin
                ctrl.reg_write = 1'b1;
                ctrl.is_jump = 1'b1;
                ctrl.alu_src = 1'b1;
                ctrl.alu_op = ALU_ADD; // pc + imm 
            end

            OP_JALR: begin
                ctrl.reg_write = 1'b1;
                ctrl.is_jump = 1'b1;
                ctrl.is_jalr = 1'b1;
                ctrl.alu_src = 1'b1;
                ctrl.alu_op = ALU_ADD // rs1 + imm
            end

            OP_LUI: begin
                ctrl.reg_write = 1'b1;
                ctrl.alu_src = 1'b1;
                ctrl.alu_op = ALU_PASS_B;
            end

            OP_AUIPC: begin
                ctrl.reg_write= 1'b1;
                ctrl.alu_src = 1'b1;
                ctrl.alu_op = ALU_ADD; // pc + imm
            end
            
            // OP_SYSTEM: begin
                //need to add its funct3's 
            // end
            
            default: begin
                // NOP
            end
        endcase
    end


endmodule