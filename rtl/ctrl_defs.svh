package ctrl_defs;

// ALU operations
typedef enum logic [4:0] {
    ALU_ADD,
    ALU_SUB,
    ALU_AND,
    ALU_OR,
    ALU_XOR,
    ALU_SLL,
    ALU_SRL,
    ALU_SRA,
    ALU_SLT,
    ALU_SLTU,
    ALU_NOP   // default / bubble
} alu_op_e;

// Operand srcs
typedef enum logic [1:0] {
    OP_SRC_RS1,
    OP_SRC_PC,
    OP_SRC_IMM,
    OP_SRC_ZERO
} op_src_e;

// control signals
typedef struct packed {
    alu_op_e      alu_op;
    op_src_e      op_a_sel;     // ALU input A mux
    op_src_e      op_b_sel;     // ALU input B mux
    logic         reg_write;
    logic         mem_read;
    logic         mem_write;
    logic [1:0]   wb_sel;       // writeback source: ALU, MEM, PC+4
    logic         branch;       // isconditional branch
    logic         jump;         // isunconditional jump
    // logic         is_load; // tetsing 
    // logic         is_store;// tesing
} ctrl_signals_t;

endpackage : ctrl_defs;