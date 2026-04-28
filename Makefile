# Define variables
R = 8
C = 8
K = 16
WK = 8
WX = 8
WY = 32
VALID_PROB = 1
READY_PROB = 50
FREQ_MHZ = 100
AXI_WIDTH = 32
ADDR_WIDTH = 32
AXIL_WIDTH = 32
TARGET = sim
TRACE ?= 1
OPTIMIZE = 0
CLEAN_REGRESS = 0
COPY_WORKDIR = 0
IP ?= axis_sa

SYS = axi
PDK ?= asap7
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
	$(if $(filter 1,$(TRACE)),--trace -CFLAGS -g) \
	--timing \
	$(FULL_FB_DIR)/fb_top_verilator_wrap.cpp
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

$(WORK_DIR)/config.svh $(WORK_DIR)/config.h $(WORK_DIR)/config.tcl $(WORK_DIR)/config.scala: $(RUN_DIR)/config.py $(WORK_DIR)
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
		--AXIL_WIDTH $(AXIL_WIDTH) \
		--ADDR_WIDTH $(ADDR_WIDTH) \
		--TARGET $(TARGET)
wave:
	gtkwave $(WORK_DIR)/trace.vcd &

config: $(WORK_DIR)/config.svh $(WORK_DIR)/config.h $(WORK_DIR)/config.tcl $(WORK_DIR)/config.scala
	@if [ "$(COPY_WORKDIR)" = "1" ]; then rm -rf run/work && cp -r $(WORK_DIR) run/work; fi;

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

.PHONY: veri_clean_cache

veri_clean_cache:
	rm -rf $(WORK_DIR)/V* $(WORK_DIR)/verilated* $(WORK_DIR)/*.o $(WORK_DIR)/*.a $(WORK_DIR)/*.d $(WORK_DIR)/*.mk $(WORK_DIR)/*.gch

veri: $(WORK_DIR) veri_clean_cache $(DATA_DIR)/kxa.bin $(WORK_DIR)/config.svh $(WORK_DIR)/config.h $(DATA_DIR)
	cd run && verilator --top $(TB_MODULE) -F $(SOURCES_FILE) $(C_SOURCE) $(VERI_FLAGS)
	cd $(WORK_DIR) && ./V$(TB_MODULE)

veri_axis: $(WORK_DIR) veri_clean_cache $(WORK_DIR)/config.svh rtl/sa/axis_sa.sv rtl/sa/pe.sv rtl/sa/mac.sv rtl/sa/n_delay.sv rtl/sa/tri_buffer.sv tb/axis_sa_tb.sv tb/axis_vip/tb/axis_sink.sv tb/axis_vip/tb/axis_source.sv
	git submodule update --init tb/axis_vip
	verilator --binary -j 0 -O3 $(if $(filter 1,$(TRACE)),--trace) --top axis_sa_tb -Mdir $(WORK_DIR)/ $(filter-out veri_clean_cache $(WORK_DIR),$^) --Wno-BLKANDNBLK --Wno-INITIALDLY
	cd $(WORK_DIR) && ./Vaxis_sa_tb

veri_smoke: $(WORK_DIR) veri_clean_cache rtl/sa/axis_sa.sv rtl/sa/mac.sv rtl/sa/n_delay.sv rtl/sa/tri_buffer.sv tb/smoke_tb.sv
	verilator --top smoke_tb --binary -j 0 -O3 --trace --Wno-BLKANDNBLK --Wno-INITIALDLY --Mdir $(WORK_DIR) $(filter-out veri_clean_cache $(WORK_DIR),$^)
	cd $(WORK_DIR) && ./Vsmoke_tb

#----------------- FORMAL VERIFICATION ------------------

qverify:
	rm -rf build/qverify/traces
	mkdir -p build/qverify/traces
	qverify -c -od build/qverify -do formal/tb_$(IP).tcl
	for db in build/qverify/qwave_files/*.db; do \
	  [ -f "$$db" ] || continue; \
	  name=$$(basename "$${db%.db}"); \
	  script -q /dev/null -c \
	    "qwave2vcd -wavefile $$db -outfile build/qverify/traces/$${name}.vcd" \
	    > /dev/null 2>&1; \
	  echo "VCD written: build/qverify/traces/$${name}.vcd"; \
	done


#----------------- Chipyard/Boom System ---------

boom_test:
	$(MAKE) -C soc/chipyard test

#----------------- OpenROAD ASIC flow ------------

OPENROAD_DIR ?= $(CURDIR)/openroad
ORFS_DIR ?= $(firstword $(wildcard /OpenROAD-flow-scripts) $(OPENROAD_DIR)/OpenROAD-flow-scripts)
ORFS_FLOW_DIR ?= $(ORFS_DIR)/flow
OPENROAD_WORK_DIR ?= $(OPENROAD_DIR)/work
OPENROAD_DESIGN_CONFIG ?= $(OPENROAD_DIR)/config.mk
OPENROAD_PLATFORM ?= $(PDK)
ifeq ($(PDK),sky130)
  OPENROAD_PLATFORM := sky130hd
endif
OPENROAD_DESIGN_NICKNAME ?= $(or $(DESIGN_NICKNAME),$(SYS))
OPENROAD_FLOW_VARIANT ?= $(or $(FLOW_VARIANT),base)
OPENROAD_RESULTS_DIR ?= $(OPENROAD_WORK_DIR)/results/$(OPENROAD_PLATFORM)/$(OPENROAD_DESIGN_NICKNAME)/$(OPENROAD_FLOW_VARIANT)
OPENROAD_REPORTS_DIR ?= $(OPENROAD_WORK_DIR)/reports/$(OPENROAD_PLATFORM)/$(OPENROAD_DESIGN_NICKNAME)/$(OPENROAD_FLOW_VARIANT)
OPENROAD_EXE ?= $(or $(shell command -v openroad 2>/dev/null),$(ORFS_DIR)/tools/install/OpenROAD/bin/openroad)
GDS_IMAGE_SCALE ?= 8
GDS_IMAGE_OUTPUT ?= $(OPENROAD_REPORTS_DIR)/final_all_$(GDS_IMAGE_SCALE)x.webp

.PHONY: gds gds_image_hi gds_clean gds_nuke

orfs_submodule:
	git submodule update --init openroad/OpenROAD-flow-scripts

gds: config orfs_submodule
	$(MAKE) -C $(ORFS_FLOW_DIR) \
		DESIGN_CONFIG=$(OPENROAD_DESIGN_CONFIG) \
		SYS=$(SYS) \
		PDK=$(PDK) \
		WORK_HOME=$(OPENROAD_WORK_DIR) \
		gds

gds_image_hi: orfs_submodule
	mkdir -p $(OPENROAD_REPORTS_DIR)
	QT_QPA_PLATFORM=offscreen \
	SCRIPTS_DIR=$(ORFS_FLOW_DIR)/scripts \
	RESULTS_DIR=$(OPENROAD_RESULTS_DIR) \
	REPORTS_DIR=$(OPENROAD_REPORTS_DIR) \
	IMAGE_SCALE=$(GDS_IMAGE_SCALE) \
	OUTPUT_FILE=$(GDS_IMAGE_OUTPUT) \
	$(OPENROAD_EXE) $(CURDIR)/scripts/save_highres_final_all.tcl

gds_clean: orfs_submodule
	$(MAKE) -C $(ORFS_FLOW_DIR) \
		DESIGN_CONFIG=$(OPENROAD_DESIGN_CONFIG) \
		SYS=$(SYS) \
		PDK=$(PDK) \
		WORK_HOME=$(OPENROAD_WORK_DIR) \
		clean_all
	rm -rf $(OPENROAD_WORK_DIR)/results/$(OPENROAD_PLATFORM)/$(OPENROAD_DESIGN_NICKNAME)/$(OPENROAD_FLOW_VARIANT)
	rm -rf $(OPENROAD_WORK_DIR)/logs/$(OPENROAD_PLATFORM)/$(OPENROAD_DESIGN_NICKNAME)/$(OPENROAD_FLOW_VARIANT)
	rm -rf $(OPENROAD_WORK_DIR)/reports/$(OPENROAD_PLATFORM)/$(OPENROAD_DESIGN_NICKNAME)/$(OPENROAD_FLOW_VARIANT)
	rm -rf $(OPENROAD_WORK_DIR)/objects/$(OPENROAD_PLATFORM)/$(OPENROAD_DESIGN_NICKNAME)/$(OPENROAD_FLOW_VARIANT)

gds_nuke: orfs_submodule
	$(MAKE) -C $(ORFS_FLOW_DIR) \
		DESIGN_CONFIG=$(OPENROAD_DESIGN_CONFIG) \
		SYS=$(SYS) \
		PDK=$(PDK) \
		WORK_HOME=$(OPENROAD_WORK_DIR) \
		nuke

#----------------- Ibex System ------------------

ibex_test:
	make ibuild irun iprint TARGET=ibex 

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
	$(MAKE) gds_clean
	rm -rf build *.vstf *.log *.ses .qverify .visualizer

#----------------- Regression ------------------

CMD ?= veri
R_LIST := 2 3 4 5 6 7 8 9 10 11 12
C_LIST := 2 3 4 5 6 7 8 9 10 11 12

regress:
	@set -e; \
	for Rv in $(R_LIST); do \
	  for Cv in $(C_LIST); do \
	    WD="$(RUN_DIR)/work_R$${Rv}_C$${Cv}"; \
	    DD="$${WD}/data"; \
			if [ -n "$(CLEAN_REGRESS)" ]; then $(MAKE) clean; fi; \
	    echo "\n\n\n================== [regress] R=$$Rv C=$$Cv SYS=$(SYS) VALID_PROB=$(VALID_PROB)/1000 READY_PROB=$(READY_PROB)/1000 ==================\n\n\n"; \
	    $(MAKE) $(CMD) R=$$Rv C=$$Cv WORK_DIR="$$WD" DATA_DIR="$$DD"; \
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

fresh: kill image start enter

restart: kill start enter

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
	- docker kill $(CONTAINER) || true
	- docker rm   $(CONTAINER) || true

.PHONY: sim vlog elab run clean vivado regress veri xrun ibuild irun iprint iwave irun-clean veri_axis veri_smoke qverify regress image start enter kill wave clean
