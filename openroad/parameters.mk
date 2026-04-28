# Shared OpenROAD-flow-scripts defaults for this repository.
# Override any of these on the make command line when exploring QoR.

OPENROAD_SYS ?= $(SYS)
OPENROAD_PDK ?= $(PDK)

OPENROAD_PLATFORM := $(OPENROAD_PDK)
ifeq ($(OPENROAD_PDK),sky130)
  OPENROAD_PLATFORM := sky130hd
endif

export DESIGN_NICKNAME ?= $(OPENROAD_SYS)

ifeq ($(OPENROAD_SYS),axi)
  export DESIGN_NAME ?= top
else ifeq ($(OPENROAD_SYS),ram)
  export DESIGN_NAME ?= top_sa_ram
else ifeq ($(OPENROAD_SYS),axi_int)
  export DESIGN_NAME ?= top_axi_int
else
  export DESIGN_NAME ?= $(OPENROAD_SYS)
endif

design_flist := $(REPO_ROOT)/run/sources_$(OPENROAD_SYS).txt
design_files_raw := $(strip $(shell awk '{sub(/#.*/, ""); gsub(/^[ \t]+|[ \t]+$$/, ""); if (length) print $$0}' $(design_flist) 2>/dev/null))
design_files_abs := $(foreach f,$(design_files_raw),$(abspath $(REPO_ROOT)/run/work/$(f)))

export VERILOG_FILES ?= $(filter $(REPO_ROOT)/rtl/%,$(design_files_abs))

ifeq ($(OPENROAD_PLATFORM),asap7)
  export CORE_UTILIZATION ?= 80
  export CORE_ASPECT_RATIO ?= 1
  export CORE_MARGIN ?= 2
  export PLACE_DENSITY ?= 0.60
  export SKIP_CTS_REPAIR_TIMING ?= 1
else
  export CORE_UTILIZATION ?= 80
  export CORE_ASPECT_RATIO ?= 1
  export CORE_MARGIN ?= 4
  export PLACE_DENSITY ?= 0.55
endif
