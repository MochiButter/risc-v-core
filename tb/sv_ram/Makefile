-include ../common.mk

RTL_SOURCES := $(RTL_DIR)/ram_1rw_sync.sv $(TB_DIR)/sv_ram/ram_wrap.sv
TB_SOURCES := $(TB_DIR)/sv_ram/ram_tb.sv
SIM_TOP := ram_tb 
SIM_OPTS := -DBINPATH='"$(ROOT_DIR)/"'

-include ../svbench.mk
