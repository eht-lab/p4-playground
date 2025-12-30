# SPDX-License-Identifier: Apache-2.0
BUILD_DIR = build
PCAP_DIR = pcaps
LOG_DIR = logs

RUN_SCRIPT = ../../../utils/run_exercise.py

P4C_ARGS = --gen-json-only
ifdef P4C_EXTRA_ARGS
P4C_ARGS += $(P4C_EXTRA_ARGS)
endif

ifndef TOPO
TOPO = topology.json
endif
run_args += -t $(TOPO)

source = $(wildcard *.p4)
compiled_json := $(source:.p4=.json)

ifndef DEFAULT_PROG
DEFAULT_PROG = $(wildcard *.p4)
endif
DEFAULT_JSON = $(BUILD_DIR)/$(DEFAULT_PROG:.p4=.json)

# Define NO_P4 to start BMv2 without a program
ifndef NO_P4
run_args += -j $(DEFAULT_JSON)
endif

# Set BMV2_SWITCH_EXE to override the BMv2 target
ifdef BMV2_SWITCH_EXE
run_args += -b $(BMV2_SWITCH_EXE)
endif

all: build run

run:
	sudo PATH="$$PATH" ${P4_EXTRA_SUDO_OPTS} python3 $(RUN_SCRIPT) $(run_args);

stop:
	@mn_path=$$(which mn 2>/dev/null); \
	if [ -n "$$mn_path" ]; then \
		sudo PATH="$$PATH" "$$mn_path" -c; \
	fi

build: dirs $(compiled_json)

%.json: %.p4
	$(P4C) $(P4C_ARGS) -o $(BUILD_DIR)/$@ $<

dirs:
	@mkdir -p $(BUILD_DIR) $(PCAP_DIR) $(LOG_DIR)

clean: stop
	rm -rf $(BUILD_DIR) $(PCAP_DIR) $(LOG_DIR)
