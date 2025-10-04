-include ../../tb/common.mk
UVM_DIR := $(TB_DIR)/uvm
ARCH_TEST_DIR ?= riscv-arch-test

export UVM_DIR

.PHONY: uvm-build copy-sail run-riscof

uvm-build: $(wildcard $(RTL_DIR)/*.sv)
	make -C $(UVM_DIR) uvm-build

copy-sail: sail_cSim
sail_cSim: $(ARCH_TEST_DIR)
	cp -r $</riscof-plugins/rv32/sail_cSim .
	patch sail_cSim/riscof_sail_cSim.py < sail_patch.diff

run-riscof: uvm-build copy-sail
	riscof run --config=config.ini --suite=$(ARCH_TEST_DIR)/riscv-test-suite \
		--env=$(ARCH_TEST_DIR)/riscv-test-suite/env
