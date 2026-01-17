// RISC-V RV32I Package - SystemVerilog

package riscv_pkg;

    timeunit 1ns; timeprecision 1ps;

    // Basic Architecture Parameters
    parameter int XLEN = 32;
    parameter int XLEN_DOUBLE = 64;
    parameter REG_ADDR_WIDTH = 5;
    parameter int NUM_REGS = 2**REG_ADDR_WIDTH; // 32
    parameter int IMEM_SIZE = 1024;      // Instructions (words)
    parameter int DMEM_SIZE = 4096;      // Data (bytes)
    parameter int WORD_ADDR_WIDTH = 10;
    parameter int BYTE_ADDR_WIDTH = 12;
    parameter int COUNT_SIZE_DIVISOR = $clog2(XLEN);
    
    parameter logic [XLEN-1:0] RESET_PC = 32'h00000000;
    parameter logic [XLEN-1:0] RESET_REG = 32'h00000000;
    parameter logic [XLEN-1:0] NOP_INSTR = 32'h00000013;  // ADDI x0, x0, 0

    // Instruction Opcodes (7-bit)
    typedef enum logic [6:0] {
        OP_LOAD     = 7'b0000011,
        OP_STORE    = 7'b0100011,
        OP_BRANCH   = 7'b1100011,
        OP_JALR     = 7'b1100111,
        OP_JAL      = 7'b1101111,
        OP_IMM      = 7'b0010011,
        OP_OP       = 7'b0110011,
        OP_AUIPC    = 7'b0010111,
        OP_LUI      = 7'b0110111,
        OP_SYSTEM   = 7'b1110011
    } opcode_e;

    // Instruction Format Types
    typedef enum logic [2:0] {
        FMT_R,      // R-type: register-register
        FMT_I,      // I-type: immediate
        FMT_S,      // S-type: store
        FMT_B,      // B-type: branch
        FMT_U,      // U-type: upper immediate
        FMT_J       // J-type: jump
    } instr_fmt_e;

    // ALU Operations
    typedef enum logic [4:0] {
        // Base RV32I ALU operations
        ALU_ADD     = 5'b00000,
        ALU_SUB     = 5'b00001,
        ALU_SLL     = 5'b00010,
        ALU_SLT     = 5'b00011,
        ALU_SLTU    = 5'b00100,
        ALU_XOR     = 5'b00101,
        ALU_SRL     = 5'b00110,
        ALU_SRA     = 5'b00111,
        ALU_OR      = 5'b01000,
        ALU_AND     = 5'b01001,
        ALU_PASS_A  = 5'b01010,  // For AUIPC
        ALU_PASS_B  = 5'b01011,  // For LUI
        
        // M Extension - Multiply
        ALU_MUL     = 5'b10000,
        ALU_MULH    = 5'b10001,
        ALU_MULHSU  = 5'b10010,
        ALU_MULHU   = 5'b10011,
        
        // M Extension - Divide/Remainder
        ALU_DIV     = 5'b10100,
        ALU_DIVU    = 5'b10101,
        ALU_REM     = 5'b10110,
        ALU_REMU    = 5'b10111 
    } alu_op_e;

    
    // FUNCT3 for ALU operations (R-type and I-type)
    typedef enum logic [2:0] {
        F3_ADD_SUB  = 3'b000,
        F3_SLL      = 3'b001,
        F3_SLT      = 3'b010,
        F3_SLTU     = 3'b011,
        F3_XOR      = 3'b100,
        F3_SRL_SRA  = 3'b101,
        F3_OR       = 3'b110,
        F3_AND      = 3'b111
    } funct3_alu_e;

    // FUNCT3 for M Extension operations
    typedef enum logic [2:0] {
        F3_MUL      = 3'b000,
        F3_MULH     = 3'b001,
        F3_MULHSU   = 3'b010,
        F3_MULHU    = 3'b011,
        F3_DIV      = 3'b100,
        F3_DIVU     = 3'b101,
        F3_REM      = 3'b110,
        F3_REMU     = 3'b111
    } funct3_m_e;
    
    // FUNCT3 for Load operations
    typedef enum logic [2:0] {
        F3_LB       = 3'b000,
        F3_LH       = 3'b001,
        F3_LW       = 3'b010,
        F3_LBU      = 3'b100,
        F3_LHU      = 3'b101
    } funct3_load_e;
    
    // FUNCT3 for Store operations
    typedef enum logic [2:0] {
        F3_SB       = 3'b000,
        F3_SH       = 3'b001,
        F3_SW       = 3'b010
    } funct3_store_e;
    
    // FUNCT3 for Branch operations
    typedef enum logic [2:0] {
        F3_BEQ      = 3'b000,
        F3_BNE      = 3'b001,
        F3_BLT      = 3'b100,
        F3_BGE      = 3'b101,
        F3_BLTU     = 3'b110,
        F3_BGEU     = 3'b111
    } funct3_branch_e;

    // Function 7 Fields (7-bit)
    typedef enum logic [6:0] {
        F7_NORMAL   = 7'b0000000,
        F7_ALT      = 7'b0100000,   // For SUB and SRA
        F7_MULDIV   = 7'b0000001   // M Extension instr compare
    } funct7_e;

    // Memory Operations (Load/Store Unit)
    typedef enum logic [2:0] {
        MEM_BYTE,       // LB/SB
        MEM_HALF,       // LH/SH
        MEM_WORD,       // LW/SW
        MEM_BYTE_U,     // LBU
        MEM_HALF_U      // LHU
    } mem_op_e;

    // Branch Operations
    typedef enum logic [2:0] {
        BR_EQ       = 3'b000,
        BR_NE       = 3'b001,
        BR_LT       = 3'b100,
        BR_GE       = 3'b101,
        BR_LTU      = 3'b110,
        BR_GEU      = 3'b111
    } branch_op_e;

    // Pipeline Control Signals Structure
    typedef struct packed {
        logic           reg_write;      // Write to register file
        logic           mem_read;       // Memory read enable
        logic           mem_write;      // Memory write enable
        logic           mem_to_reg;     // Select memory data for writeback
        logic           alu_src;        // ALU source: 0=reg, 1=imm
        logic           is_branch;      // Is branch instruction
        logic           is_jump;        // Is jump instruction (JAL/JALR)
        logic           is_jalr;        // Is JALR specifically
        alu_op_e        alu_op;         // ALU operation
        mem_op_e        mem_op;         // Memory operation type
    } ctrl_signals_t;

    // Pipeline Stage Definitions
    typedef enum logic [2:0] {
        STAGE_IF    = 3'b000,
        STAGE_ID    = 3'b001,
        STAGE_EX    = 3'b010,
        STAGE_MEM   = 3'b011,
        STAGE_WB    = 3'b100
    } pipe_stage_e;

    // Forwarding Control
    typedef enum logic [1:0] {
        FWD_NONE    = 2'b00,    // No forwarding (use RF)
        FWD_WB      = 2'b01,    // Forward from WB stage
        FWD_MEM     = 2'b10     // Forward from MEM stage
    } forward_src_e;

    // Branch Prediction
    
    // Branch Target Buffer parameters
    parameter int BTB_SIZE = 64;
    parameter int BTB_INDEX_WIDTH = $clog2(BTB_SIZE);
    parameter int BTB_TAG_WIDTH = XLEN - BTB_INDEX_WIDTH - 2;
    
    // Return Address Stack parameters
    parameter int RAS_SIZE = 8;
    parameter int RAS_PTR_WIDTH = $clog2(RAS_SIZE);
    
    // Branch prediction state (2-bit saturating counter)
    typedef enum logic [1:0] {
        PRED_STRONG_NOT_TAKEN   = 2'b00,
        PRED_WEAK_NOT_TAKEN     = 2'b01,
        PRED_WEAK_TAKEN         = 2'b10,
        PRED_STRONG_TAKEN       = 2'b11
    } branch_pred_state_e;
    
    // Branch prediction result structure
    typedef struct packed {
        logic               valid;
        logic               taken;
        logic [XLEN-1:0]    target;
        branch_pred_state_e state;
    } branch_pred_t;

    // Hazard Detection
    typedef struct packed {
        logic load_use;         // Load-use hazard detected
        logic control;          // Control hazard (branch/jump)
        logic structural;       // Structural hazard (future: cache miss)
        logic division; // Division stall (M extension)
    } hazard_t;

    // Cache Parameters
    parameter int ICACHE_SIZE = 512;            // 512 bytes
    parameter int ICACHE_LINE_SIZE = 16;        // 16 bytes per line (4 words)
    parameter int ICACHE_NUM_LINES = ICACHE_SIZE / ICACHE_LINE_SIZE;
    parameter int ICACHE_INDEX_WIDTH = $clog2(ICACHE_NUM_LINES);
    parameter int ICACHE_OFFSET_WIDTH = $clog2(ICACHE_LINE_SIZE);
    parameter int ICACHE_TAG_WIDTH = XLEN - ICACHE_INDEX_WIDTH - ICACHE_OFFSET_WIDTH;

    // Performance Counter Width
    parameter int PERF_COUNTER_WIDTH = 32;

    // IF/ID pipeline reg
    typedef struct packed {
        logic [XLEN-1:0] pc;
        logic [XLEN-1:0] instruction;
        logic [XLEN-1:0] pc_plus4;
        logic valid_if_id;
    } if_id_reg_t;

    // ID/EX pipeline reg
    typedef struct packed {
        logic [XLEN-1:0] pc;
        logic [XLEN-1:0] rs1_data;
        logic [XLEN-1:0] rs2_data;
        logic [XLEN-1:0] immediate;
        logic [2:0] funct3_for_branch;
        logic [REG_ADDR_WIDTH-1:0] rs1_addr;
        logic [REG_ADDR_WIDTH-1:0] rs2_addr;
        logic [REG_ADDR_WIDTH-1:0] rd_addr;
        ctrl_signals_t ctrl;
        logic valid_id_ex;
    } id_ex_reg_t;

    // EX/MEM pipeline reg
    typedef struct packed {
        logic [XLEN-1:0] alu_result;
        logic [XLEN-1:0] rs2_data_str; // For stores
        logic [REG_ADDR_WIDTH-1:0] rd_addr;
        ctrl_signals_t ctrl;
        logic valid_ex_mem;
    } ex_mem_reg_t;

    // MEM/WB pipeline reg
    typedef struct packed {
        logic [XLEN-1:0] alu_result;
        logic [XLEN-1:0] mem_data;
        logic [REG_ADDR_WIDTH-1:0] rd_addr;
        ctrl_signals_t ctrl;
        logic valid_mem_wb;
    } mem_wb_reg_t;


endpackage : riscv_pkg