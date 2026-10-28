# Carat command map.
#
# Every target is a thin wrapper over spin, Spinel's project tool, or over
# OpenSpec. Nothing is built here directly; see docs/architecture.md.
# Run `make help` for the list.

SPINEL_SRC  ?= $(HOME)/Repositories/spinel
SPINEL_REPO ?= matz/spinel
# The exact Spinel commit this project builds with. Bump it deliberately, in
# its own pull request, after make check passes with the new commit.
SPINEL_REF  ?= 001419ff1af7f77aaf8862ff248afef66047dd41
PREFIX      ?= $(HOME)/.local
FILE       ?= README.md
OPENSPEC   := OPENSPEC_TELEMETRY=0 npx -y @fission-ai/openspec@latest

.DEFAULT_GOAL := help

# ---------------------------------------------------------------- toolchain

## toolchain: fetch the pinned Spinel commit SPINEL_REF into SPINEL_SRC, build it, and install spinel and spin under PREFIX
toolchain:
	@if [ ! -d "$(SPINEL_SRC)/.git" ]; then \
	  echo "Initializing Spinel checkout in $(SPINEL_SRC)"; \
	  git init -q "$(SPINEL_SRC)"; \
	  git -C "$(SPINEL_SRC)" remote add origin "https://github.com/$(SPINEL_REPO)"; \
	fi
	git -C "$(SPINEL_SRC)" fetch --depth 1 origin "$(SPINEL_REF)"
	git -C "$(SPINEL_SRC)" checkout -q --detach FETCH_HEAD
	$(MAKE) -C "$(SPINEL_SRC)" deps
	$(MAKE) -C "$(SPINEL_SRC)"
	$(MAKE) -C "$(SPINEL_SRC)" install PREFIX="$(PREFIX)"
	@echo "Installed spinel and spin ($(SPINEL_REF)) under $(PREFIX)/bin. Make sure it is on your PATH."

## spinel-rev: print the Spinel commit the build is pinned to (resolving a branch or tag name through the remote), used as the CI cache key
spinel-rev:
	@if echo "$(SPINEL_REF)" | grep -qE '^[0-9a-f]{40}$$'; then \
	  echo "$(SPINEL_REF)"; \
	else \
	  git ls-remote "https://github.com/$(SPINEL_REPO)" "$(SPINEL_REF)" | head -1 | cut -f1; \
	fi

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

## test: build the executables (the smoke test runs build/bin/carat), then compile and run every test/*.rb against its committed snapshot
test: build
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

## diagnose: run spinel-doctor on every compile root (bin/*.rb and test/*.rb): unsupported constructs, unresolved calls, widened slots, boxing advice, build, and behavior parity
diagnose:
	@status=0; \
	for root in bin/*.rb test/*.rb; do \
	  echo "== $$root"; \
	  spinel-doctor --quiet "$$root" -- $$(spin flags) || status=1; \
	done; \
	exit $$status

## types: print the signatures Spinel inferred for the editor, marking where inference widened to untyped
types:
	@mkdir -p build
	spinel $$(spin flags) bin/carat.rb --emit-rbs -o build/carat.rbs >/dev/null
	@cat build/carat.rbs

## gen-config: regenerate carat/domain/default_config.rb and carat/plugins/registry.rb from config/
gen-config:
	spin run carat-gen-config

## check: everything a push needs: build, gen-config, test, and diagnose
check: build gen-config test diagnose

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

.PHONY: toolchain spinel-rev doctor build run install pack clean test lint snapshots diagnose types gen-config check spec-list spec-validate spec-update help
