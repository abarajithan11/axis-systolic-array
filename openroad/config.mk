export PLATFORM = $(OPENROAD_PLATFORM)

OPENROAD_CONFIG_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
REPO_ROOT := $(abspath $(OPENROAD_CONFIG_DIR)/..)

include $(OPENROAD_CONFIG_DIR)/parameters.mk

export SDC_FILE = $(OPENROAD_CONFIG_DIR)/constraint.sdc
export VERILOG_INCLUDE_DIRS = $(REPO_ROOT)/run/work $(REPO_ROOT)/rtl $(REPO_ROOT)/rtl/sa $(REPO_ROOT)/rtl/sys $(REPO_ROOT)/rtl/ext
