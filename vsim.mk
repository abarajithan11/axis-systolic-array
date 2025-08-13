# Define variables
R = 8
C = 4
K = 16
WK = 8
WX = 8
WY = 32
CONFIG_BASEADDR = B0000000
VALID_PROB = 1
READY_PROB = 50
FREQ_MHZ = 100
AXI_WIDTH = 128
BOARD = zcu104

TB_MODULE = top_tb
RUN_DIR = run
WORK_DIR = run/work
DATA_DIR = $(WORK_DIR)/data
FULL_DATA_DIR = $(subst \,\\,$(abspath $(DATA_DIR)))
FULL_WORK_DIR = $(subst \,\\,$(abspath $(WORK_DIR)))
C_SOURCE = ../../c/sim.c
SOURCES_FILE = sources.txt

VERI_FLAGS = --cc --exe -j 0 -O3 \
	--Wno-BLKANDNBLK --Wno-INITIALDLY \
	--Wno-WIDTHTRUNC --Wno-WIDTHEXPAND \
	--Wno-UNSIGNED --Wno-CASEINCOMPLETE \
	-I$(RUN_DIR) \
	-CFLAGS -DSIM \
	-CFLAGS -g --Mdir ../$(WORK_DIR) \
	-CFLAGS -I$(WORK_DIR) \
	--timing

$(WORK_DIR):
	"mkdir" -p $(WORK_DIR)

$(DATA_DIR): | $(WORK_DIR)
	"mkdir" -p $(DATA_DIR)

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

work_verilator: $(WORK_DIR) $(DATA_DIR)/kxa.bin $(WORK_DIR)/config.svh $(WORK_DIR)/config.h
	cd run && verilator --top $(TB_MODULE) -F sources_veri.txt $(C_SOURCE) $(VERI_FLAGS)

compile_veri:
	make -C $(WORK_DIR) -f Vtop_tb.mk Vtop_tb

veri: work_verilator $(DATA_DIR) compile_veri
	cd $(WORK_DIR) && ./V$(TB_MODULE)


veri_axis: rtl/axis_sa.sv rtl/mac.sv rtl/n_delay.sv rtl/tri_buffer.sv tb/axis_sa_tb.sv tb/axis_vip/tb/axis_sink.sv tb/axis_vip/tb/axis_source.sv
	mkdir -p $(WORK_DIR)
	verilator --binary -j 0 -O3 --trace --top axis_sa_tb -Mdir $(WORK_DIR)/ $^ --Wno-BLKANDNBLK --Wno-INITIALDLY
	@cd run && work/Vaxis_sa_tb

veri_smoke: rtl/sa/axis_sa.sv rtl/sa/mac.sv rtl/sa/n_delay.sv rtl/sa/tri_buffer.sv tb/smoke_tb.sv
	mkdir -p $(WORK_DIR)
	verilator --top smoke_tb --binary -j 0 -O3 --trace --Wno-BLKANDNBLK --Wno-INITIALDLY --Mdir $(WORK_DIR) $^
	@cd run && work/Vsmoke_tb