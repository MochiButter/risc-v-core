VERILATOR_ARGS := --timing -j 0 --assert 
VERILATOR_ARGS += --trace-fst --trace-structs 
VERILATOR_ARGS += --main-top-name "-" 
VERILATOR_ARGS += --x-assign unique --x-initial unique
VERILATOR_ARGS += -Wall -Wno-fatal

IVERILOG_ARGS := -g2005-sv -Wall

YOSYS_DATDIR := $(shell yosys-config --datdir)

GLS_SOURCES := $(YOSYS_DATDIR)/simlib.v \
							 build/synth/generic_synth.v

.PHONY: all sim synth gls synth lint clean

all: sim gls
sim: verilator.vcd iverilog.vcd
gls: verilator_gls.vcd iverilog_gls.vcd

get_sources = $(if $(findstring _gls,$@),$(GLS_SOURCES),$(RTL_SOURCES))

verilator%: $(RTL_SOURCES) $(TB_SOURCES)
	$(if $(findstring _gls,$@),$(MAKE) synth,)
	@mkdir -p build/verilator
	verilator $(ROOT_DIR)/tb/verilator.vlt -Mdir build/verilator \
		$(VERILATOR_ARGS) $(SIM_OPTS) -DDUMPFILE='"$@"' --binary \
		$(call get_sources) $(TB_SOURCES) --top $(SIM_TOP) 
	build/verilator/V$(SIM_TOP) +verilator+rand+reset+2

iverilog%: $(RTL_SOURCES) $(TB_SOURCES)
	$(if $(findstring _gls,$@),$(MAKE) synth,)
	@mkdir -p build/iverilog
	iverilog -o build/iverilog/tb $(IVERILOG_ARGS) $(SIM_OPTS) \
		-DDUMPFILE='"$@"' $(call get_sources) $(TB_SOURCES) -s $(SIM_TOP)
	vvp build/iverilog/tb -fst

synth: build/synth/sim.sv2v.v build/synth/generic_synth.v
build/synth/sim.sv2v.v build/synth/generic_synth.v: $(RTL_SOURCES)
	@mkdir -p build/synth
	sv2v $^ -w build/synth/sim.sv2v.v $(SIM_OPTS)
	yosys -p 'tcl $(ROOT_DIR)/tb/yosys.tcl' -ql build/synth/generic_synth_v.yslog

lint: $(RTL_SOURCES) $(TB_SOURCES)
	verilator $(ROOT_DIR)/tb/verilator.vlt --lint-only --timing \
		$(SIM_OPTS) -top $(SIM_TOP) $^ -Wall

clean:
	rm -rf build
	rm -f *.vcd
