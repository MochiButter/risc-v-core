SIM ?= verilator
WAVES ?= 1

TOPLEVEL_LANG := verilog
ifeq ($(SIM), verilator)
EXTRA_ARGS = --trace --trace-fst --trace-structs -DRISCV_FORMAL
endif

ROOT_DIR := $(PWD)/../..

VERILOG_SOURCES += $(ROOT_DIR)/rtl/core_pkg.sv
VERILOG_SOURCES += $(ROOT_DIR)/rtl/csr_pkg.sv
VERILOG_SOURCES += $(ROOT_DIR)/rtl/pipeline_pkg.sv
VERILOG_SOURCES += $(ROOT_DIR)/rtl/alu.sv
VERILOG_SOURCES += $(ROOT_DIR)/rtl/core.sv
VERILOG_SOURCES += $(ROOT_DIR)/rtl/decode.sv
VERILOG_SOURCES += $(ROOT_DIR)/rtl/ram_1r1w_sync.sv
VERILOG_SOURCES += $(ROOT_DIR)/rtl/fifo.sv
VERILOG_SOURCES += $(ROOT_DIR)/rtl/fetch.sv
VERILOG_SOURCES += $(ROOT_DIR)/rtl/mem_lsu.sv
VERILOG_SOURCES += $(ROOT_DIR)/rtl/register.sv
VERILOG_SOURCES += $(ROOT_DIR)/rtl/csr.sv
VERILOG_SOURCES += $(ROOT_DIR)/rtl/pipeline_reg.sv

COCOTB_TOPLEVEL = core

COCOTB_TEST_MODULES = test_asm

CUSTOM_SIM_DEPS = $(patsubst asm/%.s,sim_build/%.bin,$(wildcard asm/*.s)) $(patsubst src/%.c,sim_build/%.bin,$(wildcard src/*.c))

RISCV_TOOLCHAIN ?= riscv64-unknown-elf-
sim_build/%.bin: sim_build/%.elf
	$(RISCV_TOOLCHAIN)objcopy -O binary $< $@

sim_build/%.elf: asm/%.s
	$(RISCV_TOOLCHAIN)gcc -march=rv64i_zicsr_zifencei -mabi=lp64 -nostartfiles -nostdlib -mcmodel=medany -T ../generic.ld $< -o $@

sim_build/%.elf: src/%.c src/boot.s
	$(RISCV_TOOLCHAIN)gcc -march=rv64i_zicsr_zifencei -mabi=lp64 -nostartfiles -nostdlib -mcmodel=medany -T ../generic.ld src/boot.s $< -o $@

include $(shell cocotb-config --makefiles)/Makefile.sim

.PHONY: lint clean_asm

lint: $(VERILOG_SOURCES)
	verilator $(ROOT_DIR)/tb/verilator.vlt --lint-only --timing \
		-top $(COCOTB_TOPLEVEL) $^ -Wall

svlint: $(VERILOG_SOURCES)
	svlint --config $(ROOT_DIR)/tb/lowrisc_style.toml $^
