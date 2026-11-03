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
# The test runner: every test program under test/ in one Spinel program,
# compiled once into TEST_BIN and run once per test (test/runner/run_all.rb
# and tools/run_tests.sh). Each test program used to be its own compile of
# the whole library: about 25 seconds of Spinel's analysis and 10 to 40 of
# C compile, 50 times over.
TEST_RUNNER := test/runner/run_all.rb
TEST_BIN    := build/test/run_all
# The development build of the test runner, of one test (make test-one),
# and of spinel-doctor's checks: Spinel's -O 0, and for the runner and one
# test also --incremental, which cuts the C into units and takes the object
# of every unit whose text did not change from SPINEL_CACHE_DIR. Both are
# documented development modes of Spinel: the same answers, slower code.
# The release binary, build/bin/carat, never gets them: make build compiles
# it with spin build at -O 2. On four cores the runner's C compiled in 9 s
# at -O 0, 30 s at -O 1, and 46 s at -O 2; a warm cache leaves about 2 s.
TEST_OPT    ?= 0
DEV_FLAGS   := -O $(TEST_OPT) --incremental
export SPINEL_CACHE_DIR ?= $(CURDIR)/build/spinel-cache
# The development build of the editor (make dev-build): bin/carat.rb with
# DEV_FLAGS into DEV_BIN, which CI's smoke test runs on pull requests in
# place of the release build. On four cores its C compiled in 2.5 s cold
# against 15 s for the release build at -O 2; the analysis, about 14 s,
# is the same for both. It is kept out of build/bin, so spin build never
# takes it for an up to date release binary.
DEV_BIN     := build/dev/carat
# The editor binary the smoke test runs (test/smoke_editor.rb reads it):
# the release build by default, DEV_BIN when CI passes CARAT_BIN.
export CARAT_BIN ?= build/bin/carat
# The tests make test-run runs: every test/*.rb when empty, e.g.
# make test-run TESTS=test/smoke_editor.rb.
TESTS      ?=
# The benchmark binary make bench-budget builds with DEV_FLAGS: it counts
# objects, not time, and every scenario allocated the same objects and
# bytes per key at -O 0 as at -O 2, so it needs no release build. make
# bench and make profile, which measure time, keep -O 2 in build/bench/keys.
BUDGET_BIN  := build/bench/keys-budget
# T names the test program of make test-one and make diagnose-one.
T          ?=
# The spinel-doctor legs make diagnose skips. The behavior leg compares
# against a CRuby, which this project never runs. make check runs only the
# legs that can fail it: it skips the build leg, since make build and make
# test-build have just compiled every root, and the inference and advice
# legs, which report at info severity and never fail, and which cost a
# second analysis of each root (spinel --emit-rbs); make diagnose and
# make types print them.
DIAGNOSE_SKIP ?= behavior
# The analysis budget (tools/analysis_budget.sh): the most re-narrowing
# rounds Spinel's analysis of a compile root may take, which fails, and
# the analysis milliseconds above which it only warns, since time depends
# on the machine. make test-build checks the test runner's own report, so
# the budget costs no second analysis; make analysis-budget compiles
# ANALYSIS_ROOTS to C one after another and checks them. Every root needed
# 2 rounds and 22 to 26 seconds of analysis on a four-core machine; a value
# that widens to untyped across the library took 5 rounds and 40 seconds.
ANALYSIS_ROOTS  ?= bin/carat.rb $(TEST_RUNNER)
ANALYSIS_ROUNDS ?= 2
ANALYSIS_MS     ?= 45000
# Prints one line from the phase report of a development build: the
# analysis time, the units of C, how many missed the cache and were
# compiled, and the C compile's wall time, so a log shows how much of the
# compile cache a build reused.
UNIT_SUMMARY := awk '/^spinel-timing: phase=analysis / { a = $$3 } /^spinel-timing: phase=cc_compile / { sub(/^spinel-timing: phase=cc_compile /, ""); print "analysis " a ", C compile " $$0; exit }'
# The canonical stage list: make check runs it in order, the checker agent
# runs each stage on its own through tools/run_state.sh check (make
# check-stage S=NAME, with the same diagnose legs), and CI runs the same
# targets but three: the release build only on main, since pull requests
# smoke test dev-build (ci-speed-2); diagnose, a second analysis of every
# root, about a minute, kept off pull requests to hold them near two
# minutes, while the checker runs it before every push; and gates, which
# need the branch's history and its run state, which a pull request's
# checkout lacks, so the checker and the merger run them. docs-lint
# comes right after doctor: it needs no build and fails in a second.
CHECK_STAGES := doctor docs-lint build dev-build config-current test-build test-run diagnose no-cruby bench-budget metrics tools-test gates
# The measurement make metrics writes from the builds of dev-build,
# test-build, and bench-budget (tools/metrics.sh), and the base make
# metrics-compare compares it with: the benchmark agent measures main in a
# worktree, and CI restores the measurement of the last push to main.
METRICS_OUT  := build/metrics/current.tsv
BASE_METRICS ?= build/metrics/base.tsv
# The spinel-doctor legs the stages skip (see DIAGNOSE_SKIP).
CHECK_SKIP   := behavior,build,inference,advice
# The generated files make config-current checks.
GENERATED    := carat/domain/default_config.rb carat/plugins/registry.rb
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
	elif [ -d "$(SPINEL_SRC)/.git" ]; then \
	  git -C "$(SPINEL_SRC)" ls-remote origin "$(SPINEL_REF)" | head -1 | cut -f1; \
	else \
	  echo "spinel-rev: SPINEL_REF=$(SPINEL_REF) is not a commit, and only the remote of the checkout make toolchain sets up can resolve it" >&2; exit 1; \
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

## dev-build: compile the editor bin/carat.rb with the development flags (-O TEST_OPT, --incremental) into build/dev/carat, the binary CI's smoke test runs on pull requests (make test-run CARAT_BIN=build/dev/carat); make build stays the release build
dev-build:
	@mkdir -p $(dir $(DEV_BIN))
	@rm -f $(DEV_BIN)
	@echo "spinel bin/carat.rb $(DEV_FLAGS) -o $(DEV_BIN)"
	@SP_TIMING=1 spinel $$(spin flags) bin/carat.rb $(DEV_FLAGS) -o $(DEV_BIN) 2> $(DEV_BIN).timing; \
	  status=$$?; grep -v '^spinel-timing' $(DEV_BIN).timing >&2; \
	  if [ $$status -ne 0 ]; then echo "dev-build: bin/carat.rb did not compile" >&2; exit 1; fi
	@$(UNIT_SUMMARY) $(DEV_BIN).timing
	sh tools/analysis_budget.sh --check $(ANALYSIS_ROUNDS) $(ANALYSIS_MS) bin/carat.rb $(DEV_BIN).timing

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

## test: compile the editor (make build; the smoke test runs build/bin/carat) and the test runner (make test-build), then run every test from the runner against its committed snapshot (make test-run); a compile failure stops before any test runs
test: build test-build test-run

## test-build: compile the test runner, every test program in one, into build/test/run_all with the development flags (-O 0, --incremental) and check its analysis against the analysis budget
test-build:
	@mkdir -p build/test
	@rm -f $(TEST_BIN)
	@echo "spinel $(TEST_RUNNER) $(DEV_FLAGS) -o $(TEST_BIN)"
	@SP_TIMING=1 spinel $$(spin flags) $(TEST_RUNNER) $(DEV_FLAGS) -o $(TEST_BIN) 2> $(TEST_BIN).timing; \
	  status=$$?; grep -v '^spinel-timing' $(TEST_BIN).timing >&2; \
	  if [ $$status -ne 0 ]; then echo "test-build: $(TEST_RUNNER) did not compile; no test ran" >&2; exit 1; fi
	@$(UNIT_SUMMARY) $(TEST_BIN).timing
	sh tools/analysis_budget.sh --check $(ANALYSIS_ROUNDS) $(ANALYSIS_MS) $(TEST_RUNNER) $(TEST_BIN).timing

## test-run: run every test from the compiled runner (or the TESTS named, e.g. TESTS=test/smoke_editor.rb), each in its own process, and compare its output with its committed snapshot; the smoke test runs CARAT_BIN (default build/bin/carat); make test-build compiles the runner
test-run:
	sh tools/run_tests.sh $(TEST_BIN) $(TESTS)

## test-one: compile one test program on its own with the development flags and run it against its snapshot, e.g. make test-one T=test/domain_buffer.rb; a smoke test builds the editor first
test-one:
	@case "$(T)" in test/*.rb) ;; *) echo "usage: make test-one T=test/NAME.rb" >&2; exit 2 ;; esac
	@case "$(T)" in test/smoke_*) $(MAKE) --no-print-directory build ;; esac
	@mkdir -p build/test-one
	@rm -f build/test-one/$(basename $(notdir $(T)))
	spinel $$(spin flags) $(T) $(DEV_FLAGS) -o build/test-one/$(basename $(notdir $(T)))
	sh tools/run_tests.sh build/test-one/$(basename $(notdir $(T))) $(T)

## lint: compile and run only the lint test program (make test-one T=test/lint.rb)
lint:
	@$(MAKE) --no-print-directory test-one T=test/lint.rb

## snapshots: compile the editor and the test runner, then rewrite every test's .expected snapshot from the runner's output, standard output and error together as make test compares them; review the diff before committing
snapshots: build test-build
	@for t in test/*.rb; do \
	  name=$$(basename $$t .rb); \
	  $(TEST_BIN) $$name > $$t.expected 2>&1; \
	  echo "wrote $$t.expected"; \
	done
	@echo "Snapshots come from the Spinel binaries, never from CRuby. Review the diff before committing."

## diagnose: run spinel-doctor on every compile root, bin/*.rb and the test runner, which holds every test program: unsupported constructs, unresolved calls, widened slots, boxing advice, and a build at -O TEST_OPT. The behavior leg is skipped: it compares against a CRuby on the path, which this project never uses and which differs from Ruby 4 output
diagnose:
	@status=0; \
	for root in bin/*.rb $(TEST_RUNNER); do \
	  echo "== $$root"; \
	  spinel-doctor --quiet --skip $(DIAGNOSE_SKIP) "$$root" -- $$(spin flags) -O $(TEST_OPT) || status=1; \
	done; \
	exit $$status

## diagnose-one: run spinel-doctor on one file as make diagnose does, e.g. make diagnose-one T=test/domain_buffer.rb
diagnose-one:
	@case "$(T)" in *.rb) ;; *) echo "usage: make diagnose-one T=path/NAME.rb" >&2; exit 2 ;; esac
	spinel-doctor --quiet --skip $(DIAGNOSE_SKIP) "$(T)" -- $$(spin flags) -O $(TEST_OPT)

## bench: build the key benchmark bench/keys.rb into build/bench and run its scenarios (all, or SCENARIOS="lh j"): time per key for handling and rendering, the slowest key, bytes written, the collector's share, and allocations per key, pinned to one core when taskset exists
bench:
	@mkdir -p build/bench
	spinel $$(spin flags) bench/keys.rb -o build/bench/keys
	sh bench/run.sh $(SCENARIOS)

## bench-budget: build the key benchmark with the development flags into build/bench/keys-budget (allocations are the same at -O 0 as at -O 2) and fail when one key of the cursor scenario (lh) allocates ALLOC_BUDGET objects or more (default 100); CI runs it
bench-budget:
	@mkdir -p build/bench
	@rm -f $(BUDGET_BIN)
	@echo "spinel bench/keys.rb $(DEV_FLAGS) -o $(BUDGET_BIN)"
	@SP_TIMING=1 spinel $$(spin flags) bench/keys.rb $(DEV_FLAGS) -o $(BUDGET_BIN) 2> $(BUDGET_BIN).timing; \
	  status=$$?; grep -v '^spinel-timing' $(BUDGET_BIN).timing >&2; \
	  if [ $$status -ne 0 ]; then echo "bench-budget: bench/keys.rb did not compile" >&2; exit 1; fi
	@$(UNIT_SUMMARY) $(BUDGET_BIN).timing
	BENCH_BIN=$(BUDGET_BIN) sh bench/run.sh --budget lh $(ALLOC_BUDGET)

## metrics: measure the tree into build/metrics/current.tsv from the reports and the binary of dev-build, test-build, and bench-budget: the re-narrowing rounds and analysis milliseconds of both compile roots, and allocations and time per key of eight scenarios (or SCENARIOS="lh j")
metrics:
	sh tools/metrics.sh measure $(METRICS_OUT) $(SCENARIOS)

## metrics-compare: compare build/metrics/current.tsv with BASE_METRICS (default build/metrics/base.tsv): fail when allocations per key or re-narrowing rounds grew, warn when time grew by more than TIME_TOLERANCE percent (default 20); pass with a notice when there is no base
metrics-compare:
	sh tools/metrics.sh compare $(BASE_METRICS) $(METRICS_OUT)

## profile: build the key benchmark with spinel --profile into build/profile and, when perf works (or PERF names one that does), record the j and lh scenarios and print the top functions by self time with their Ruby names
profile:
	@mkdir -p build/profile
	spinel $$(spin flags) bench/keys.rb --profile -o build/profile/keys
	sh bench/profile.sh build/profile/keys

## analysis-budget: compile ANALYSIS_ROOTS (default bin/carat.rb and the test runner) to C one after another with SP_TIMING=1 and fail when Spinel's analysis of one needs more than ANALYSIS_ROUNDS re-narrowing rounds (default 2); warn when it takes more than ANALYSIS_MS milliseconds (default 45000). make test-build checks the runner's own report
analysis-budget:
	SPIN_FLAGS="$$(spin flags)" sh tools/analysis_budget.sh $(ANALYSIS_ROUNDS) $(ANALYSIS_MS) $(ANALYSIS_ROOTS)

## types: print the signatures Spinel inferred for the editor, marking where inference widened to untyped
types:
	@mkdir -p build
	spinel $$(spin flags) bin/carat.rb --emit-rbs -o build/carat.rbs >/dev/null
	@cat build/carat.rbs

## gen-config: regenerate carat/domain/default_config.rb and carat/plugins/registry.rb from config/
gen-config:
	spin run carat-gen-config

## config-current: run gen-config and fail when it changed the config mirror or the plugin registry, which were then stale
config-current:
	@before=$$(cat $(GENERATED) | cksum); \
	$(MAKE) --no-print-directory gen-config || exit 1; \
	if [ "$$(cat $(GENERATED) | cksum)" != "$$before" ]; then \
	  echo "config-current: make gen-config rewrote $(GENERATED); commit what it wrote" >&2; exit 1; \
	fi; \
	echo "config-current: $(GENERATED) match config/"

## tools-test: test the shell tools in temporary repositories: tools/ci_scope.sh, tools/metrics.sh, tools/run_state.sh, and every gate of tools/gates.sh, passing and refusing
tools-test:
	sh tools/tools_test.sh

## docs-lint: check the documents agents read (tools/docs_lint.sh): CLAUDE.md within 30 KiB, each agent file within 8 KiB, docs/architecture.md within its budget, no URL, email, session id, or model name, no hard-wrapped pull request text, and no backticked path that does not exist
docs-lint:
	sh tools/docs_lint.sh

## gates: run the rule gates that need only git on the branch against origin/main (trailer, content, snapshots, docs); tools/gates.sh has the rest
gates:
	sh tools/gates.sh static

## stages: print the canonical stage list, CHECK_STAGES, which make check and the checker run in order
stages:
	@echo $(CHECK_STAGES)

## check-stage: run one stage of CHECK_STAGES as make check runs it, e.g. make check-stage S=diagnose
check-stage: DIAGNOSE_SKIP = $(CHECK_SKIP)
check-stage:
	@case " $(CHECK_STAGES) " in *" $(S) "*) ;; *) echo "usage: make check-stage S=STAGE, one of: $(CHECK_STAGES)" >&2; exit 2 ;; esac
	@$(MAKE) --no-print-directory $(S) DIAGNOSE_SKIP=$(DIAGNOSE_SKIP)

## check: everything a push needs, the stages of CHECK_STAGES in order: doctor, docs-lint, build, dev-build and test-build with their analysis budgets, config-current, test-run, diagnose with the legs that can fail it, no-cruby, bench-budget, metrics, tools-test, and gates
check: DIAGNOSE_SKIP = $(CHECK_SKIP)
check: $(CHECK_STAGES)

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
	@echo "Variables: SPINEL_SRC=$(SPINEL_SRC)  SPINEL_REPO=$(SPINEL_REPO)  SPINEL_REF=$(SPINEL_REF)  PREFIX=$(PREFIX)  FILE=$(FILE)  T=$(T)  TEST_OPT=$(TEST_OPT)  SPINEL_CACHE_DIR=$(SPINEL_CACHE_DIR)  CARAT_BIN=$(CARAT_BIN)  TESTS=$(TESTS)"

.PHONY: toolchain toolchain-clean spinel-rev doctor no-cruby build dev-build run install pack clean test test-build test-run test-one lint snapshots diagnose diagnose-one bench bench-budget analysis-budget profile types gen-config config-current tools-test docs-lint gates stages check-stage check spec-list spec-validate spec-update help
