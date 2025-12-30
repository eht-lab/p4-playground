# SPDX-License-Identifier: Apache-2.0

SUBDIRS := $(shell find . -maxdepth 1 -type d ! -name '.' ! -name 'debug' ! -name '.*' ! -name 'common')

.PHONY: all build clean $(SUBDIRS)

all: $(SUBDIRS)
	@echo "Build finished"

build:
	@for dir in $(SUBDIRS); do \
		echo "\033[1;32m==> Building $$dir\033[0m"; \
		$(MAKE) --no-print-directory -C $$dir build; \
	done
	@echo "Build finished"

$(SUBDIRS):
	@printf "\033[1;32m==> Building $@\033[0m\n"
	@$(MAKE) --no-print-directory -C $@

clean:
	@for dir in $(SUBDIRS); do \
		echo "\033[1;32m==> Cleaning $$dir\033[0m"; \
		$(MAKE) --no-print-directory -C $$dir clean || exit $$?; \
	done
