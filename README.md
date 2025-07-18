# AdiRiscV
AdiRiscV is a custom 32-bit RISC-V CPU built from scratch in SystemVerilog, featuring pipelining, branch prediction, cache hierarchy and custom DSP instructions.
Aim of this project is to understand how CPUs work internally this project is parallel to my self taught journey in Digital Design and Computer Architecture

## Tools
- Verilog/SystemVerilog for implementation
- Icarus Verilog / Verilator for simulation
- GTKWave for waveform debugging
- RISC-V toolchain (riscv64-unknown-elf-gcc, objdump) for generating programs

# Strech Goal
add cryptographic instructions, vector processing unit, out-of-order execution, Neural processing Unit (Which runs a simple CNN layer in hardware), AES-128 integration

## RISC-V GNU Toolchain
```sh
sudo apt install gcc-riscv64-unknown-elf
```
- riscv64-unknown-elf-gcc (compiler)
- riscv64-unknown-elf-objdump (disassembler)
- riscv64-unknown-elf-objcopy (binary util1ities)
- riscv64-unknown-elf-gdb (debugger)

```sh
# Install Make and other build essentials
sudo apt install build-essential
```

# Compiling for RISC-V
```sh
riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -c FILENAME.c -o FILENAME_OUT.o
riscv64-unknown-elf-objdump -d FILENAME_OUT.o
```
