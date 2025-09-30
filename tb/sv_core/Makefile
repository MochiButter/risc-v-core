-include ../common.mk

RTL_SOURCES := $(RTL_DIR)/register.sv \
					 		 $(RTL_DIR)/decode.sv \
					     $(RTL_DIR)/alu32.sv \
					     $(RTL_DIR)/mem_state.sv \
					     $(RTL_DIR)/fifo.sv \
							 $(RTL_DIR)/core.sv

TB_SOURCES := $(RTL_DIR)/ram_1rw_sync.sv \
					    $(TB_DIR)/sv_core/core_tb.sv

SIM_TOP := core_tb
SIM_OPTS := -DBINPATH='"$(ROOT_DIR)/"' +incdir+$(ROOT_DIR)/rtl

-include ../svbench.mk
