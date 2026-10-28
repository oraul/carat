# Carat command map.
#
# Every target is a thin wrapper over spin, Spinel's project tool, or over
# OpenSpec. Nothing is built here directly; see docs/architecture.md.
# Run `make help` for the list.

SPINEL_SRC  ?= $(HOME)/Repositories/spinel
SPINEL_REPO ?= matz/spinel
SPINEL_REF  ?= master
PREFIX      ?= $(HOME)/.local
FILE       ?= README.md
OPENSPEC   := OPENSPEC_TELEMETRY=0 npx -y @fission-ai/openspec@latest

.DEFAULT_GOAL := help

# ---------------------------------------------------------------- toolchain

## toolchain: clone Spinel into SPINEL_SRC if missing (or fast-forward it), build it, and install spinel and spin under PREFIX
toolchain:
	@if [ -d "$(SPINEL_SRC)/.git" ]; then \
	  echo "Updating Spinel in $(SPINEL_SRC)"; git -C "$(SPINEL_SRC)" pull --ff-only; \
	else \
	  echo "Cloning Spinel into $(SPINEL_SRC)"; \
	  git clone --depth 1 --branch "$(SPINEL_REF)" "https://github.com/$(SPINEL_REPO)" "$(SPINEL_SRC)"; \
	fi
	$(MAKE) -C "$(SPINEL_SRC)" deps
	$(MAKE) -C "$(SPINEL_SRC)"
	$(MAKE) -C "$(SPINEL_SRC)" install PREFIX="$(PREFIX)"
	@echo "Installed spinel and spin under $(PREFIX)/bin. Make sure it is on your PATH."

## spinel-rev: print the commit of Spinel that SPINEL_REF currently points to on SPINEL_REPO, used as the CI cache key
spinel-rev:
	@git ls-remote "https://github.com/$(SPINEL_REPO)" "refs/heads/$(SPINEL_REF)" | cut -f1

## doctor: check that spinel, spin, a C compiler, and node for OpenSpec are available
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

## types: print the signatures Spinel inferred for the editor, marking where inference widened to untyped
types:
	@mkdir -p build
	spinel $$(spin flags) bin/carat.rb --emit-rbs -o build/carat.rbs >/dev/null
	@cat build/carat.rbs

## gen-config: regenerate carat/domain/default_config.rb and carat/plugins/registry.rb from config/
gen-config:
	spin run carat-gen-config

## check: everything a push needs: build, gen-config, and test
check: build gen-config test

# ----------------------------------------------------------------- openspec

## spec-list: list active OpenSpec changes
spec-list:
	$(OPENSPEC) list

## spec-validate: validate every OpenSpec change and spec in strict mode
spec-validate:
	$(OPENSPEC) validate --all --strict --no-interactive

## spec-update: refresh the generated OpenSpec commands and skills under .claude/
spec-update:
	$(OPENSPEC) update

# --------------------------------------------------------------------- help

## help: list the targets
help:
	@echo "Carat targets:"
	@grep -E '^## [a-z-]+:' $(MAKEFILE_LIST) | sed -E 's/^## ([a-z-]+): (.*)/  \1\t\2/' | expand -t 16
	@echo
	@echo "Variables: SPINEL_SRC=$(SPINEL_SRC)  SPINEL_REPO=$(SPINEL_REPO)  SPINEL_REF=$(SPINEL_REF)  PREFIX=$(PREFIX)  FILE=$(FILE)"

.PHONY: toolchain spinel-rev doctor build run install pack clean test lint snapshots types gen-config check spec-list spec-validate spec-update help
