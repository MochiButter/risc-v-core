SIM ?= icarus
WAVES ?= 1

TOPLEVEL_LANG := verilog
ifeq ($(SIM), verilator)
EXTRA_ARGS = --trace --trace-fst --trace-structs
endif

ROOT_DIR := $(PWD)/../..

VERILOG_SOURCES += $(ROOT_DIR)/rtl/alu32.sv
VERILOG_SOURCES += $(ROOT_DIR)/rtl/core.sv
VERILOG_SOURCES += $(ROOT_DIR)/rtl/decode.sv
VERILOG_SOURCES += $(ROOT_DIR)/rtl/fifo.sv
VERILOG_SOURCES += $(ROOT_DIR)/rtl/mem_state.sv
VERILOG_SOURCES += $(ROOT_DIR)/rtl/register.sv

COCOTB_TOPLEVEL = core

COCOTB_TEST_MODULES = test_asm

CUSTOM_SIM_DEPS = asm/jump.bin asm/arithmetic.bin asm/load.bin asm/store.bin asm/branch.bin asm/extra.bin

%.bin: %.elf
	riscv32-unknown-elf-objcopy -O binary $< $@

%.elf: %.s
	riscv32-unknown-elf-as $< -o $@

include $(shell cocotb-config --makefiles)/Makefile.sim

.PHONY: clean_asm
clean_asm:
	rm -f asm/*.bin asm/*.elf

