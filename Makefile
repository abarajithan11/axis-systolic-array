# Define variables
R = 8
C = 4
K = 16
WK = 8
WX = 8
WY = 32
VALID_PROB = 1
READY_PROB = 50
FREQ_MHZ = 100
AXI_WIDTH = 32
BOARD = zcu104
TRACE = 0
OPTIMIZE = 0
CLEAN_REGRESS = 0

SYS = axi
TB_MODULE = top_$(SYS)_tb
FB_MODULE = fb_axi_vip
RUN_DIR = run
WORK_DIR = run/work
FB_DIR = firebridge
DATA_DIR = $(WORK_DIR)/data
C_SOURCE = ../../c/sim.c
SOURCES_FILE = sources_$(SYS).txt

BOARDSTORE_REPO  := https://github.com/Xilinx/XilinxBoardStore.git
BOARDSTORE_BRANCH:= 2024.2
BOARDSTORE       := $(RUN_DIR)/XilinxBoardStore


FULL_DATA_DIR = $(subst \,\\,$(abspath $(DATA_DIR)))
FULL_WORK_DIR = $(subst \,\\,$(abspath $(WORK_DIR)))
FULL_FB_DIR = $(subst \,\\,$(abspath $(FB_DIR)))

#-----------------COMPILER OPTIONS ------------------

XSC_FLAGS = \
	--gcc_compile_options -DSIM \
	--gcc_compile_options "-I$(FULL_WORK_DIR)" \
	--gcc_compile_options "-I$(FULL_FB_DIR)"

XVLOG_FLAGS = -sv -i $(abspath $(RUN_DIR))

XELAB_FLAGS = --snapshot $(TB_MODULE) -log elaborate.log --debug typical -sv_lib dpi

XSIM_FLAGS = --tclbatch cfg.tcl

VERI_FLAGS = --cc --exe --build -j 0 \
	--Wno-BLKANDNBLK --Wno-INITIALDLY \
	-I$(RUN_DIR) \
	-CFLAGS -DTB_MODULE=$(TB_MODULE) \
	-CFLAGS -DFB_MODULE=$(FB_MODULE) \
	-CFLAGS -DSIM \
	-CFLAGS -g --Mdir ../$(WORK_DIR) \
	-CFLAGS -I$(WORK_DIR) \
	-CFLAGS -I$(FULL_FB_DIR) \
	--timing \
	$(FULL_FB_DIR)/fb_top_verilator_wrap.cpp

ifeq ($(TRACE),1)
  VERI_FLAGS += --trace-fst -CFLAGS -g
endif
ifeq ($(OPTIMIZE),1)
	VERI_FLAGS += -O3
endif

XCELIUM_FLAGS = -64bit -sv -dpi -CFLAGS -DSIM -CFLAGS -I.
# GCC_FLAGS = -std=gnu99 -fPIC -g -O2 -DSIM "-DDIR=$(WORK_DIR)/" "-I$(FULL_WORK_DIR)" -shared
#----------------- COMMON SETUP ------------------

$(WORK_DIR):
	mkdir -p $(WORK_DIR)

$(DATA_DIR): | $(WORK_DIR)
	mkdir -p $(DATA_DIR)

# Golden model
$(DATA_DIR)/kxa.bin: $(DATA_DIR)
	python3 run/golden.py --R $(R) --K $(K) --C $(C) --DIR $(FULL_DATA_DIR)

$(WORK_DIR)/config.svh $(WORK_DIR)/config.h $(WORK_DIR)/config.tcl: $(RUN_DIR)/config.py $(WORK_DIR)
	cd $(RUN_DIR) && python3 config.py \
		--R $(R) \
		--C $(C) \
		--K $(K) \
		--WK $(WK) \
		--WX $(WX) \
		--WY $(WY) \
		--VALID_PROB $(VALID_PROB) \
		--READY_PROB $(READY_PROB) \
		--DATA_DIR $(FULL_DATA_DIR) \
		--WORK_DIR $(FULL_WORK_DIR) \
		--FREQ_MHZ $(FREQ_MHZ) \
		--AXI_WIDTH $(AXI_WIDTH) \
		--BOARD $(BOARD) \

wave:
	gtkwave $(WORK_DIR)/top_tb.vcd &

#----------------- Vivado XSIM ------------------

# Compile C source
c: $(WORK_DIR) $(DATA_DIR)/kxa.bin $(WORK_DIR)/config.h
	cd $(WORK_DIR) && xsc $(C_SOURCE) $(XSC_FLAGS)

# Run Verilog compilation
vlog: c $(WORK_DIR)/config.svh
	cd $(WORK_DIR) && xvlog -f ../$(SOURCES_FILE)  $(XVLOG_FLAGS)

# Elaborate design
elab: vlog
	cd $(WORK_DIR) && xelab $(TB_MODULE) $(XELAB_FLAGS)

# Run simulation
xsim: elab $(DATA_DIR)
	echo "log_wave -recursive *; run all; exit" > $(WORK_DIR)/cfg.tcl
	cd $(WORK_DIR) && xsim $(TB_MODULE) $(XSIM_FLAGS)


#----------------- FPGA FLOW ------------------

$(BOARDSTORE):
	@git clone --branch $(BOARDSTORE_BRANCH) --depth 1 "$(BOARDSTORE_REPO)" "$(BOARDSTORE)"

vivado: $(WORK_DIR) $(WORK_DIR)/config.svh $(WORK_DIR)/config.tcl $(BOARDSTORE)
	cd $(WORK_DIR) && vivado -mode batch -source $(subst \,\\,$(abspath $(RUN_DIR)))/vivado_flow.tcl

#----------------- XCELIUM --------------------

$(WORK_DIR)/fw.so: $(WORK_DIR)
	cd $(WORK_DIR) && gcc $(GCC_FLAGS) -o fw.so $(C_SOURCE)

xrun: $(WORK_DIR) $(DATA_DIR)/kxa.bin $(WORK_DIR)/config.svh $(WORK_DIR)/config.h $(WORK_DIR)/fw.so
	cd $(WORK_DIR) && xrun $(XCELIUM_FLAGS) -f ../$(SOURCES_FILE)


#----------------- VERILATOR ------------------

work_verilator: $(WORK_DIR) $(DATA_DIR)/kxa.bin $(WORK_DIR)/config.svh $(WORK_DIR)/config.h
	cd run && verilator --top $(TB_MODULE) -F $(SOURCES_FILE) $(C_SOURCE) $(VERI_FLAGS)

veri: work_verilator $(DATA_DIR)
	cd $(WORK_DIR) && ./V$(TB_MODULE)


veri_axis: rtl/axis_sa.sv rtl/mac.sv rtl/n_delay.sv rtl/tri_buffer.sv tb/axis_sa_tb.sv tb/axis_vip/tb/axis_sink.sv tb/axis_vip/tb/axis_source.sv
	mkdir -p $(WORK_DIR)
	verilator --binary -j 0 -O3 --trace --top axis_sa_tb -Mdir $(WORK_DIR)/ $^ --Wno-BLKANDNBLK --Wno-INITIALDLY
	@cd run && work/Vaxis_sa_tb

veri_smoke: rtl/sa/axis_sa.sv rtl/sa/mac.sv rtl/sa/n_delay.sv rtl/sa/tri_buffer.sv tb/smoke_tb.sv
	mkdir -p $(WORK_DIR)
	verilator --top smoke_tb --binary -j 0 -O3 --trace --Wno-BLKANDNBLK --Wno-INITIALDLY --Mdir $(WORK_DIR) $^
	@cd run && work/Vsmoke_tb

#----------------- Ibex System ------------------

iprint: 
	$(MAKE) -C ibex-soc print
irun: 
	$(MAKE) -C ibex-soc run
irun-clean:
	$(MAKE) -C ibex-soc run-clean
ibuild: $(WORK_DIR)/config.svh
	$(MAKE) -C ibex-soc build
iwave:
	$(MAKE) -C ibex-soc wave

clean:
	rm -rf $(WORK_DIR)*
	$(MAKE) -C ibex-soc clean

#----------------- Regression ------------------

R_LIST := 2 3 4 5 6 7 8 9 10 11 12
C_LIST := 2 3 4 5 6 7 8 9 10 11 12

regress:
	@if [ -n "$(CLEAN_REGRESS)" ]; then $(MAKE) clean; fi; \
	@set -e; \
	for Rv in $(R_LIST); do \
	  for Cv in $(C_LIST); do \
	    WD="$(RUN_DIR)/work_R$${Rv}_C$${Cv}"; \
	    DD="$${WD}/data"; \
	    echo "\n\n\n================== [regress] R=$$Rv C=$$Cv SYS=$(SYS) VALID_PROB=$(VALID_PROB)/1000 READY_PROB=$(READY_PROB)/1000 ==================\n\n\n"; \
	    $(MAKE) --no-print-directory veri \
	      R=$$Rv C=$$Cv \
	      WORK_DIR="$$WD" \
	      DATA_DIR="$$DD"; \
	  done; \
	done

#----------------- Docker Setup ------------------
USR       := $(shell id -un)
UID       := $(shell id -u)
GID       := $(shell id -g)
SHORTUSR  := $(shell id -un | cut -c1-4)

IMAGE     := $(USR)/sa-ibex:dev
CONTAINER := sa-ibex-$(USR)
HOSTNAME  := saibex

image:
	docker build \
		-f Dockerfile \
		--build-arg UID=$(UID) \
		--build-arg GID=$(GID) \
		--build-arg USERNAME=$(SHORTUSR) \
		-t $(IMAGE) .

start:
	- xhost +local:docker
	docker run -d --name $(CONTAINER) \
		-h $(HOSTNAME) \
		-e DISPLAY=$$DISPLAY \
		-v /tmp/.X11-unix:/tmp/.X11-unix \
		--tty --interactive \
		-v $(PWD):/repo \
		$(IMAGE) bash -lc 'fusesoc library add sa_ip /repo || true; tail -f /dev/null'

enter:
	docker exec -it $(CONTAINER) bash

kill:
	docker kill $(CONTAINER) || true
	docker rm   $(CONTAINER) || true

.PHONY: sim vlog elab run clean vivado regress veri xrun ibuild irun iprint iwave irun-clean veri_axis veri_smoke regress image start enter kill wave clean
