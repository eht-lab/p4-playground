SUBDIRS := $(shell find . -maxdepth 1 -type d ! -name '.' ! -name 'debug' ! -name '.*')

.PHONY: all build clean $(SUBDIRS)

all: $(SUBDIRS)
	@echo "Build finished"

build:
	@for dir in $(SUBDIRS); do echo "\033[1;34mBuilding app/$$dir\033[0m"; $(MAKE) --no-print-directory -C $$dir build; done

$(SUBDIRS):
	@printf "\033[1;34mBuilding app/$@\033[0m\n"
	@$(MAKE) --no-print-directory -C $@ build

clean:
	@for dir in $(SUBDIRS); do echo "\033[1;34mCleaning app/$@\033[0m"; $(MAKE) --no-print-directory -C $$dir clean; done