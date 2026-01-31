RISCV_FORMAL_DIR ?= riscv-formal
TARGET_DIR := $(RISCV_FORMAL_DIR)/cores/core
ROOT_DIR := $(shell git rev-parse --show-toplevel)

.PHONY: all run clean
all: run

RTL_SRC	+= $(ROOT_DIR)/rtl/core_pkg.sv
RTL_SRC	+= $(ROOT_DIR)/rtl/csr_pkg.sv
RTL_SRC	+= $(ROOT_DIR)/rtl/pipeline_pkg.sv
RTL_SRC	+= $(ROOT_DIR)/rtl/alu.sv
RTL_SRC	+= $(ROOT_DIR)/rtl/core.sv
RTL_SRC	+= $(ROOT_DIR)/rtl/decode.sv
RTL_SRC	+= $(ROOT_DIR)/rtl/ram_1r1w_sync.sv
RTL_SRC	+= $(ROOT_DIR)/rtl/fifo.sv
RTL_SRC	+= $(ROOT_DIR)/rtl/fetch.sv
RTL_SRC	+= $(ROOT_DIR)/rtl/mem_lsu.sv
RTL_SRC	+= $(ROOT_DIR)/rtl/register.sv
RTL_SRC	+= $(ROOT_DIR)/rtl/csr.sv
RTL_SRC	+= $(ROOT_DIR)/rtl/pipeline_reg.sv

$(TARGET_DIR)/core.v: $(RTL_SRC)
	@mkdir -p $(TARGET_DIR)
	sv2v -D	RISCV_FORMAL -DSYNTH $^ -w $@

CONFIG_FILES += checks.cfg
CONFIG_FILES += rvfi_wrapper.sv
COPIED_FILES := $(addprefix $(TARGET_DIR)/, $(notdir $(CONFIG_FILES)))

$(TARGET_DIR)/%: %
	@mkdir -p $(TARGET_DIR)
	cp -p $< $@

$(TARGET_DIR)/checks/makefile: $(TARGET_DIR)/core.v $(COPIED_FILES)
	cd $(TARGET_DIR); python3 ../../checks/genchecks.py

run: $(TARGET_DIR)/checks/makefile $(TARGET_DIR)/core.v $(COPIED_FILES)
	make -C $(TARGET_DIR)/checks
	bash check_tests.sh

clean:
	rm -rf $(TARGET_DIR)
