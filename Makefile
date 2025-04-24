# Define variables
R = 8
C = 4
K = 16
VALID_PROB = 1
READY_PROB = 50

TB_MODULE = top_tb
RUN_DIR = run
WORK_DIR = run/work
DATA_DIR = $(WORK_DIR)/data
FULL_DATA_DIR = $(subst \,\\,$(abspath $(DATA_DIR)))
C_SOURCE = ../../c/sim.c
SOURCES_FILE = sources.txt

# Compiler options
XSC_FLAGS = \
	--gcc_compile_options -DSIM \
	--gcc_compile_options "-DDIR=$(FULL_DATA_DIR)/" \
	--gcc_compile_options "-I$(FULL_DATA_DIR)"

XVLOG_FLAGS = -sv \
	-d "DIR=$(FULL_DATA_DIR)/" \
	-d "R=$(R)" -d "C=$(C)" \
	-d "VALID_PROB=$(VALID_PROB)" \
	-d "READY_PROB=$(READY_PROB)" \
	-i $(abspath $(RUN_DIR))

XELAB_FLAGS = --snapshot $(TB_MODULE) -log elaborate.log --debug typical -sv_lib dpi

XSIM_FLAGS = --tclbatch cfg.tcl

VERI_FLAGS = --binary -j 0 -O3 \
	--Wno-BLKANDNBLK --Wno-INITIALDLY \
	-DDIR=$(FULL_DATA_DIR)/ \
	-DR=$(R) \
	-DC=$(C) \
	-DVALID_PROB=$(VALID_PROB) \
	-DREADY_PROB=$(READY_PROB) \
	-I$(RUN_DIR) \
	-CFLAGS -DSIM \
	-CFLAGS -DDIR=$(FULL_DATA_DIR)/ \
	-CFLAGS -DR=$(R) \
	-CFLAGS -DC=$(C) \
	-CFLAGS -DK=$(K) \
	-CFLAGS -g --Mdir ../$(WORK_DIR) \
	-CFLAGS -I$(FULL_DATA_DIR) 

# Ensure the work directories exist
$(WORK_DIR):
	mkdir -p $(WORK_DIR)

$(DATA_DIR): | $(WORK_DIR)
	mkdir -p $(DATA_DIR)

# Golden model
$(DATA_DIR)/kxa.bin: $(DATA_DIR)
	python run/golden.py --R $(R) --K $(K) --C $(C) --DIR $(FULL_DATA_DIR)

#----------------- Vivado XSIM ------------------

# Compile C source
c: $(WORK_DIR) $(DATA_DIR)/kxa.bin
	cd $(WORK_DIR) && xsc $(C_SOURCE) $(XSC_FLAGS)

# Run Verilog compilation
vlog: c
	cd $(WORK_DIR) && xvlog -f ../$(SOURCES_FILE)  $(XVLOG_FLAGS)

# Elaborate design
elab: vlog
	cd $(WORK_DIR) && xelab $(TB_MODULE) $(XELAB_FLAGS)

# Run simulation
xsim: elab $(DATA_DIR)
	echo log_wave -recursive *; run all; exit > $(WORK_DIR)/cfg.tcl
	cd $(WORK_DIR) && xsim $(TB_MODULE) $(XSIM_FLAGS)


#----------------- VERILATOR ------------------

work_verilator: $(WORK_DIR) $(DATA_DIR)/kxa.bin
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

# Clean work directory
clean:
	rm -rf $(WORK_DIR)*

.PHONY: sim vlog elab run clean
