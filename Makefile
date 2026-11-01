# Carat command map.
#
# Every target is a thin wrapper over spin, Spinel's project tool, or over
# OpenSpec. Nothing is built here directly; see docs/architecture.md.
# Run `make help` for the list.

# Everything make toolchain fetches or installs lives under tmp/, which git
# ignores and make toolchain-clean removes. Both locations can still be
# overridden on the command line. The two directories are hidden because spin
# treats every visible directory under the repository as part of the project:
# it would report Spinel's C sources as undeclared and feed the .rbs sidecars
# in Spinel's tests to the compiler, which fails on them. spin skips hidden
# directories.
SPINEL_SRC  ?= $(CURDIR)/tmp/.spinel
SPINEL_REPO ?= matz/spinel
# The exact Spinel commit this project builds with. Bump it deliberately, in
# its own pull request, after make check passes with the new commit, and
# regenerate tools/spinel/spinel_rt_responds_generated.h in that same pull
# request (see the toolchain target).
SPINEL_REF  ?= 001419ff1af7f77aaf8862ff248afef66047dd41
PREFIX      ?= $(CURDIR)/tmp/.toolchain
FILE       ?= README.md
# The most objects one key of the cursor scenario of the benchmark may
# allocate; make bench-budget fails at this number or above.
ALLOC_BUDGET ?= 100
OPENSPEC   := OPENSPEC_TELEMETRY=0 npx -y @fission-ai/openspec@latest

# tools/noruby holds a ruby that refuses to run and exits 127. It comes first
# on the PATH of every recipe, so no target can start a CRuby installed on
# the machine: spin test compares a test program that has no .expected
# snapshot against `ruby` from the PATH, and Spinel's own Makefile probes
# `ruby -rprism`; both reach the stub instead. The installed toolchain comes
# next, so after make toolchain every other target finds spinel, spin, and
# spinel-doctor with no shell setup. The override keeps both in front even
# when PATH is given on the make command line.
NORUBY := $(CURDIR)/tools/noruby
override export PATH := $(NORUBY):$(PREFIX)/bin:$(PATH)

.DEFAULT_GOAL := help

# ---------------------------------------------------------------- toolchain

# Spinel's own build runs a CRuby script, tools/gen_respond_to_tables.rb, to
# generate lib/spinel_rt_responds_generated.h, a header that is not in
# Spinel's git. tools/spinel/spinel_rt_responds_generated.h is that script's
# output at the pinned commit SPINEL_REF, copied into this repository so that
# no Ruby interpreter is needed to build the toolchain. The toolchain target
# copies it into the checkout after the checkout step and before make deps,
# so the copy is newer than its prerequisites and Spinel's rule leaves it
# alone. It is a pure function of Spinel's sources: regenerate it with that
# script, on a machine that has CRuby, in the same pull request that bumps
# SPINEL_REF.
SPINEL_GENERATED_HEADER := tools/spinel/spinel_rt_responds_generated.h

## toolchain: fetch the pinned Spinel commit SPINEL_REF into SPINEL_SRC (default tmp/.spinel), build it without Ruby, and install spinel, spin, and spinel-doctor under PREFIX (default tmp/.toolchain)
toolchain:
	@if [ ! -d "$(SPINEL_SRC)/.git" ]; then \
	  echo "Initializing Spinel checkout in $(SPINEL_SRC)"; \
	  git init -q "$(SPINEL_SRC)"; \
	  git -C "$(SPINEL_SRC)" remote add origin "https://github.com/$(SPINEL_REPO)"; \
	fi
	git -C "$(SPINEL_SRC)" fetch --depth 1 origin "$(SPINEL_REF)"
	git -C "$(SPINEL_SRC)" checkout -q --detach FETCH_HEAD
	cp "$(SPINEL_GENERATED_HEADER)" "$(SPINEL_SRC)/lib/spinel_rt_responds_generated.h"
	$(MAKE) -C "$(SPINEL_SRC)" deps
	$(MAKE) -C "$(SPINEL_SRC)"
	$(MAKE) -C "$(SPINEL_SRC)" install PREFIX="$(PREFIX)"
	@echo
	@echo "Installed spinel, spin, and spinel-doctor ($(SPINEL_REF)) under $(PREFIX)/bin."
	@echo "The make targets find them there automatically; no PATH change is needed."

## toolchain-clean: remove tmp/, the Spinel checkout and the installed toolchain
toolchain-clean:
	rm -rf tmp

## spinel-rev: print the Spinel commit the build is pinned to (resolving a branch or tag name through the remote), used as the CI cache key
spinel-rev:
	@if echo "$(SPINEL_REF)" | grep -qE '^[0-9a-f]{40}$$'; then \
	  echo "$(SPINEL_REF)"; \
	else \
	  git ls-remote "https://github.com/$(SPINEL_REPO)" "$(SPINEL_REF)" | head -1 | cut -f1; \
	fi

## doctor: check that spinel, spin, a C compiler, and node for OpenSpec are available, and that the ruby every target reaches is the refusing stub in tools/noruby, never a CRuby
doctor:
	@ok=1; \
	for tool in spinel spin cc node; do \
	  if command -v $$tool >/dev/null 2>&1; then echo "ok       $$tool: $$(command -v $$tool)"; \
	  else echo "missing  $$tool"; ok=0; fi; \
	done; \
	ruby=$$(command -v ruby || true); \
	if [ "$$ruby" = "$(NORUBY)/ruby" ]; then \
	  "$$ruby" -v >/dev/null 2>&1; status=$$?; \
	  if [ $$status -eq 127 ]; then echo "ok       ruby: refused (stub)"; \
	  else echo "error    ruby: the stub $$ruby exited $$status instead of refusing with 127"; ok=0; fi; \
	elif [ -z "$$ruby" ]; then echo "missing  ruby: the stub $(NORUBY)/ruby is not on the make PATH"; ok=0; \
	else echo "error    ruby: $$ruby would be reached instead of the stub $(NORUBY)/ruby"; ok=0; fi; \
	test $$ok -eq 1

## no-cruby: prove that a test program without a snapshot fails instead of being compared against a CRuby: run spin test on a one-line program in a temporary project outside the repository and require the stub's refusal
no-cruby:
	@dir=$$(mktemp -d "$${TMPDIR:-/tmp}/carat-no-cruby.XXXXXX"); \
	trap 'rm -rf "$$dir"' EXIT; \
	mkdir "$$dir/test"; \
	printf '[package]\nname = "probe"\nversion = "0.1.0"\n' > "$$dir/spin.toml"; \
	echo 'puts "probe"' > "$$dir/test/probe.rb"; \
	if (cd "$$dir" && spin test) > "$$dir/report" 2>&1; then \
	  cat "$$dir/report"; \
	  echo "no-cruby: spin test passed a program without a snapshot, so it compared against an interpreter" >&2; exit 1; \
	fi; \
	if ! grep -q "carat never runs a CRuby interpreter; refused: ruby" "$$dir/report"; then \
	  cat "$$dir/report"; \
	  echo "no-cruby: spin test failed, but not because it reached the ruby stub" >&2; exit 1; \
	fi; \
	sed 's/^/  /' "$$dir/report"; \
	echo "no-cruby: spin test reached $$(command -v ruby) and failed the program without a snapshot, as it must"

# -------------------------------------------------------------------- build

## build: compile every bin/*.rb into build/bin and print how to run the editor from anywhere
build:
	spin build
	@echo
	@echo "Built $(CURDIR)/build/bin/carat"
	@echo "To run it from anywhere, add an alias to your shell profile (~/.bashrc, ~/.zshrc, or ~/.config/fish/config.fish):"
	@echo "  bash and zsh:  alias carat='$(CURDIR)/build/bin/carat'"
	@echo "  fish:          alias carat '$(CURDIR)/build/bin/carat'"
	@echo "Or run make install PREFIX=dir to copy it to dir/bin, a directory on your PATH, instead."

## run: build and run the editor on FILE (default README.md), e.g. make run FILE=path/to/file
run:
	spin run carat -- "$(FILE)"

## install: copy the built executables to PREFIX/bin (default tmp/.toolchain/bin, the PATH of every make target); PREFIX=dir installs into dir/bin
install:
	spin install --prefix "$(PREFIX)/bin"
	@echo "Installed $(PREFIX)/bin/carat. Run make install PREFIX=dir to install into dir/bin, a directory on your own PATH."

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

## diagnose: run spinel-doctor on every compile root (bin/*.rb and test/*.rb): unsupported constructs, unresolved calls, widened slots, boxing advice, and build. The behavior leg is skipped: it compares against a CRuby on the path, which this project never uses and which differs from Ruby 4 output
diagnose:
	@status=0; \
	for root in bin/*.rb test/*.rb; do \
	  echo "== $$root"; \
	  spinel-doctor --quiet --skip behavior "$$root" -- $$(spin flags) || status=1; \
	done; \
	exit $$status

## bench: build the key benchmark bench/keys.rb into build/bench and run its scenarios (all, or SCENARIOS="lh j"): time per key for handling and rendering, the slowest key, bytes written, the collector's share, and allocations per key, pinned to one core when taskset exists
bench:
	@mkdir -p build/bench
	spinel $$(spin flags) bench/keys.rb -o build/bench/keys
	sh bench/run.sh $(SCENARIOS)

## bench-budget: build the key benchmark and fail when one key of the cursor scenario (lh) allocates ALLOC_BUDGET objects or more (default 100); CI runs it
bench-budget:
	@mkdir -p build/bench
	spinel $$(spin flags) bench/keys.rb -o build/bench/keys
	sh bench/run.sh --budget lh $(ALLOC_BUDGET)

## profile: build the key benchmark with spinel --profile into build/profile and, when perf works (or PERF names one that does), record the j and lh scenarios and print the top functions by self time with their Ruby names
profile:
	@mkdir -p build/profile
	spinel $$(spin flags) bench/keys.rb --profile -o build/profile/keys
	sh bench/profile.sh build/profile/keys

## types: print the signatures Spinel inferred for the editor, marking where inference widened to untyped
types:
	@mkdir -p build
	spinel $$(spin flags) bin/carat.rb --emit-rbs -o build/carat.rbs >/dev/null
	@cat build/carat.rbs

## gen-config: regenerate carat/domain/default_config.rb and carat/plugins/registry.rb from config/
gen-config:
	spin run carat-gen-config

## check: everything a push needs: build, gen-config, test, diagnose, and no-cruby
check: build gen-config test diagnose no-cruby

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

.PHONY: toolchain toolchain-clean spinel-rev doctor no-cruby build run install pack clean test lint snapshots diagnose bench bench-budget profile types gen-config check spec-list spec-validate spec-update help
