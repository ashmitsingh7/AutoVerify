##############################################################################
# Makefile - convenience wrapper around gen_tb.pl + run_sim.tcl
#
# Usage:
#   make gen MODULE=counter DUT=examples/counter.v
#   make sim MODULE=counter DUT=examples/counter.v
#   make regress MODULE=counter DUT=examples/counter.v SEEDS=10
#   make clean MODULE=counter
#
# Requires a SystemVerilog simulator with Tcl scripting (Questa/ModelSim by
# default). Set SIMULATOR=vcs or SIMULATOR=xrun and adjust run_sim.tcl if
# your site uses a different tool.
##############################################################################

MODULE    ?= counter
DUT       ?= examples/$(MODULE).v
GEN_DIR   ?= gen_$(MODULE)
SEEDS     ?= 5
SIMULATOR ?= vsim

.PHONY: gen sim regress clean help

help:
	@echo "Targets:"
	@echo "  make gen      MODULE=<name> DUT=<path/to/module.v>   - generate testbench"
	@echo "  make sim      MODULE=<name> DUT=<path/to/module.v>   - generate + compile + run once"
	@echo "  make regress  MODULE=<name> DUT=<path/to/module.v> SEEDS=N - generate + N random-seed runs"
	@echo "  make clean    MODULE=<name>                          - remove generated files"

gen:
	perl bin/gen_tb.pl $(DUT) --outdir=$(GEN_DIR)

sim: gen
	$(SIMULATOR) -c -do "set MODULE $(MODULE); set DUT_FILE $(DUT); set GEN_DIR $(GEN_DIR); source run_sim.tcl; quit"

regress: gen
	$(SIMULATOR) -c -do "set MODULE $(MODULE); set DUT_FILE $(DUT); set GEN_DIR $(GEN_DIR); source run_sim.tcl; regress $(SEEDS); quit"

clean:
	rm -rf $(GEN_DIR) work transcript *.vcd *.wlf
