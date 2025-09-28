-include ../common.mk

RTL_SOURCES := $(RTL_DIR)/pipeline_reg.sv $(TB_DIR)/sv_pipeline_reg/pipeline_reg_wrap.sv
TB_SOURCES := $(TB_DIR)/sv_fifo/fifo_tb.sv
SIM_TOP := fifo_tb
SIM_OPTS := -DSIM_PIPELINE

-include ../svbench.mk
