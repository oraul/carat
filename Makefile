# Carat command map.
#
# Every target is a thin wrapper over spin, Spinel's project tool.
# Nothing is built here directly; see docs/architecture.md.
# Run `make help` for the list.

SPINEL_SRC ?= $(HOME)/Repositories/spinel
PREFIX     ?= $(HOME)/.local
FILE       ?= README.md

.DEFAULT_GOAL := help

# ---------------------------------------------------------------- toolchain

## toolchain: build Spinel and spin from a local checkout at SPINEL_SRC and install them under PREFIX
toolchain:
	@test -d "$(SPINEL_SRC)" || { echo "Spinel checkout not found at $(SPINEL_SRC). Clone it there or set SPINEL_SRC."; exit 1; }
	$(MAKE) -C "$(SPINEL_SRC)" deps
	$(MAKE) -C "$(SPINEL_SRC)"
	$(MAKE) -C "$(SPINEL_SRC)" install PREFIX="$(PREFIX)"
	@echo "Installed spinel and spin under $(PREFIX)/bin. Make sure it is on your PATH."

## doctor: check that spinel, spin, a C compiler, and node are available
doctor:
	@ok=1; \
	for tool in spinel spin cc node; do \
	  if command -v $$tool >/dev/null 2>&1; then echo "ok       $$tool: $$(command -v $$tool)"; \
	  else echo "missing  $$tool"; ok=0; fi; \
	done; \
	test $$ok -eq 1

# -------------------------------------------------------------------- build

## build: compile every bin/*.rb into build/bin
build:
	spin build

## run: build and run the editor on FILE (default README.md), e.g. make run FILE=path/to/file
run:
	spin run carat -- "$(FILE)"

## install: copy the built executables to PREFIX/bin
install:
	spin install --prefix "$(PREFIX)"

## pack: write a self-contained C source tree to dist/ that builds without Spinel
pack:
	spin pack --out dist

## clean: remove build output
clean:
	spin clean
	rm -rf dist

# --------------------------------------------------------------------- test

## test: compile and run every test/*.rb against its committed snapshot
test:
	spin test

## lint: run only the lint test program
lint:
	spin test test/lint.rb

## snapshots: rebuild every test program with Spinel and rewrite its .expected snapshot from the Spinel output; review the diff before committing
snapshots:
	@mkdir -p build/test
	@for t in test/*.rb; do \
	  name=$$(basename $$t .rb); \
	  spinel $$(spin flags) $$t -o build/test/$$name && build/test/$$name > $$t.expected; \
	  echo "wrote $$t.expected"; \
	done
	@echo "Snapshots come from the Spinel binaries, never from CRuby. Review the diff before committing."

## gen-config: regenerate carat/domain/default_config.rb and carat/plugins/registry.rb from config/
gen-config:
	spin run carat-gen-config

## check: everything a push needs: build, gen-config, and test
check: build gen-config test

# --------------------------------------------------------------------- help

## help: list the targets
help:
	@echo "Carat targets:"
	@grep -E '^## [a-z-]+:' $(MAKEFILE_LIST) | sed -E 's/^## ([a-z-]+): (.*)/  \1\t\2/' | expand -t 16
	@echo
	@echo "Variables: SPINEL_SRC=$(SPINEL_SRC)  PREFIX=$(PREFIX)  FILE=$(FILE)"

.PHONY: toolchain doctor build run install pack clean test lint snapshots gen-config check help
