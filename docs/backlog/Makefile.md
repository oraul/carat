# Backlog: Makefile

## make types leaves build/carat.rbs that a later spin build warns about

- Where: the `types` target in the `Makefile` writes `build/carat.rbs` with `--emit-rbs`, inside the tree `spin` scans.
- Why it matters: `spinel_rbs_extract` reports a parse failure on the emitted file at every later `spin build`, `spin test`, and `make snapshots`, because of a doubled namespace separator in the class names it writes; the noise hides real warnings and the file has to be deleted by hand. Observed during the Struct change and again during the command grammar change.
- Fix outline: have the `types` target write the file outside the `spin` source tree, or delete it after printing.
- Category: pipeline
- Added: 2026-10-28

## Spinel f34005bf miscompiles versioned entries and case constants

- Where: the pinned Spinel (`SPINEL_REF` in the `Makefile`), new between 001419ff and f34005bf: the version entries of `src/call_plan.c` (#9898) and the constant readers of `case`/`when`; worked around in `carat/use_cases/plugins/plugin_entry.rb` (`attach`), `carat/domain/mode.rb` (`visual_kind`), `Host#icon` and `Host#stat` in `carat/plugin_api.rb`, and `FilePort#stat` in `carat/ports/file_port.rb`.
- Why it matters: without the workarounds the release build does not compile (an entry's parameter typed from the argument's class, not the dispatched signature), charwise visual selections read as none (a `when` on a constant whose name another scope defines with another type folds to false), and `make diagnose` reports unresolved readers (an entry's return joins a raising base's `nil`); `docs/spinel-notes.md`, Known miscompilations, has the mechanism.
- Fix outline: report each upstream with its reduced probe (the `when` probe: two modules defining `VISUAL` as a Symbol and an Integer, a `case` on the Symbol), then drop the workarounds in the bump that carries the fix. The `when` defect bisects to Spinel ade8cfe2; the versioned-entry defects have no reduced probe yet (a one-file probe of the plugin shape compiles at both pins), so the report names the carat build that shows them. `PluginEntry#attach(host)` (`carat/use_cases/plugins/plugin_entry.rb:51`) is a one-value setter not named `link=`, kept only because the Struct writer does not upcast (quality advisory at spinel-bump): the bump that clears this entry drops it for `self.link=`.
- Also: carat/use_cases/plugins/plugin_entry.rb, carat/domain/mode.rb, carat/plugin_api.rb, carat/ports/file_port.rb, docs/spinel-notes.md
- Category: pipeline
- Added: 2026-11-10

## Spinel loses the types of an array destructured inside a method

- Where: the pinned Spinel (`SPINEL_REF` in the `Makefile`); seen in the test helpers `setup` of `test/use_cases_plugins.rb`, `editor` of `test/use_cases_plugin_files.rb`, and `run` of `test/domain_grammar.rb`, which returned `[a, b, ...]` for the caller to destructure (`state, host, keymap, files, ex = setup(...)`).
- Why it matters: at the top level of a program those locals kept their types, but once the `test-build` change moved each test's statements into a method, they became poly: in `test/use_cases_plugins.rb` the generated C did not compile (`expected statement before ')'` at each `state.cursor.row = 1`), and in the other two spinel-doctor reported unresolved calls on poly receivers. A minimal program with three values of three classes kept its types, so the trigger is not yet isolated. The helpers now return an object with typed readers, which is the convention in `CLAUDE.md`; production code has no such destructuring.
- Fix outline: restore the array return of `setup` in `test/use_cases_plugins.rb` and reduce it to a minimal reproduction (five values from a helper, destructured twenty times inside one method, one of them an attribute chain assigned through), report it upstream to Spinel, and drop the convention once a `SPINEL_REF` bump compiles it typed. Rechecked at f34005bf: the reduced probe keeps its types at both 001419ff and f34005bf, so only reverting a helper decides it.
- Also: test/use_cases_plugins.rb, test/use_cases_plugin_files.rb, test/domain_grammar.rb, CLAUDE.md
- Category: pipeline
- Added: 2026-11-03

## Spinel answers a method's argument for some string returns

- Where: the pinned Spinel (`SPINEL_REF` in the `Makefile`); seen in `carat/domain/rc_value.rb` and `carat/domain/config.rb` during the `caratrc-config` change. `RcValue.expectation(kind)`, written as a `case` whose branches were string literals, answered the kind itself when called with a literal; `RcValue.text(words, kind)`, written as `words.empty? ? "" : words[0].to_s`, answered the kind; and `SCOPES.include?(line.scope)` answered false for a scope the array holds, while the same call through a local answered true.
- Why it matters: each is silent wrong code, not a compile error; only the table tests caught them. The three places are rewritten (guard returns, a local for the first word, a local for the scope), but the same shapes elsewhere could be affected.
- Fix outline: reduce each to a minimal program (a module function with a literal-branch `case` called with a literal; a ternary of `""` and an indexed `to_s` in a two-parameter method; a constant array's `include?` of a reader called on a `Data` value; a guard `return path if slash.nil?` before `path.byteslice(...).to_s`, which answered the path inside the whole program in `PluginApi::Paths.basename` during `utf8-input-safety` though not in a small probe), report them upstream, and recheck them when `SPINEL_REF` is bumped. Rechecked at f34005bf: the four reduced shapes answer correctly at both pins, so only reverting the rewritten places decides it.
- Also: carat/domain/rc_value.rb, carat/domain/config.rb
- Category: pipeline
- Added: 2026-11-03

## Spinel compiles private_constant without enforcing it

- Where: the pinned Spinel (`SPINEL_REF` in the `Makefile`); every `private_constant` line under `carat/use_cases/` since the `use-case-boundaries` change.
- Why it matters: a probe on the pinned compiler compiled `private_constant :NAME` and still let another class read `Owner::NAME`, which CRuby refuses with `NameError`, so the declaration documents the intent but stops nothing. `private` on methods is enforced (a call raises `NoMethodError`). `test/lint.rb` carries the rule instead: every constant of a use case file is listed in a `private_constant`, and no file names `Owner::NAME` of a use case outside its own file.
- Fix outline: reduce it to a minimal program (a class with a private constant read from another class), report it upstream, and when a `SPINEL_REF` bump enforces it, keep the lint rule only as a check that the list is complete. Rechecked at f34005bf: still open, the probe still reads `Owner::NAME` from another class.
- Also: test/lint.rb
- Category: pipeline
- Added: 2026-11-03

## The docs of tools-test and /review lag the workflows

- Where: the `tools-test` help line of the `Makefile` (line 355 at 594dd35) lists the shell tools but not the workflow helpers it now runs with node; `.claude/commands/review.md` (line 8) says the quality reviewer reviews the whole tree; the guard case of `tools/tools_test.sh` (line 1000) still uses `tmp/.review-quality` while the workflow names `tmp/.review-quality-N`. Quality advisories in `partial-results`.
- Why it matters: `make help` and `/review` describe what no longer runs, and the guard case tests a path the workflow no longer uses.
- Fix outline: add the workflows' pure helpers (node) to the help line, say the security reviewer and three quality starts over the code map areas in `review.md`, and use `tmp/.review-quality-1` in the guard case.
- Also: .claude/commands/review.md, tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-07

## The Makefile's header, compile recipes, and docs-lint help drift

- Where: `Makefile` line 3, the compile recipe at lines 221, 255, and 312, and the docs-lint help at line 359, at 38628bb (periodic quality). Queued in `run-budgets-tidy`.
- Why it matters: the header says every target wraps spin or OpenSpec while seven call spinel; three targets copy one timing recipe; the help omits the queue budget and check.
- Fix outline: correct the header, one recipe for the three, and name the queue budget in the help.
- Raised again at 6a0db20 (periodic quality, note 45): `Makefile:238`, `:272`, `:329`. Owner: queue item `run-budgets-tidy`.
- Raised again as "The Makefile repeats its timed compile and misdescribes gates": Where: `Makefile:241`, `:275`, `:332`, `:383`. Periodic quality advisory. Fix outline: one `define timed_compile`; describe static as the gates that need no run state, here and in CLAUDE.md. Queue item `check-skip`.
- Also: CLAUDE.md
- Category: pipeline
- Added: 2026-11-09

## The .PHONY list leaves out metrics

- Where: `Makefile` line 432, at b76b722. Periodic quality. Queue item `run-budgets-tidy`. Raised again at ce6abdb, `metrics-compare` missing too (periodic quality). Raised again at be4b63a (owner `check-skip`).
- Why it matters: a file or directory named `metrics` at the top would make `make metrics` answer up to date and skip the measurement the check stage records.
- Fix outline: add `metrics` and `metrics-compare` to `.PHONY`.
- Category: pipeline
- Added: 2026-11-09

## toolchain-clean deletes all of tmp/ and ignores its overrides

- Where: `toolchain-clean` in the `Makefile` line 158, its help line 156, and `README.md` line 20 at 847851d. Periodic quality. Queue item `check-runner-safety`.
- Why it matters: it removes the scout packs and the merge-gates and review worktrees, leaving stale worktree records, yet ignores the `SPINEL_SRC` and `PREFIX` overrides that `docs/architecture.md` section 2 says it removes.
- Fix outline: remove only the two toolchain paths, and say so in the help line and the README row.
- Also: README.md, docs/architecture.md
- Category: pipeline
- Added: 2026-11-09

## Tooling copies and help gaps found by the periodic review at 2f54bb5

- Where: the timed development compile recipe copied in `dev-build`, `test-build`, and `bench-budget` (`Makefile` lines 221, 255, 312); the `make help` variables line omits `ALLOC_BUDGET`, `SCENARIOS`, `ANALYSIS_ROOTS`, `ANALYSIS_ROUNDS`, `ANALYSIS_MS`, `BASE_METRICS`, `S`, and the generator variables (line 430); the `usage` function in `tools/run_state.sh` (line 1460) shares its name with the `usage` command, and `push` (line 1555) has no argument-count check; `docs/codebase-map.md` line 48 leaves `sort_form` and `uniq_form` out of the guard's form list. Periodic quality at 2f54bb5. Queued in `run-budgets-tidy` and `docs-index`.
- Why it matters: three copies drift, and `make help` and the map fail to name what CLAUDE.md says they name.
- Fix outline: one `define` macro for the recipe; every variable a target reads in the help line; rename the function `print_usage` and refuse a second `push` argument; name both forms in the map.
- Also: tools/run_state.sh, docs/codebase-map.md, CLAUDE.md
- Category: pipeline
- Added: 2026-11-10

## Stale places in the Makefile, CLAUDE.md, the rules script, and carat.rb

- Where: `Makefile` line 19 (the `SPINEL_REF` comment sends the header regeneration to the toolchain target, not `spinel-header`); `CLAUDE.md` line 21 and `tools/rules.sh` line 34 (the allowed URL is in the shared Spinel checkout recipe, not the toolchain target); the CLAUDE.md buffer text bullet (`LeaveInsert` opens no transaction, it closes the insert session the dispatcher left open); `carat.rb` line 332 (`carat/adapters/indent_guides.rb` missing from the production require graph). Periodic quality at e49f63d.
- Why it matters: each sends a reader to the wrong place, and the require graph header says every file is pulled in once.
- Fix outline: correct each sentence and add the require. Queue item: `docs-index`.
- Also: CLAUDE.md, carat.rb, tools/rules.sh, carat/adapters/indent_guides.rb
- Category: pipeline
- Added: 2026-11-10

## The analysis budget warns on every build and passes a non-numeric rounds value

- Where: `Makefile:78` (22 to 26 s and `ANALYSIS_MS` 45000, also `docs/architecture.md` line 346, against 39.0 s and 92.3 s at #95); `tools/analysis_budget.sh:67` (the rounds test errors and passes on a non-number). Periodic quality at 9a92265.
- Why it matters: a warning on every build carries no signal, and a broken figure passes.
- Fix outline: refresh the threshold per root, and refuse a non-numeric value with a case. Queue item `run-budgets-tidy`.
- Also: docs/architecture.md, tools/analysis_budget.sh
- Category: pipeline
- Added: 2026-11-10

## Docs drift found at bd86828

- Where: `Makefile:385` and :389 (the tools-test help omits the scanner and the pull request scan; docs-lint omits secrets); `README.md:15` (no `make spinel-rev` row); `docs/codebase-map.md:331`, 360, 421 (Selection, Layout, ExTable methods missing; `HistoryCommandHandler.digits?` listed public). Periodic quality.
- Why it matters: agents plan from these documents.
- Fix outline: correct each. Queue item `docs-index`.
- Also: README.md, docs/codebase-map.md
- Category: pipeline
- Added: 2026-11-11

## The toolchain checkout's git config is unchecked

- Where: `Makefile:145` (`spinel_checkout` runs git in `tmp/.spinel`), linked writable into check clones at `tools/run_state.sh:529`. Periodic security Low (4) at d0d783c.
- Why it matters: a stage can plant `core.fsmonitor` in `tmp/.spinel/.git/config` that the next `make toolchain` or `spinel-header` runs.
- Fix outline: run its git with `GIT_CONFIG_GLOBAL=/dev/null` and refuse a `RISKY_CONFIG` key in that config, or stop linking `tmp/.spinel` into the check clone. Queue item `check-runner-safety`.
- Also: tools/run_state.sh
- Category: security
- Added: 2026-11-11

## delivery-speed quality advisory at Makefile:398

- Where: `Makefile:398`. Delivery review of `delivery-speed` (quality advisory) at 2dcfd3d.
- Why it matters: the check help still calls CHECK_STAGES everything a push needs, while a push now needs FAST_STAGES and CI runs the rest.
- Fix outline: call it every stage, the checker's and CI's.
- Category: pipeline
- Added: 2026-11-11

### The development compile is copied in three targets

- Location: Makefile:245, :279, :336 (sprint-4 sweep, quality advisory).
- Why: dev-build, test-build, and bench-budget repeat SP_TIMING, the timing filter, the failure message, and UNIT_SUMMARY.
- Fix: one define dev_compile called by the three.
- Category: pipeline
- Added: 2026-11-14

### toolchain-clean removes all of tmp

- Location: Makefile:182 (sprint-4 sweep, quality advisory).
- Why: `rm -rf tmp` also deletes linked worktrees and tmp/scout, leaving stale worktree records, against its help text.
- Fix: remove SPINEL_SRC and PREFIX only, or run git worktree prune after.
- Category: pipeline
- Added: 2026-11-14

### make help and tool headers drift from the code

- Location: Makefile:454 and :379, tools/tools_test.sh:2-12, tools/docs_lint.sh:19, tools/gates.sh:36 and :62, tools/run_state.sh:137 (sprint-4 sweep, quality advisory).
- Why: help omits ten variables and three tested scripts; docs_lint says 1 to 5 sprint items where it accepts 0 to 5; gates omits FAST_STAGES; run_state's usage splits the review-due entry around ci-stages and tokens.
- Fix: correct each text.
- Also: tools/tools_test.sh, tools/docs_lint.sh, tools/gates.sh, tools/run_state.sh
- Category: pipeline
- Added: 2026-11-14

### Makefile:317 the Spinel warning recipe is repeated in every compile target

- Where: Makefile:317, and the build, test-one, bench, types, and gen-config targets, with near copies in dev-build, test-build, and bench-budget.
- Why: the same capture-stderr, keep-status, copy-back, fail-on-status, check recipe is copied target by target, so a fix to one copy drifts from the others (quality advisory, duplication).
- Fix: one script mode, for example sh tools/spinel_warnings.sh run LABEL LOG -- CMD..., keeping the status and the check in one place.
- Also: tools/spinel_warnings.sh
- Category: pipeline
- Added: 2026-11-15

### Makefile:248 make build no longer streams the standard error of spin build

- Where: Makefile:248, the build target.
- Why: make build now holds all of spin build's standard error until it exits, so Spinel and cc errors of the minute-long release build no longer stream and an interrupted build shows none (quality advisory, behavior).
- Fix: tee standard error into BUILD_LOG while keeping spin's status.
- Category: pipeline
- Added: 2026-11-15

### Makefile:87 BUILD_BINS lists the binaries by hand

- Where: Makefile:87.
- Why: BUILD_BINS spells out build/bin/carat-gen-config beside GEN_CONFIG_BIN and lists the binaries by hand while spin build compiles every bin/*.rb, so a new bin/*.rb that warns keeps its binary and a second make build passes silently (quality advisory, duplication and drift).
- Fix: BUILD_BINS ?= $(patsubst bin/%.rb,build/bin/%,$(wildcard bin/*.rb)) and GEN_CONFIG_BIN built from it or the reverse.
- Category: pipeline
- Added: 2026-11-15

### make snapshots ignores a crashing test

- Location: Makefile:303. Sprint-6 sweep, quality. Queue item `tools-docs-tidy`.
- Why: the runner's exit status per test is ignored, so a crash's output becomes its snapshot with only a manual diff review before a commit.
- Fix outline: note each nonzero exit and exit 1 after the loop.
- Category: pipeline
- Added: 2026-11-15

### make types leaves build/carat.rbs that breaks every later compile

- Location: Makefile types target, build/carat.rbs read by spin --rbs
- Why: after make types, every later Spinel compile reads the stale build/carat.rbs and fails until the file is deleted
- Fix: write the types output outside the path spin reads, or delete it at the end of the target, with a tools_test case
- Category: pipeline
- Added: 2026-11-15

### Spinel warnings print twice in each guarded compile target

- Location: Makefile:254, and the build, dev-build, test-build, test-one, bench, bench-budget, types, and gen-config targets (sprint-7 review, quality, shell output).
- Why: each guarded target echoes its whole log to standard error, then tools/spinel_warnings.sh check prints the same warning lines again, so every Spinel warning shows twice and a reader counts it twice.
- Fix outline: leave the warning lines out of the echoed log, or have check print only its summary line. Queue item `tools-docs-tidy`.
- Also: tools/spinel_warnings.sh
- Category: pipeline
- Added: 2026-11-15

### The Makefile comment on the CI stages reads unclearly

- Location: Makefile:122
- Why: the comment 'Every other stage runs once, in CI, on every pull request, but build on main.' reads unclearly (quality advisory, ci-time-tidy-b).
- Fix: '... on every pull request, except build, which runs on a push to main (.github/workflows/main.yml).'
- Also: .github/workflows/main.yml
- Category: pipeline
- Added: 2026-11-16

### toolchain-clean deletes every lane worktree under tmp

- Location: Makefile:203; docs/architecture.md:33; README.md:21 (sweep, quality, blocking).
- Why: toolchain-clean runs rm -rf tmp, which also deletes each stopped delivery's worktree tmp/.lane-CHANGE (uncommitted work kept for its resume), tmp/.merge-gates, the review worktrees, and tmp/scout, leaving dangling worktree records; it ignores the SPINEL_SRC and PREFIX overrides the architecture says it honors.
- Fix outline: remove only "$(SPINEL_SRC)" and "$(PREFIX)", and say so in its help line and README.md:21.
- Also: docs/architecture.md, README.md
- Category: pipeline
- Added: 2026-11-17

### The tools-test help line omits four scripts

- Location: Makefile:433 (sweep, quality).
- Why: it leaves out open_pr.sh, scan_text.sh, pr_scan.sh, and rules.sh.
- Fix outline: name them, or say every script under tools/.
- Category: pipeline
- Added: 2026-11-17

### .PHONY leaves out metrics and metrics-compare (sprint-16 sweep quality)

- Location: Makefile:510 (targets at :389, :393).
- Why: a file named metrics would quietly stop make metrics.
- Fix outline: add both targets to .PHONY.
- Category: pipeline
- Added: 2026-11-18

### The grep scenario runs twice in the fast stages
- Location: Makefile:387 (bench-budget), tools/metrics.sh (measure)
- Why: make bench-budget prints the grep scenario's figures and make metrics now measures the same scenario at the same keys, so each check spends the grep runs over 150,000 lines twice.
- Fix: drop the grep line of bench-budget, since make metrics records and compares the figure, and update its help text, the map, and the Makefile's stage notes.
- Also: tools/metrics.sh
- Category: pipeline
- Added: 2026-11-20

### The OpenSpec pin leaves its transitive dependencies unpinned (`pr-trust-lows` security Low (5), three passes, and quality advisory)
- Location: Makefile:139 and :140 (`OPENSPEC_PACKAGE`), tools/spec_validate.sh:18, tools/agent_guard.sh:902; the design's residual-risk sentence (archived design.md:11, tasks.md:22).
- Why: pinning `@fission-ai/openspec@2.1.1` fixes only the top-level package; with no lockfile, npx resolves the package's dependency ranges afresh on a cold cache, so a hijacked dependency of OpenSpec could still run code in the contributor or checker session that holds the push credentials. Reported at d388c4a, again at ee4ce6c (which added CLAUDE.md as a fourth place the pin must match, no lockfile), and at d005798 (which only reworded the design to say the risk is recorded for a later change); this entry is that record.
- Fix: commit a package.json and a package-lock.json with integrity hashes for OpenSpec under tools/, install it with `npm ci --ignore-scripts`, and run the installed binary instead of npx in the Makefile, tools/spec_validate.sh, the guard's allowlist, and CLAUDE.md's OpenSpec line, keeping the tools-test pin comparison over the new form.
- Also: tools/spec_validate.sh, tools/agent_guard.sh, CLAUDE.md
- Category: security
- Added: 2026-11-20

### Makefile:212: spinel-rev resolves a branch or tag name though SPINEL_REF (sprint-22 sweep quality)

- Location: `Makefile:212`
- Why: spinel-rev resolves a branch or tag name though SPINEL_REF is a pinned commit, and prints nothing with exit 0 when ls-remote finds no ref, leaving CI an empty cache key
- Fix: drop the branch path (speculative), or fail on an empty answer
- Category: pipeline
- Added: 2026-11-20

### Makefile:440: the tools-test help lists the scripts it tests but (sprint-22 sweep quality)

- Location: `Makefile:440`
- Why: the tools-test help lists the scripts it tests but leaves out tools/open_pr.sh, tools/scan_text.sh, tools/pr_scan.sh, and tools/rules.sh, which tools_test.sh covers
- Fix: name them, or say every script under tools/
- Also: tools/open_pr.sh, tools/scan_text.sh, tools/pr_scan.sh, tools/rules.sh
- Category: pipeline
- Added: 2026-11-20

### Makefile:140: the OpenSpec version 2.1.1 is spelled out in four (sprint-22 review quality)

- Location: `Makefile:140`
- Why: the OpenSpec version 2.1.1 is spelled out in four files (Makefile OPENSPEC_PACKAGE, tools/spec_validate.sh:18, tools/agent_guard.sh:902, CLAUDE.md:194) and kept equal only by a tools test (one way to do each thing)
- Fix: have make spec-validate pass OPENSPEC_CMD built from $(OPENSPEC_PACKAGE) so spec_validate.sh needs no literal, leaving only the guard and CLAUDE.md to mirror it
- Also reported: sprint-22 sweep note 20 (tools/spec_validate.sh:18)


none
- Also: tools/spec_validate.sh, tools/agent_guard.sh, CLAUDE.md
- Category: pipeline
- Added: 2026-11-20

### toolchain-clean deletes every lane worktree under tmp (sprint-24 sweep quality)

- Location: `Makefile:209`
- Why: `rm -rf tmp` deletes the kept worktrees of stopped runs with their uncommitted work, the review and merge-gate worktrees, and the scout packs, leaves stale worktree records, and ignores the SPINEL_SRC and PREFIX overrides `docs/architecture.md` section 2 promises.
- Fix: remove `$(SPINEL_SRC)` and `$(PREFIX)` only and correct the README row and the help line.
- Also: docs/architecture.md
- Category: pipeline
- Added: 2026-11-21

### The command-line popup's allocation budget is measured, not gated
- Location: Makefile `bench-budget`, bench/keys.rb `cmdline-tab`
- Why: `bench-budget` fails only on `lh`; the popup scenario measured 79.5 objects per key, under the budget of 100, but a later change could raise it unnoticed.
- Fix: add `sh bench/run.sh --budget cmdline-tab $(ALLOC_BUDGET)` to `bench-budget`, with the CLAUDE.md line the Makefile rule asks for.
- Also: bench/keys.rb, bench/run.sh, CLAUDE.md
- Category: pipeline
- Added: 2026-11-21
