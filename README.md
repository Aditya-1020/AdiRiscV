# Custom RISC-V Processor
A custom 32-bit RISC-V CPU built from scratch in SystemVerilog, featuring pipelining, branch prediction, cache hierarchy and custom DSP instructions.

## Tools
- Verilog/SystemVerilog for implementation
- Icarus Verilog / Verilator for simulation
- GTKWave for waveform debugging
- RISC-V toolchain (riscv64-unknown-elf-gcc, objdump) for generating programs

# Strech Goal
add cryptographic instructions, vector processing unit, out-of-order execution


# Compiling for RISC-V
```sh
riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -c FILENAME.c -o FILENAME_OUT.o
riscv64-unknown-elf-objdump -d FILENAME_OUT.o
```
