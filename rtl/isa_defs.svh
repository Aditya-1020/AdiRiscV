package isa_defs;

parameter int XLEN = 32;
parameter int NUM_REGS = 32;
parameter int REG_ADDR_WIDTH = $clog2(NUM_REGS);
parameter int INSTR_WIDTH = 32;

// Opcodes
typedef enum logic [6:0] {
  OPCODE_OP      = 7'b0110011, // R-Type
  OPCODE_OP_IMM  = 7'b0010011, // I-Type ALU
  OPCODE_LOAD    = 7'b0000011, // I-Type load
  OPCODE_STORE   = 7'b0100011, // S-Type
  OPCODE_BRANCH  = 7'b1100011, // B-Type
  OPCODE_JAL     = 7'b1101111, // J-Type
  OPCODE_JALR    = 7'b1100111, // I-Type JALR
  OPCODE_AUIPC   = 7'b0010111, // U-Type
  OPCODE_LUI     = 7'b0110111  // U-Type
} opcode_e;

// FUNCT3
typedef enum logic [2:0] {
  FUNCT3_000 = 3'b000, // ADD/SUB, ADDI, BEQ
  FUNCT3_001 = 3'b001, // SLL, SLLI
  FUNCT3_010 = 3'b010, // SLT, SLTI, LW
  FUNCT3_011 = 3'b011, // SLTU, SLTIU
  FUNCT3_100 = 3'b100, // XOR, XORI
  FUNCT3_101 = 3'b101, // SRL/SRA, SRLI/SRAI, BGE, BGEU
  FUNCT3_110 = 3'b110, // OR, ORI, BLTU
  FUNCT3_111 = 3'b111  // AND, ANDI, BGEU
} funct3_e;

// FUNCT7
typedef enum logic [6:0] {
  FUNCT7_STD  = 7'b0000000,
  FUNCT7_SUB  = 7'b0100000
} funct7_e;

// Instruction fomrats
typedef struct packed {
  logic [6:0] funct7;
  logic [4:0] rs2, rs1;
  logic [2:0] funct3;
  logic [4:0] rd;
  logic [6:0] opcode;
} rv_r_type_t;

typedef struct packed {
  logic [11:0] imm;
  logic [4:0] rs1;
  logic [2:0] funct3;
  logic [4:0] rd;
  logic [6:0] opcode;
} rv_i_type_t;

typedef struct packed {
  logic [6:0] imm_11_5;
  logic [4:0] rs2, rs1;
  logic [2:0] funct3;
  logic [4:0] imm_4_0;
  logic [6:0] opcode;
} rv_s_type_t;

typedef struct packed {
  logic        imm_12;
  logic [5:0]  imm_10_5;
  logic [4:0]  rs2, rs1;
  logic [2:0]  funct3;
  logic [3:0]  imm_4_1;
  logic        imm_11;
  logic [6:0]  opcode;
} rv_b_type_t;

typedef struct packed {
  logic        imm_20;
  logic [9:0]  imm_10_1;
  logic        imm_11;
  logic [7:0]  imm_19_12;
  logic [4:0]  rd;
  logic [6:0]  opcode;
} rv_j_type_t;

typedef struct packed {
  logic [19:0] imm;
  logic [4:0]  rd;
  logic [6:0]  opcode;
} rv_u_type_t;

// Immediate extract

function automatic logic signed [XLEN-1:0] imm_i (rv_i_type_t inst);
  return {{20{inst.imm[11]}}, inst.imm};
endfunction

function automatic logic signed [XLEN-1:0] imm_s (rv_s_type_t inst);
  return {{20{inst.imm_11_5[6]}}, inst.imm_11_5, inst.imm_4_0};
endfunction

function automatic logic signed [XLEN-1:0] imm_b (rv_b_type_t inst);
  return {{19{inst.imm_12}}, inst.imm_12, inst.imm_10_5, inst.imm_4_1, inst.imm_11, 1'b0};
endfunction

function automatic logic signed [XLEN-1:0] imm_u (rv_u_type_t inst);
  return {inst.imm, 12'b0};
endfunction

function automatic logic signed [XLEN-1:0] imm_j (rv_j_type_t inst);
  return {{11{inst.imm_20}}, inst.imm_20, inst.imm_19_12, inst.imm_11, inst.imm_10_1, 1'b0};
endfunction


endpackage : isa_defs