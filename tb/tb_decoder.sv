import riscv_pkg::*;

module tb_decoder;

    timeunit 1ns;
    timeprecision 1ps;

    logic [XLEN-1:0] instruction;
    ctrl_signals_t ctrl;

    decoder dut (
        .instruction(instruction),
        .ctrl(ctrl)
    );

    function logic [XLEN-1:0] encode_r_type(
        input logic [6:0] opcode,
        input logic [4:0] rd, rs1, rs2,
        input logic [2:0] funct3,
        input logic [6:0] funct7
    );
        encode_r_type = {funct7, rs2, rs1, funct3, rd, opcode};
    endfunction

    function logic [XLEN-1:0] encode_i_type(
        input logic [6:0] opcode,
        input logic [4:0] rd, rs1,
        input logic [2:0] funct3,
        input logic [11:0] imm
    );
        encode_i_type = {imm, rs1, funct3, rd, opcode};
    endfunction

    function logic [XLEN-1:0] encode_s_type(
        input logic [6:0] opcode,
        input logic [4:0] rs1, rs2,
        input logic [2:0] funct3,
        input logic [11:0] imm
    );
        encode_s_type = {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode};
    endfunction

    function logic [XLEN-1:0] encode_b_type(
        input logic [6:0] opcode,
        input logic [4:0] rs1, rs2,
        input logic [2:0] funct3,
        input logic [12:0] imm
    );
        encode_b_type = {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], opcode};
    endfunction

    function logic [XLEN-1:0] encode_u_type(
        input logic [6:0] opcode,
        input logic [4:0] rd,
        input logic [31:0] imm
    );
        encode_u_type = {imm[31:12], rd, opcode};
    endfunction

    function logic [XLEN-1:0] encode_j_type(
        input logic [6:0] opcode,
        input logic [4:0] rd,
        input logic [20:0] imm
    );
        encode_j_type = {imm[20], imm[10:1], imm[11], imm[19:12], rd, opcode};
    endfunction

    task automatic test_instruction(
        input string name,
        input logic [XLEN-1:0] instr,
        input ctrl_signals_t expected
    );
        instruction = instr;
        #1;

        if (ctrl !== expected) begin
            $display("FAIL: %s", name);
            $display("  Expected: reg_write=%b mem_read=%b mem_write=%b alu_src=%b alu_op=%s mem_op=%s", 
                     expected.reg_write, expected.mem_read, expected.mem_write, expected.alu_src, expected.alu_op.name(), expected.mem_op.name());
            $display("  Got: reg_write=%b mem_read=%b mem_write=%b alu_src=%b alu_op=%s mem_op=%s", 
                    ctrl.reg_write, ctrl.mem_read, ctrl.mem_write, ctrl.alu_src, ctrl.alu_op.name(), ctrl.mem_op.name());
        end else begin
            $display("PASS: %s", name);
        end
    endtask

    initial begin
        $dumpfile("decoder.vcd");
        $dumpvars(0, tb_decoder);
        
        test_instruction("ADD", encode_r_type(OP_OP, 1, 2, 3, F3_ADD_SUB, 7'h00),
            '{reg_write:1'b1, mem_read:1'b0, mem_write:1'b0, mem_to_reg:1'b0,alu_src:1'b0, is_branch:1'b0, is_jump:1'b0, is_jalr:1'b0,
              alu_op:ALU_ADD, mem_op:MEM_WORD});
    
        test_instruction("SUB", encode_r_type(OP_OP, 5, 6, 7, F3_ADD_SUB, F7_ALT),
            '{reg_write:1'b1, mem_read:1'b0, mem_write:1'b0, mem_to_reg:1'b0, alu_src:1'b0, is_branch:1'b0, is_jump:1'b0, is_jalr:1'b0,
              alu_op:ALU_SUB, mem_op:MEM_WORD});
        
        test_instruction("ADDI", encode_i_type(OP_IMM, 1, 2, F3_ADD_SUB, 12'd123),
            '{reg_write:1'b1, mem_read:1'b0, mem_write:1'b0, mem_to_reg:1'b0,alu_src:1'b1, is_branch:1'b0, is_jump:1'b0, is_jalr:1'b0,
              alu_op:ALU_ADD, mem_op:MEM_WORD});
        
        test_instruction("LW", encode_i_type(OP_LOAD, 1, 2, F3_LW, 12'd8),
            '{reg_write:1'b1, mem_read:1'b1, mem_write:1'b0, mem_to_reg:1'b1,alu_src:1'b1, is_branch:1'b0, is_jump:1'b0, is_jalr:1'b0,
              alu_op:ALU_ADD, mem_op:MEM_WORD});
        
        test_instruction("SW", encode_s_type(OP_STORE, 4, 3, F3_SW, 12'd12),
            '{reg_write:1'b0, mem_read:1'b0, mem_write:1'b1, mem_to_reg:1'b0, alu_src:1'b1, is_branch:1'b0, is_jump:1'b0, is_jalr:1'b0,
              alu_op:ALU_ADD, mem_op:MEM_WORD});
        
        test_instruction("BEQ", encode_b_type(OP_BRANCH, 1, 2, F3_BEQ, 13'd8),
            '{reg_write:1'b0, mem_read:1'b0, mem_write:1'b0, mem_to_reg:1'b0, alu_src:1'b0, is_branch:1'b1, is_jump:1'b0, is_jalr:1'b0,
              alu_op:ALU_ADD, mem_op:MEM_WORD});
        
        // JAL x1, +100
        test_instruction("JAL", 
            encode_j_type(OP_JAL, 1, 21'd100),
            '{reg_write:1'b1, mem_read:1'b0, mem_write:1'b0, mem_to_reg:1'b0,
              alu_src:1'b1, is_branch:1'b0, is_jump:1'b1, is_jalr:1'b0,
              alu_op:ALU_ADD, mem_op:MEM_WORD});
        
        test_instruction("JALR", encode_i_type(OP_JALR, 1, 2, 3'h0, 12'd4),
            '{reg_write:1'b1, mem_read:1'b0, mem_write:1'b0, mem_to_reg:1'b0, alu_src:1'b1, is_branch:1'b0, is_jump:1'b1, is_jalr:1'b1,
              alu_op:ALU_ADD, mem_op:MEM_WORD});

        test_instruction("LUI", encode_u_type(OP_LUI, 1, 32'h12345000),
            '{reg_write:1'b1, mem_read:1'b0, mem_write:1'b0, mem_to_reg:1'b0,alu_src:1'b1, is_branch:1'b0, is_jump:1'b0, is_jalr:1'b0,
              alu_op:ALU_PASS_B, mem_op:MEM_WORD});

        test_instruction("AUIPC", encode_u_type(OP_AUIPC, 1, 32'h12345000), 
            '{reg_write:1'b1, mem_read:1'b0, mem_write:1'b0, mem_to_reg:1'b0, alu_src:1'b1, is_branch:1'b0, is_jump:1'b0, is_jalr:1'b0,
              alu_op:ALU_ADD, mem_op:MEM_WORD});

        $display("\nAll tests completed!");
        $finish;
    end

    initial begin
        #10000;
        $error("TIMEOUT: Testbench did not complete in time");
        $finish;
    end
    
endmodule