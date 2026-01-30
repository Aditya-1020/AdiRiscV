# User‑configurable variables
MODULE ?= tb_MODULE_NAME
TOP ?= $(MODULE)

# Vivado simulation commands
XVLOG = xvlog -sv -f cmds.f
XELAB = xelab $(TOP) -s sim
XSIM  = xsim sim -R

.PHONY: sim clean

sim: cmds.f
	$(XVLOG)
	$(XELAB)
	$(XSIM)

# Ensure cmds.f exists (you still need to edit it with your sources)
cmds.f:
	@touch cmds.f
	@echo "Please edit cmds.f with your source files, for example:"
	@echo "src/dut.sv"
	@echo "tb/tb_COUNTER.svro"

clean:
	rm -rf sim *.jou *.log *.wdb xsim.dir xelab.*
