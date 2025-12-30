# SPDX-License-Identifier: Apache-2.0

SUBDIRS := $(shell find . -maxdepth 1 -type d ! -name '.' ! -name 'debug' ! -name '.*')

.PHONY: all build clean $(SUBDIRS)

all: $(SUBDIRS)
	@echo "Build finished"

build:
	@for dir in $(SUBDIRS); do \
		echo "\033[1;34mBuilding $$dir\033[0m"; \
		$(MAKE) --no-print-directory -C $$dir build; \
	done

$(SUBDIRS):
	@printf "\033[1;34mBuilding $@\033[0m\n"
	@$(MAKE) --no-print-directory -C $@ build

clean:
	@for dir in $(SUBDIRS); do \
		echo "\033[1;34mCleaning $$dir\033[0m"; \
		$(MAKE) --no-print-directory -C $$dir clean || exit $$?; \
	done
