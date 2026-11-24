# Backlog: tools/metrics.sh

## metrics compare passes a strict metric missing from the run

- Where: `compare` in `tools/metrics.sh` line 86 at 38628bb (periodic quality). Queued in `run-budgets-tidy`. Raised again at be4b63a, notes 23 and 43 (owner `run-budgets-tidy`).
- Why it matters: only the current names are walked, so an `allocs.*` or `rounds.*` name of the base that the run lacks passes, against the header's rule.
- Fix outline: fail each strict base name not seen, with a `tools/tools_test.sh` case.
- Raised again at 6a0db20 (periodic quality, note 47): `tools/metrics.sh:86`. Owner: queue item `run-budgets-tidy`.
- Also: tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-09

## metrics.sh ignores a failed field read

- Where: `tools/metrics.sh` lines 55 and 57 at 3895e21 (`set --` from `analysis_budget.sh --fields`). Periodic quality advisory. Queue item `run-budgets-tidy`.
- Why it matters: a failure stops on `set -u` with an unclear message and leaves the temporary output file.
- Fix outline: read the fields into a variable with `|| die`, check both, and remove the temporary file on failure.
- Category: pipeline
- Added: 2026-11-09

### metrics compare ignores a missing figure

- Location: tools/metrics.sh:86 and :55 (sprint-4 sweep, quality).
- Why: compare walks only CURRENT, so a base scenario with no current line passes; line 55 splits fields unquoted, so a ? field globs.
- Fix: fail each strict base name not seen; read the fields with read.
- Category: pipeline
- Added: 2026-11-14

### metrics.sh compare passes a base key the current run lacks
- Location: tools/metrics.sh:86
- Why: compare reads only CURRENT's names, so an allocs.* or rounds.* key in BASE that CURRENT lacks passes, though the header says a value not measured fails. Folded into tools-docs-tidy.
- Fix: print FAIL in END for each strict base key never seen in CURRENT.
- Category: pipeline
- Added: 2026-11-17

### metrics.sh compare passes a base name never measured

- Location: tools/metrics.sh:85, :17 (sweep, quality).
- Why: compare walks only the current file, so a strict base allocs or rounds name missing from the current run passes, against the header.
- Fix outline: mark names seen and fail every unseen strict base name in END.
- Category: pipeline
- Added: 2026-11-17

### Tools pass what their usage says fails (sprint-18 sweep quality)
- Location: `tools/metrics.sh:86`; `tools/gates.sh:266`; `tools/run_state.sh:2538`; `tools/spec_validate.sh:25`; `tools/ci_scope.sh:80`.
- Why it matters: compare passes a base name CURRENT lacks; `has()` matches paths as a regex; backlog-oldest skips `####` entries backlog-pick takes; only the last spec preview survives; the push path calls one endpoint twice.
- Fix outline: fail every unseen strict base name; `grep -q -x -F`; one heading test in ENTRY_AWK; a preview directory per change; one gh call.
- Also: tools/gates.sh, tools/run_state.sh, tools/spec_validate.sh, tools/ci_scope.sh
- Category: pipeline
- Added: 2026-11-18

### metrics compare passes a strict base name the current run lacks (sprint-24 sweep quality)

- Location: `tools/metrics.sh:104`
- Why: compare walks only CURRENT's names, so an allocs or rounds name in BASE that the bench did not print passes, and an empty value counts as 0, though the usage says a value not measured fails.
- Fix: fail in END for every unseen strict base name and treat an empty value as unmeasured.
- Category: pipeline
- Added: 2026-11-21

### compare ignores a name present only in BASE, so at tools/metrics.sh:110 (sprint-26 sweep quality, note 43)

- Location: tools/metrics.sh:110
- Why: compare ignores a name present only in BASE, so an allocs.* or rounds.* line missing from CURRENT passes silently, though the usage at :18 says an unmeasured strict value fails and run_state.sh bench_compare reports base keys not seen
- Fix: in the END block, FAIL each allocs or rounds name of BASE absent from CURRENT
- Category: pipeline
- Added: 2026-11-22
- Merged: ### tools/metrics.sh:110: compare walks only the names of CURRENT, so an (sprint-22 sweep quality)
- Location: `tools/metrics.sh:110`
- Why: compare walks only the names of CURRENT, so an allocs or rounds name present in BASE and missing from CURRENT passes silently, against the usage (fail when not measured) and unlike run_state.sh bench_compare, which reports it as none
- Fix: in END, fail for each strict base name not seen

### The benchmark cannot see growth in the float, finder, or palette allocations (picker-speed retro note 4)
- Location: tools/metrics.sh (the allocs column), bench/run.sh `PICKER_BUDGETS`.
- Why: tools/metrics.sh records no lh-float, finder, or palette allocations, so make metrics-compare cannot fail on their growth; PICKER_BUDGETS allows about 60 percent growth under its fixed maxima.
- Fix: record lh-float, finder, and palette in the allocs column; accepted when the next metrics row holds them and a growth of one object a key in any of them fails make metrics-compare.
- Also: bench/run.sh
- Category: pipeline
- Added: 2026-11-22

### metrics compare passes a base name current lacks at tools/metrics.sh:104 (sprint-28 sweep quality, notes 11, 43)

- Location: tools/metrics.sh:104, :19
- Why: compare walks only CURRENT, so a scenario dropped from DEFAULT_SCENARIOS or an unparsed bench line passes, against the header's "a value not measured fails".
- Fix: in END fail each strict base name not seen, or reword the header if a subset must pass.
- Category: pipeline
- Added: 2026-11-22

### allocs.grep measured 685.3 once on identical sources
- Location: tools/metrics.sh measure, the grep scenario of bench/keys.rb
- Why: the metrics stage of the first check of this change read allocs.grep 685.3 against main's 685.0 though carat/, bench/, and the Makefile equal main's; three reruns of the same binary read 685.0 and the rerun check passed, so the allocation count of the grep scenario varies with load, which would block an unrelated change at random.
- Fix: find what in the grep picker's setup varies (a reader thread's timing, or the stages running beside the metrics stage), make the count exact or have measure take the lowest of a few runs for grep.
none
- Also: bench/keys.rb, Makefile
- Category: pipeline
- Added: 2026-11-23

### compare walks only the current file, so an allocs.* at tools/metrics.sh:105 (sprint-30 sweep quality, note 57)

- Location: tools/metrics.sh:105
- Why: gap against its usage: compare walks only the current file, so an allocs.* or rounds.* name the base holds but the current measurement lacks passes silently, though the usage says such a value fails when not measured
- Fix: mark names seen and, in END, fail each strict base name the current file did not hold
- Category: pipeline
- Added: 2026-11-23

### compare reports only the names in the current measurement, so at tools/metrics.sh:105 (sprint-32 sweep quality, note 54)
- Location: tools/metrics.sh:105
- Why: compare reports only the names in the current measurement, so a strict allocs or rounds metric present in the base and missing from current (a dropped scenario) passes silently
- Fix: in END, print a FAIL line for each strict base name that current did not hold
- Category: quality
