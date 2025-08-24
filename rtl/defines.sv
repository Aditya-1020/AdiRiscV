package isa_defs;

// Opcodes
localparam OPCODE_OP      = 7'b0110011; // R-Type (ADD, SUB, AND, OR, XOR, SLT)
localparam OPCODE_OP_IMM  = 7'b0010011; // I-Type (ADDI, etc.)
localparam OPCODE_LOAD    = 7'b0000011; // I-Type (LW)
localparam OPCODE_STORE   = 7'b0100011; // S-Type (SW)
localparam OPCODE_BRANCH  = 7'b1100011; // B-Type (BEQ)
localparam OPCODE_JAL     = 7'b1101111; // J-Type (JAL)
localparam OPCODE_JALR    = 7'b1100111; // I-Type (JALR)
localparam OPCODE_AUIPC   = 7'b0010111; // U-Type (AUIPC)
localparam OPCODE_LUI     = 7'b0110111; // U-Type (LUI)

// FUNCT3
localparam FUNCT3_ADD_SUB = 3'b000;
localparam FUNCT3_AND     = 3'b111;
localparam FUNCT3_OR      = 3'b110;
localparam FUNCT3_XOR     = 3'b100;
localparam FUNCT3_SLT     = 3'b010;
localparam FUNCT3_ADDI    = 3'b000;
localparam FUNCT3_LW      = 3'b010;
localparam FUNCT3_SW      = 3'b010;
localparam FUNCT3_BEQ     = 3'b000;

// FUNCT7
localparam FUNCT7_ADD = 7'b0000000;
localparam FUNCT7_SUB = 7'b0100000;

// R-Type packed
typedef struct packed {
  logic [6:0] funct7;
  logic [4:0] rs2;
  logic [4:0] rs1;
  logic [2:0] funct3;
  logic [4:0] rd;
  logic [6:0] opcode;
} rv_r_type_t;

// I-Type packed
typedef struct packed {
  logic [11:0] imm;
  logic [4:0]  rs1;
  logic [2:0]  funct3;
  logic [4:0]  rd;
  logic [6:0]  opcode;
} rv_i_type_t;

// S-Type packed
typedef struct packed {
  logic [6:0] imm_11_5;
  logic [4:0] rs2;
  logic [4:0] rs1;
  logic [2:0] funct3;
  logic [4:0] imm_4_0;
  logic [6:0] opcode;
} rv_s_type_t;

// B-Type packed
typedef struct packed {
  logic       imm_12;
  logic [5:0] imm_10_5;
  logic [4:0] rs2;
  logic [4:0] rs1;
  logic [2:0] funct3;
  logic [3:0] imm_4_1;
  logic       imm_11;
  logic [6:0] opcode;
} rv_b_type_t;

// J-Type packed
typedef struct packed {
  logic       imm_20;
  logic [9:0] imm_10_1;
  logic       imm_11;
  logic [7:0] imm_19_12;
  logic [4:0] rd;
  logic [6:0] opcode;
} rv_j_type_t;

// U-Type packed
typedef struct packed {
  logic [19:0] imm;
  logic [4:0]  rd;
  logic [6:0]  opcode;
} rv_u_type_t;


endpackage