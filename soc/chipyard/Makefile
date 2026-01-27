HOST_GIT_ROOT := $(abspath ../..)
IP_CONFIG_SCALA := run/work/config.scala
WS_WRT_GIT_ROOT := soc/chipyard/chipyard-docker/ws
HOST_CHIPYARD_ROOT := $(abspath $(CURDIR))/chipyard-docker/ws/chipyard
NEW_IP_NAME := my_axi_ip

SV_BLACKBOX := $(NEW_IP_NAME)_blackbox.sv
SCALA_SOC_CONFIG := SmallBoomMyAxiIPConfig.scala
SCALA_WRAPPER := MyAxiIP.scala

CHIPYARD_SV_BLACKBOX_PATH := $(HOST_CHIPYARD_ROOT)/generators/chipyard/src/main/resources/vsrc
CHIPYARD_CONFIG_PATH := $(HOST_CHIPYARD_ROOT)/generators/chipyard/src/main/scala/config
CHIPYARD_WRAPPER_PATH := $(HOST_CHIPYARD_ROOT)/generators/chipyard/src/main/scala/$(NEW_IP_NAME)

fresh:
	$(MAKE) -C chipyard-docker HOST_GIT_ROOT=$(HOST_GIT_ROOT) WS_WRT_GIT_ROOT=$(WS_WRT_GIT_ROOT) fresh

enter:
	$(MAKE) -C chipyard-docker HOST_GIT_ROOT=$(HOST_GIT_ROOT) WS_WRT_GIT_ROOT=$(WS_WRT_GIT_ROOT) enter

submodule_sync:
	$(MAKE) -C chipyard-docker submodule_sync

generate_ip:
	$(MAKE) -C $(HOST_GIT_ROOT) clean $(IP_CONFIG_SCALA) AXI_WIDTH=64 ADDR_WIDTH=32 AXIL_WIDTH=32

concat_sv: $(NEW_IP_NAME)_blackbox.sv
$(NEW_IP_NAME)_blackbox.sv: $(HOST_GIT_ROOT)/$(IP_CONFIG_SCALA)
	python3 chipyard-docker/concat_sv.py \
		--list $(HOST_GIT_ROOT)/run/sources_axi.txt \
		--base $(HOST_GIT_ROOT)/run/work \
		--out $(CHIPYARD_SV_BLACKBOX_PATH)/$(NEW_IP_NAME)_blackbox.sv \
		--top-old top \
		--top-new my_axi_ip

sync_ip: submodule_sync concat_sv
	cp $(SCALA_SOC_CONFIG) $(CHIPYARD_CONFIG_PATH)/$(SCALA_SOC_CONFIG)
	mkdir -p $(CHIPYARD_WRAPPER_PATH)
	cp $(SCALA_WRAPPER) $(CHIPYARD_WRAPPER_PATH)/$(SCALA_WRAPPER)
	cp $(HOST_GIT_ROOT)/$(IP_CONFIG_SCALA) $(CHIPYARD_WRAPPER_PATH)

smoke_test: generate_ip concat_sv sync_ip
	$(MAKE) -C chipyard-docker run CMD=" \
		cd chipyard/tests && \
		make hello.riscv && \
		cd ../sims/verilator && \
		make CONFIG=SmallBoomMyAxiIPConfig && \
		make CONFIG=SmallBoomMyAxiIPConfig BINARY=../../tests/hello.riscv run-binary"

clean:
	rm -f $(SV_BLACKBOX)
	rm -f $(CHIPYARD_SV_BLACKBOX_PATH)/$(SV_BLACKBOX)
	rm -f $(CHIPYARD_CONFIG_PATH)/$(SCALA_SOC_CONFIG)
	rm -f $(CHIPYARD_WRAPPER_PATH)/*
	$(MAKE) -C chipyard-docker run CMD="cd chipyard/sims/verilator && make clean"

	