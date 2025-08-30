package isa_defs;

parameter int XLEN = 32;
parameter int NUM_REGS = 32;
parameter int INSTR_WIDTH = 32;
parameter int MEM_SIZE = 1024;

// ALU Opcodes
typedef enum logic [3:0] {
    ALU_ADD  = 4'b0000,
    ALU_SUB  = 4'b0001,
    ALU_SLL  = 4'b0010,
    ALU_SLT  = 4'b0011,
    ALU_SLTU = 4'b0100,
    ALU_XOR  = 4'b0101,
    ALU_SRL  = 4'b0110,
    ALU_SRA  = 4'b0111,
    ALU_OR   = 4'b1000,
    ALU_AND  = 4'b1001
} alu_op_e;

// Opcodes 
typedef enum logic [6:0] {
    OPCODE_OP      = 7'b0110011, // R-Type
    OPCODE_OP_IMM  = 7'b0010011, // I-Type
    OPCODE_LOAD    = 7'b0000011, // I-Type
    OPCODE_STORE   = 7'b0100011, // S-Type
    OPCODE_BRANCH  = 7'b1100011, // B-Type
    OPCODE_JAL     = 7'b1101111, // J-Type
    OPCODE_JALR    = 7'b1100111, // I-Type
    OPCODE_AUIPC   = 7'b0010111, // U-Type
    OPCODE_LUI     = 7'b0110111  // U-Type
} opcode_e;

// fucnt 3 14:12 bitz
typedef enum logic [2:0] {
    FUNCT3_ADD_SUB  = 3'b000, // ADD, SUB, ADDI, BEQ, BNE
    FUNCT3_SLL      = 3'b001, //SLL, SLLI
    FUNCT3_SLT      = 3'b010, // SLT, SLTI
    FUNCT3_SLTU     = 3'b011, // SLTU, SLTIU
    FUNCT3_XOR      = 3'b100, // XOR, XORI
    FUNCT3_SR       = 3'b101, // SRL, SRA, SRLI, SRAI, BGE, BGEU
    FUNCT3_OR       = 3'b110, // OR, ORI, BLT, BLTU
    FUNCT3_AND      = 3'b111  // AND, ANDI
} funct3_e;

// fucny 7 31:25 bit
typedef enum logic [6:0] {
    FUNCT7_ADD_SLT_ETC = 7'b0000000,
    FUNCT7_SUB_SRA     = 7'b0100000
} funct7_e;

typedef enum logic [2:0] {
    ITYPE = 3'b000,
    STYPE = 3'b001,
    BTYPE = 3'b010,
    UTYPE = 3'b011,
    JTYPE = 3'b100,
} imm_gen_e;

// formating  for decoder
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

endpackage : isa_defs