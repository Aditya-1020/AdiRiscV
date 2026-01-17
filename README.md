# AdiRiscV - RV32IM

A simple RISC‑V CPU core written in SystemVerilog, featuring both single‑cycle and 5‑stage pipelined implementations. The design currently supports the RV32I base integer ISA with the M extension for integer multiplication and division.

#### Features
- RV32I + M extension support (I + M instructions)
- Single‑cycle core: riscv_single_cycle_core.sv
- 5‑stage pipelined core: riscv_pipelined_core.sv
- Classic 5‑stage pipeline: Fetch, Decode, Execute, Memory, Writeback
- Hazard detection and forwarding
- Basic branch unit with planned branch prediction support

This project is intended to be simulator‑agnostic. You can use any Verilog/SystemVerilog simulator (e.g. Verilator, Questa, etc.). Example Verilator/Makefile flow and test programs will be added later.


## Quick Start (Vivado)
1. **Update `cmds.f`** – Uncomment the testbench and RTL files you want to compile
2. Compile, elaborate, simulate:
```bash
xvlog -sv -f sim_build/cmds.f  # Compiles all files in cmds.f
xelab tb_MODULE_NAME -s sim    # Elaborate testbench (e.g. tb_pipelined)
xsim sim -R                    # Run simulation
```

##### Roadmap
- Add branch prediction and improve control‑hazard handling
- Implement A extension (atomics)
- Implement system instructions and privilege modes required for Linux
- Add Linux‑capable execution environment and toolchain integration
- Add performance benchmarking and documentation


## License
MIT License