-include ../common.mk

RTL_SOURCES := $(RTL_DIR)/core_pkg.sv \
							 $(RTL_DIR)/register.sv \
					 		 $(RTL_DIR)/decode.sv \
					     $(RTL_DIR)/alu.sv \
					     $(RTL_DIR)/mem_state.sv \
					     $(RTL_DIR)/ram_1r1w_sync.sv \
					     $(RTL_DIR)/fifo.sv \
							 $(RTL_DIR)/core.sv

TB_SOURCES := $(RTL_DIR)/ram_1rw_sync.sv \
					    $(TB_DIR)/sv_core/core_tb.sv

SIM_TOP := core_tb
SIM_OPTS := -DBINPATH='"$(ROOT_DIR)/"'

-include ../svbench.mk
