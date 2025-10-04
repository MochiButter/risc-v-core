-include ../common.mk
all: simulate

NPROC = $(shell nproc)

# -------------------------------------
# Testbench setup
# -------------------------------------
VERILATOR := verilator
ifdef VERILATOR_ROOT
VERILATOR := $(VERILATOR_ROOT)/bin/verilator
endif

UVM_ROOT ?= $(ROOT_DIR)/third_party/uvm-1.2
UVM_TEST ?= core_base_test

VERILOG_DEFINE_FILES = ${UVM_ROOT}/src/uvm.sv
VERILOG_DEFINE_FILES += $(RTL_DIR)/core_pkg.sv
VERILOG_DEFINE_FILES += $(RTL_DIR)/alu32.sv
VERILOG_DEFINE_FILES += $(RTL_DIR)/core.sv
VERILOG_DEFINE_FILES += $(RTL_DIR)/decode.sv
VERILOG_DEFINE_FILES += $(RTL_DIR)/fifo.sv
VERILOG_DEFINE_FILES += $(RTL_DIR)/mem_state.sv
VERILOG_DEFINE_FILES += $(RTL_DIR)/register.sv

VERILOG_DEFINE_FILES += ./bus_agent/bus_if.sv
VERILOG_DEFINE_FILES += ./bus_agent/bus_resp_agent_pkg.sv
VERILOG_DEFINE_FILES += ./env/core_env_pkg.sv
VERILOG_DEFINE_FILES += ./tests/core_test_pkg.sv

VERILOG_DEFINE_FILES += ./tb/tb.sv

VERILOG_INCLUDE_DIRS = ../../rtl ./ ${UVM_ROOT}/src ./bus_agent ./env ./tests

# -------------------------------------
# Compilation/simulation configuration
# -------------------------------------
SIM_NAME ?= core_tb
SIM_DIR ?= $(SIM_NAME)-sim
TEMPFILE := $(shell mktemp)
COMPILE_ARGS += --output-groups $(NPROC) -DUVM_NO_DPI
COMPILE_ARGS += --prefix $(SIM_NAME) -o $(SIM_NAME)
COMPILE_ARGS += $(addprefix +incdir+, $(VERILOG_INCLUDE_DIRS))
EXTRA_ARGS += --timescale 1ns/1ps --error-limit 100 --trace-fst --trace-structs
WARNING_ARGS += -Wno-lint \
	-Wno-style \
	-Wno-SYMRSVDWORD \
	-Wno-IGNOREDRETURN \
	-Wno-ZERODLY \
	-Wno-fatal

# -------------------------------------
# Make UVM test with Verilator
# -------------------------------------
$(SIM_DIR)/$(SIM_NAME).mk: $(wildcard $(RTL_DIR)/*.sv) $(wildcard ./bus_agent/*.sv) $(wildcard ./env/*.sv) $(wildcard ./tests/*.sv)
	$(VERILATOR) --version
	$(VERILATOR) --cc --exe --main --timing -Mdir $(SIM_DIR) \
	${COMPILE_ARGS} ${EXTRA_ARGS} \
	${VERILOG_DEFINE_FILES} \
	${WARNING_ARGS}

$(SIM_DIR)/$(SIM_NAME): $(SIM_DIR)/$(SIM_NAME).mk
	$(MAKE) -j${NPROC} -C $(SIM_DIR) $(BUILD_ARGS) -f $(SIM_NAME).mk

program.elf: ../cocotb_asm/asm/loop.s
	riscv64-unknown-elf-as -march=rv32i -mabi=ilp32 $< -o $@

program_text.hex: program.elf
	riscv64-unknown-elf-objcopy -O verilog --verilog-data-width=4 --only-section=.text $< $@

program_data.hex: program.elf
	riscv64-unknown-elf-objcopy -O verilog --verilog-data-width=4 --only-section=.data $< $@

simulate: $(SIM_DIR)/$(SIM_NAME).mk $(SIM_DIR)/$(SIM_NAME) program_text.hex program_data.hex
	$(SIM_DIR)/$(SIM_NAME) +UVM_TESTNAME=$(UVM_TEST) +UVM_VERBOSITY=UVM_HIGH \
		+TEXT_HEX=program_text.hex +DATA_HEX=program_data.hex \
		| tee $(TEMPFILE)
	@grep "^UVM_ERROR\\s*:\\s*0$$" $(TEMPFILE) -q
	@grep "^UVM_FATAL\\s*:\\s*0$$" $(TEMPFILE) -q

clean:
	rm -rf simv*.daidir csrc
	rm -rf csrc* simv*
	rm -rf $(SIM_DIR)
	rm -rf *.vcd

.PHONY: simulate clean
