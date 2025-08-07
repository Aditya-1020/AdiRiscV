`ifndef DEFINES_SV
`define DEFINES_SV

// U-type
`define OPCODE_LUI    7'b0110111 // Load upper immediate
`define OPCODE_AUIPC  7'b0010111 // add upper immediate to PC

// J-type
`define OPCODE_JAL 7'b1101111 // Jump and Link

// I-type
`define OPCODE_JALR 7'b1100111 // Jump and Link register
`define OPCODE_LOAD 7'b0000011 // load from memory
`define OPCODE_IMM  7'b0010011 // ALU op with immediate

// S-Type
`define OPCODE_STORE   7'b0100011 // store to memory

// B-type
`define OPCODE_BRANCH  7'b1100011 // branches (BEQ, BNE, etc)

// R-type
`define OPCODE_OP 7'b0110011 // ALU op with registers

// Arithmetic
`define ALU_ADD  4'b0000
`define ALU_SUB  4'b0001

// set Les than
`define ALU_SLT  4'b1000 // Signed comparison
`define ALU_SLTU 4'b1001 // Unsigned comparison

// shifts
`define ALU_SLL 4'b0101 // Shift Left Logical
`define ALU_SRL 4'b0110 // Shift Right Logical
`define ALU_SRA 4'b0111 // Shift Right Arithmetic

// Logical
`define ALU_AND  4'b0010
`define ALU_OR   4'b0011
`define ALU_XOR  4'b0100

typedef struct packed {
    logic reg_write;
    logic mem_read;
    logic mem_write;
    logic alu_src;
    logic mem_to_reg;
    logic [3:0] alu_op;
    logic branch;
    logic jump;
} control_t;

`endif