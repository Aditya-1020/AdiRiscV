`ifndef ISA_DEFS
`define ISA_DEFS

`define XLEN 32
`define NUM_REGS 32
`define MEM_SIZE 1024
`define IMEM_SIZE 1024
`define DMEM_SIZE 1024
`define WORD_ADDRESS 10
`define WORD_BYTES 4
`define RESET_PC 32'h00000000
`define NOP_INSTRUCTION 32'h00000013

// Pipeline
`define PIPE_STAGES 5
`define IF_STAGE 3'b000
`define ID_STAGE 3'b001
`define EX_STAGE 3'b010
`define MEM_STAGE 3'b011
`define WB_STAGE 3'b100

// Pipeline control
`define STALL 1'b1
`define NO_STALL 1'b0
`define FLUSH 1'b1
`define NO_FLUSH 1'b0
`define BUBBLE 1'b1
`define NO_BUBBLE 1'b0

// Forwarding MUX select signals
`define FWD_NONE 2'b00  // No forwarding, use register file
`define FWD_MEM  2'b01  // Forward from MEM stage
`define FWD_WB   2'b10  // Forward from WB stage

// ALU OPCODES
`define ALU_ADD      4'b0000
`define ALU_SUB      4'b0001
`define ALU_SLL      4'b0010
`define ALU_SLT      4'b0011
`define ALU_SLTU     4'b0100
`define ALU_XOR      4'b0101
`define ALU_SRL      4'b0110
`define ALU_SRA      4'b0111
`define ALU_OR       4'b1000
`define ALU_AND      4'b1001
`define ALU_PASS_A   4'b1010
`define ALU_PASS_B   4'b1011

// RV32M
// `define ALU_MUL      4'b1100
// `define ALU_MULH     4'b1101
// `define ALU_MULHU    4'b1110
// `define ALU_MULHSU   4'b1111

// FUNCT3 for M type
// `define FUNCT3_MUL    3'b000
// `define FUNCT3_MULH   3'b001
// `define FUNCT3_MULHSU 3'b010
// `define FUNCT3_MULHU  3'b011
// `define FUNCT3_DIV    3'b100
// `define FUNCT3_DIVU   3'b101
// `define FUNCT3_REM    3'b110
// `define FUNCT3_REMU   3'b111

// FUNCT7 for M type
//`define FUNCT7_MULDIV 7'b0000001

// Instruction OPCODES
`define OP_R_TYPE    7'b0110011
`define OP_IMM       7'b0010011
`define OP_IMM_LOAD  7'b0000011
`define OP_S_TYPE    7'b0100011
`define OP_B_TYPE    7'b1100011
`define OP_J_JAL     7'b1101111
`define OP_J_JALR    7'b1100111
`define OP_U_LUI     7'b0110111
`define OP_U_AUIPC   7'b0010111
`define OP_I_SYSTEM  7'b1110011

// FUNCT3 (R/I Type)
`define FUNCT3_ADD_SUB  3'b000
`define FUNCT3_XOR      3'b100
`define FUNCT3_OR       3'b110
`define FUNCT3_AND      3'b111
`define FUNCT3_SLL      3'b001
`define FUNCT3_SRL_SRA  3'b101
`define FUNCT3_SLT      3'b010
`define FUNCT3_SLTU     3'b011

// FUNCT3 (LOAD/STORE)
`define FUNCT3_LB   3'b000
`define FUNCT3_LH   3'b001
`define FUNCT3_LW   3'b010
`define FUNCT3_LBU  3'b100
`define FUNCT3_LHU  3'b101

`define FUNCT3_SB   3'b000
`define FUNCT3_SH   3'b001
`define FUNCT3_SW   3'b010

// FUNCT3 (BRANCH)
`define FUNCT3_BEQ  3'b000
`define FUNCT3_BNE  3'b001
`define FUNCT3_BLT  3'b100
`define FUNCT3_BGE  3'b101
`define FUNCT3_BLTU 3'b110
`define FUNCT3_BGEU 3'b111

// FUNCT7
`define FUNCT7_ADD_SLL_SLT_SLTU_XOR_SRL_OR_AND 7'b0000000
`define FUNCT7_SUB_SRA 7'b0100000

// Base instruction
`define BASE_OPCODE_MSB 6
`define BASE_OPCODE_LSB 0

// R-TYPE
`define R_FUNCT7_MSB 31
`define R_FUNCT7_LSB 25
`define R_RS2_MSB   24
`define R_RS2_LSB   20
`define R_RS1_MSB   19
`define R_RS1_LSB   15
`define R_FUNCT3_MSB 14
`define R_FUNCT3_LSB 12
`define R_RD_MSB     11
`define R_RD_LSB     7
`define R_OPCODE_MSB 6
`define R_OPCODE_LSB 0

// I-TYPE
`define I_IMM_MSB 31
`define I_IMM_LSB 20
`define I_RS1_MSB 19
`define I_RS1_LSB 15
`define I_FUNCT3_MSB 14
`define I_FUNCT3_LSB 12
`define I_RD_MSB 11
`define I_RD_LSB 7
`define I_OPCODE_MSB 6
`define I_OPCODE_LSB 0

// S-TYPE
`define S_IMM_11_5_MSB 31
`define S_IMM_11_5_LSB 25
`define S_RS2_MSB     24
`define S_RS2_LSB     20
`define S_RS1_MSB     19
`define S_RS1_LSB     15
`define S_FUNCT3_MSB  14
`define S_FUNCT3_LSB  12
`define S_IMM_4_0_MSB 11
`define S_IMM_4_0_LSB 7
`define S_OPCODE_MSB 6
`define S_OPCODE_LSB 0

// B-TYPE
`define B_IMM_12_MSB 31
`define B_IMM_12_LSB 31
`define B_IMM_10_5_MSB 30
`define B_IMM_10_5_LSB 25
`define B_RS2_MSB 24
`define B_RS2_LSB 20
`define B_RS1_MSB 19
`define B_RS1_LSB 15
`define B_FUNCT3_MSB 14
`define B_FUNCT3_LSB 12
`define B_IMM_4_1_MSB 11
`define B_IMM_4_1_LSB 8
`define B_IMM_11_MSB 7
`define B_IMM_11_LSB 7
`define B_OPCODE_MSB 6
`define B_OPCODE_LSB 0

// U-TYPE
`define U_IMM_MSB 31
`define U_IMM_LSB 12
`define U_RD_MSB 11
`define U_RD_LSB 7
`define U_OPCODE_MSB 6
`define U_OPCODE_LSB 0

// J-TYPE
`define J_IMM_20_MSB 31
`define J_IMM_20_LSB 31
`define J_IMM_10_1_MSB 30
`define J_IMM_10_1_LSB 21
`define J_IMM_11_MSB 20
`define J_IMM_11_LSB 20
`define J_IMM_19_12_MSB 19
`define J_IMM_19_12_LSB 12
`define J_RD_MSB 11
`define J_RD_LSB 7
`define J_OPCODE_MSB 6
`define J_OPCODE_LSB 0

// BRANCH PREDICTION
`define BTB_SIZE 64
`define BTB_INDEX_WIDTH 6
`define RAS_SIZE 8
`define RAS_PTR_WIDTH 3
`define BTB_CACHE_WIDTH (32 - `BTB_INDEX_WIDTH - 2)

// Branch predictor states (2-bit saturating counter)
`define PRED_STRONG_NOT_TAKEN 2'b00
`define PRED_WEAK_NOT_TAKEN   2'b01
`define PRED_WEAK_TAKEN       2'b10
`define PRED_STRONG_TAKEN     2'b11


// CACHE PARAMETERS
`define ICACHE_SIZE 512        // 512 bytes
`define ICACHE_LINE_SIZE 16    // 16 bytes per line (4 words)
`define ICACHE_NUM_LINES 32    // 512/16 = 32 lines
`define ICACHE_INDEX_WIDTH 5   // log2(32)
`define ICACHE_OFFSET_WIDTH 4  // log2(16)
`define ICACHE_TAG_WIDTH 23    // 32 - 5 - 4

// Cache states
`define CACHE_INVALID 1'b0
`define CACHE_VALID   1'b1

// CONTROL SIGNAL BUNDLE WIDTH
// Used for pipeline registers to pass control signals
// Format: {RegWrite, MemToReg, MemWrite, MemRead, ALUSrc, Branch, ALU_op[3:0]}
`define CTRL_WIDTH 10


// HAZARD DETECTION
`define LOAD_USE_HAZARD 1'b1
`define NO_LOAD_USE_HAZARD 1'b0

// PERFORMANCE COUNTERS
`define PERF_COUNTER_WIDTH 32

`endif