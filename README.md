# AdiRiscV - RISC-V RV32IM Processor Core

A complete, synthesizable RISC-V processor implementation in SystemVerilog featuring both single-cycle and 5-stage pipelined microarchitectures.
- Implements RV32IM instruction set architecture


The project includes:
- **Single-cycle core** (`riscv_single_cycle_core.sv`) - Simple, straightforward implementation
- **5-stage pipelined core** (`riscv_pipelined_core.sv`) - High-performance with hazard handling
- **Complete RV32IM support** - Base integer ISA + multiply/divide extension
- **Branch prediction** - BTB, 2-bit counters, Return Address Stack
- **Comprehensive verification** - 28 assertions across 8 test suites with 100% pass rate

---
## Features

### Instruction Set Architecture
- **RV32I Base Integer** - 40+ instructions (arithmetic, logical, shifts, branches, jumps, loads, stores)
- **M Extension** - Hardware multiply (MUL/MULH/MULHSU/MULHU) and divide (DIV/DIVU/REM/REMU)
- **Full compliance** with RISC-V spec for RV32IM subset

#### Performance Features
- **Data Forwarding**: EX→EX and MEM→EX bypassing for RAW hazard mitigation
- **Hazard Detection**: Automatic load-use stall with pipeline bubble insertion
- **Branch Prediction**:
  - 64-entry Branch Target Buffer (BTB)
  - 256-entry Pattern History Table with G-share indexing
  - 2-bit saturating counters (strong/weak taken/not-taken)
  - 8-deep Return Address Stack for function calls
- **Division Unit**: 32-cycle non-restoring radix-2 divider with signed/unsigned support
- **Performance Counters**: Tracks cycles, instructions, IPC, branches, stalls

---
## Quick Start

### Prerequisites
- **Xilinx Vivado** (tested with 2023.x) or any SystemVerilog simulator
- Unix-like environment (Linux/macOS) for shell scripts

### Running Tests

#### Using Vivado Simulator
```bash
# 1. Compile, elaborate, and simulate the pipelined core
./scripts/run_sim.sh tb_pipelined

# 2. For manual control:
xvlog -sv -f sim_build/cmds.f       # Compile all files
xelab tb_pipelined -s sim           # Elaborate testbench
xsim sim -R                         # Run simulation
```

#### Using Other Simulators
```bash
# Example with ModelSim/QuestaSim
vlog -sv rtl/**/*.sv tb/tb_pipelined.sv
vsim -c tb_pipelined -do "run -all; quit"

# Example with Verilator (requires C++ wrapper)
verilator --cc --exe --build rtl/**/*.sv sim_main.cpp
./obj_dir/Vriscv_pipelined_core
```

### Viewing Waveforms
```bash
# After simulation, open VCD file
gtkwave pipelined.vcd  # or use Vivado waveform viewer
```

---

## Design Highlights

### 1. Parameterized Configuration
```systemverilog
// From riscv_pkg.sv - easily adjustable
parameter int XLEN = 32;              // Data width
parameter int IMEM_SIZE = 1024;       // Instruction memory (words)
parameter int DMEM_SIZE = 4096;       // Data memory (bytes)
parameter int BTB_SIZE = 64;          // Branch target buffer entries
parameter int RAS_SIZE = 8;           // Return address stack depth
```

### 2. Clean Pipeline Register Interface
```systemverilog
typedef struct packed {
    logic [XLEN-1:0] pc;
    logic [XLEN-1:0] rs1_data;
    logic [XLEN-1:0] rs2_data;
    logic [XLEN-1:0] immediate;
    logic [REG_ADDR_WIDTH-1:0] rd_addr;
    ctrl_signals_t ctrl;
    logic valid_id_ex;
} id_ex_reg_t;
```

### 3. Typed Control Signals
```systemverilog
typedef enum logic [4:0] {
    ALU_ADD, ALU_SUB, ALU_SLL, ALU_SLT, ALU_SLTU,
    ALU_XOR, ALU_SRL, ALU_SRA, ALU_OR, ALU_AND,
    ALU_MUL, ALU_MULH, ALU_DIV, ALU_REM, ...
} alu_op_e;
```

---

## License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.


## References

- [RISC-V Instruction Encode/Decoder](https://luplab.gitlab.io/rvcodecjs/)
- [RISC-V ISA Specification](https://riscv.org/technical/specifications/)
- [RISC-V Assembly Programmer's Manual](https://github.com/riscv/riscv-asm-manual)
- [SystemVerilog IEEE 1800-2017](https://ieeexplore.ieee.org/document/8299595)