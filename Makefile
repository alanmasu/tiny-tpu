#================ CONFIGURAZIONE AMBIENTE =================
VENV = $(shell pwd)/.venv
PYTHON = $(VENV)/bin/python3
export PATH := $(VENV)/bin:$(PATH)

# Assicuriamoci che i comandi cocotb-config vengano eseguiti dal venv
COCOTB_CONFIG = $(VENV)/bin/cocotb-config

#================ PARAMETRI DI SIMULAZIONE ================
SIM_BUILD_DIR = sim_build
SIM ?= icarus
TOPLEVEL_LANG ?= verilog
VERILOG_SOURCES = 	$(wildcard src/systemverilog/*.sv)

#================ LOGICA DINAMICA =========================
# Trova tutti i test presenti (es. pe, systolic, ecc.)
MODULES_FOUND = $(patsubst test/test_%.py,%,$(wildcard test/test_*.py))
#=============== MODIFY BELOW ======================

venv:
	@if [ ! -d $(VENV) ]; then \
		python3 -m venv $(VENV); \
		$(PYTHON) -m pip install cocotb==1.9.2 cocotb-bus==0.3.0 numpy; \
	fi
# Test target
test: venv $(SIM_BUILD_DIR)
	pytest test/runner.py

# Test targets
test_%: venv $(SIM_BUILD_DIR)
	@echo "Running Cocotb test for: $*"
	@echo "module dump(); initial begin \$$dumpfile(\"waveforms/$*.vcd\"); \$$dumpvars(0, $*); end endmodule" > $(SIM_BUILD_DIR)/dump_$*.sv
	@$(eval COCOTB_MAKEFILE=$(shell $(VENV)/bin/cocotb-config --makefiles)/Makefile.sim)
	$(MAKE) -f $(COCOTB_MAKEFILE) \
		SIM=$(SIM) \
		TOPLEVEL_LANG=$(TOPLEVEL_LANG) \
		MODULE=test.test_$* \
		TOPLEVEL=$* \
		VERILOG_SOURCES=" $(SIM_BUILD_DIR)/dump_$*.sv $(VERILOG_SOURCES)" \
		COMPILE_ARGS="-g2012 -s dump" \
		SIM_BUILD=$(SIM_BUILD_DIR) \
		COCOTB_REDUCED_LOG_FMT=1 \
		LIBPYTHON_LOC=$(shell $(COCOTB_CONFIG) --libpython) \
		--no-print-directory
	@$(MAKE) -s --no-print-directory clean_sim


# ============ DO NOT MODIFY BELOW THIS LINE ==============

# Create simulation build directory and waveforms directory
$(SIM_BUILD_DIR):
	mkdir -p $(SIM_BUILD_DIR)
	mkdir -p waveforms

# Waveform viewing
show_%: waveforms/%.vcd waveforms/%.gtkw
	gtkwave $^

# Linting
lint:
	verible-verilog-lint src/*sv --rules_config verible.rules

# Cleanup
clean_sim:
	@echo "Cleaning simulation build directory and python cache..."
	@rm -rf $(SIM_BUILD_DIR) test/__pycache__

clean: clean_sim
	@echo "Cleaning waveform files..."
	@rm -rf waveforms/*vcd 

help:
	@echo "Moduli rilevati in $(TESTDIR):"
	@$(foreach mod,$(MODULES_FOUND),echo "  make test_$(mod)";)

.PHONY: clean	
