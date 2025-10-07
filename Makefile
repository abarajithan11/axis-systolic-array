# Define variables
R = 4
C = 8
K = 16
WK = 8
WX = 8
WY = 32
CONFIG_BASEADDR = 40000
VALID_PROB = 1
READY_PROB = 50
FREQ_MHZ = 100
AXI_WIDTH = 32
BOARD = zcu104

SYS = axi
TB_MODULE = top_$(SYS)_tb
RUN_DIR = run
WORK_DIR = run/work
DATA_DIR = $(WORK_DIR)/data
FULL_DATA_DIR = $(subst \,\\,$(abspath $(DATA_DIR)))
FULL_WORK_DIR = $(subst \,\\,$(abspath $(WORK_DIR)))
C_SOURCE = ../../c/sim.c
SOURCES_FILE = sources_$(SYS).txt

#-----------------COMPILER OPTIONS ------------------

XSC_FLAGS = \
	--gcc_compile_options -DSIM \
	--gcc_compile_options "-DDIR=$(WORK_DIR)/" \
	--gcc_compile_options "-I$(FULL_WORK_DIR)"

XVLOG_FLAGS = -sv -i $(abspath $(RUN_DIR))

XELAB_FLAGS = --snapshot $(TB_MODULE) -log elaborate.log --debug typical -sv_lib dpi

XSIM_FLAGS = --tclbatch cfg.tcl

VERI_FLAGS = --binary -j 0 -O3 \
	--Wno-BLKANDNBLK --Wno-INITIALDLY \
	-I$(RUN_DIR) \
	-CFLAGS -DSIM \
	-CFLAGS -g --Mdir ../$(WORK_DIR) \
	-CFLAGS -I$(WORK_DIR) 

XCELIUM_FLAGS = -64bit -sv -dpi -CFLAGS -DSIM -CFLAGS -I.

#----------------- COMMON SETUP ------------------

$(WORK_DIR):
	"mkdir" -p $(WORK_DIR)

$(DATA_DIR): | $(WORK_DIR)
	"mkdir" -p $(DATA_DIR)

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
		--CONFIG_BASEADDR $(CONFIG_BASEADDR) \
		--VALID_PROB $(VALID_PROB) \
		--READY_PROB $(READY_PROB) \
		--DATA_DIR $(FULL_DATA_DIR) \
		--WORK_DIR $(FULL_WORK_DIR) \
		--FREQ_MHZ $(FREQ_MHZ) \
		--AXI_WIDTH $(AXI_WIDTH) \
		--BOARD $(BOARD) \


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
	echo log_wave -recursive *; run all; exit > $(WORK_DIR)/cfg.tcl
	cd $(WORK_DIR) && xsim $(TB_MODULE) $(XSIM_FLAGS)


#----------------- FPGA FLOW ------------------

vivado: $(WORK_DIR) $(WORK_DIR)/config.svh $(WORK_DIR)/config.tcl
	cd $(WORK_DIR) && vivado -mode batch -source $(subst \,\\,$(abspath $(RUN_DIR)))/vivado_flow.tcl

#----------------- XCELIUM --------------------

xrun: $(WORK_DIR) $(DATA_DIR)/kxa.bin $(WORK_DIR)/config.svh $(WORK_DIR)/config.h
	cd $(WORK_DIR) && xrun $(XCELIUM_FLAGS) -f ../$(SOURCES_FILE) $(C_SOURCE)


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
	$(MAKE) -C ibex-soc rm-sw
ibuild: $(WORK_DIR)/config.svh
	$(MAKE) -C ibex-soc build
iwave:
	$(MAKE) -C ibex-soc wave

# Clean work directory
clean:
	"rm" -rf $(WORK_DIR)*
	$(MAKE) -C ibex-soc clean

.PHONY: sim vlog elab run clean vivado regress veri xrun
