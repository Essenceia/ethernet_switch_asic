SHELL := /bin/bash

ifndef debug
#debug := 
endif 

ifndef gates
#gates :=
endif

VIVADO_PRJ_DIR=emulator
VIVADO_PRJ_NAME=$(VIVADO_PRJ_DIR)
VIVADO_PRJ_PATH=$(VIVADO_PRJ_DIR)/$(VIVADO_PRJ_NAME).xpr
VIVADO_CHECKPOINT_PATH=$(VIVADO_PRJ_DIR)/$(VIVADO_PRJ_NAME)_checkpoint.dcp
VIVADO_DEBUG_PROBE_PATH=$(VIVADO_PRJ_DIR)/$(VIVADO_PRJ_NAME)_debug_probes.ltx
VIVADO_BIT_PATH=$(VIVADO_PRJ_DIR)/$(VIVADO_PRJ_NAME).bit

VIVADO_CMD=vivado -mode batch -source

SRC_PATH=../src

GATE_NL_FILES=../final/tt_um_teapot.nl.v ../lib/sg13g2_stdcell_phony.v

.PHONY: setup build prog gui

all: setup build gen

$(VIVADO_PRJ_PATH): setup.tcl 
	mkdir -p $(VIVADO_PRJ_DIR)
	$(VIVADO_CMD) setup.tcl -tclargs $(VIVADO_PRJ_DIR) $(VIVADO_PRJ_NAME) $(SRC_PATH) $(if $(gates),1 $(GATE_NL_FILES))

setup: $(VIVADO_PRJ_PATH) 

$(VIVADO_CHECKPOINT_PATH): $(VIVADO_PRJ_PATH) $(wildcard *.xdc) $(wildcard $(SRC_PATH)/*.v) $(if $(gates),$(GATE_NL_FILES) $(wildcard *.v))
	$(VIVADO_CMD) build.tcl -tclargs $(VIVADO_PRJ_PATH) $(VIVADO_BIT_PATH) $(VIVADO_CHECKPOINT_PATH) $(if $(gates),1,0) $(if $(debug), $(debug) $(VIVADO_DEBUG_PROBE_PATH) )

build: $(VIVADO_CHECKPOINT_PATH)

$(VIVADO_BIT_PATH): $(VIVADO_CHECKPOINT_PATH) 
	$(VIVADO_CMD) program.tcl -tclargs $(VIVADO_CHECKPOINT_PATH) $(VIVADO_BIT_PATH)

prog: $(VIVADO_BIT_PATH)

gui: $(VIVADO_CHECKPOINT_PATH)
	vivado $(VIVADO_CHECKPOINT_PATH)

clean:
	rm -rf .Xil 
	rm -rf $(VIVADO_PRJ_DIR)
	rm -f vivado*
	rm -f webtalk*{log,jou}
	rm -f usage_statistics_webtalk*{html,xml}
	rm -f hs_err*.log
