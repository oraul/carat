# Backlog: bench/run.sh

## The benchmark reuses one temporary report path

- Where: `bench/run.sh` (line 22, `REPORT=$(mktemp "${TMPDIR:-/tmp}/carat-bench-alloc.XXXXXX")`), deleted after the first scenario and reused by name for the later ones, with no trap, and created before the binary check. Low finding of the periodic security review at 66fd52b.
- Why it matters: on a shared `/tmp` another user can plant a symlink at the freed name, which `SPINEL_ALLOC_REPORT` then writes through.
- Fix outline: create the file with `mktemp` inside each `per_key` call, or make a private `mktemp -d` directory removed by a `trap`, after the binary check.
- Category: security
- Added: 2026-11-03

## The bench scenario list has drifted from the scenarios

- Where: `bench/run.sh` line 69 at cd87445 copies the `SCENARIOS` of `bench/keys.rb` line 104 and omits `lh-float`, `lh-winbar`, and `n` (`file-finder` added `finder` to it). Periodic quality at cd87445, refreshed at 8d8832f; folded into `docs-index`.
- Why it matters: `make bench` never runs area 13's float benchmark or `n`, so a regression there goes unmeasured.
- Fix outline: take the names from the bench binary or one shared list, with a case that every scenario runs. Queued in the backlog items worth a change.
- Raised again as "The palette bench scenario is not in the default list": Where: `bench/run.sh` line 69, the default scenario list, against `bench/keys.rb` line 145 (`palette`), named in the discovery area's Bench line since `float-frame`. Quality advisory of `float-frame`. Why it matters: `make bench` without `SCENARIOS` never measures the palette, so a regression in its refiltering goes unseen. Fix outline: add `palette` to the default list if it is meant to run by default, or say in the map why it is opt-in. Queue item `run-budgets-tidy`.
- Also: bench/keys.rb
- Category: code-quality
- Added: 2026-11-07

### make bench skips four scenarios

- Location: bench/run.sh:69, bench/keys.rb:118, 119, 143, 145 (sprint-4 sweep, quality).
- Why: the default list is a hand copy that left out lh-float, lh-winbar, n, and palette, though the header says every scenario runs.
- Fix: loop over the names build/bench/keys prints, or add the four.
- Also: bench/keys.rb
- Category: code-quality
- Added: 2026-11-14

### make bench without SCENARIOS skips four scenarios

- Location: bench/run.sh:69, bench/keys.rb (sweep, quality).
- Why: run.sh copies bench/keys.rb's SCENARIOS and lacks lh-float, lh-winbar, n, and palette.
- Fix outline: let bench/keys.rb print its names for run.sh, or add the four.
- Also: bench/keys.rb
- Category: code-quality
- Added: 2026-11-17

### The default scenario list, documented as every scenario when none is (sprint-20 sweep quality, run.sh:69)

- Location: `bench/run.sh:69`
- Why: the default scenario list, documented as every scenario when none is named, omits lh-float, lh-winbar, n, and palette from bench/keys.rb SCENARIOS (named in the Bench lines of map areas 5, 6, and 13), so make bench without SCENARIOS silently skips them; a second hand-kept list of names drifts
- Fix: have bench/keys print its scenario names (a --list argument) and loop over that, removing the list from run.sh
- Also: bench/keys.rb
- Category: code-quality
- Added: 2026-11-19

### tools-test cannot exercise bench/run.sh
- Location: tools/rules.sh:97 (TOOLS_RE), bench/run.sh
- Why: a tools-test case that reads bench/run.sh fails the check that TOOLS_RE covers every path tools-test reads, so the benchmark runner's per-key arithmetic and its budget mode have no test; grep-long-files kept the grep key counts in tools/metrics.sh for that reason.
- Fix: add bench/run.sh to TOOLS_RE in its own change (an edit of the merge gate's rules goes first, alone), then add tools-test cases over a fake benchmark binary for per_key and --budget.
- Also: tools/rules.sh, tools/metrics.sh
- Category: code-quality
- Added: 2026-11-20

### make bench leaves five scenarios unrun (sprint-24 sweep quality)

- Location: `bench/run.sh:69`, `bench/keys.rb`
- Why: the default list omits lh-float, lh-winbar, n, palette, and grep, though the help and the map say every scenario runs.
- Fix: loop over the names `bench/keys.rb` defines.
- Also: bench/keys.rb
- Category: code-quality
- Added: 2026-11-21

### bench/run.sh leaves its report in TMPDIR on an early exit (sprint-24 sweep quality)

- Location: `bench/run.sh:22`
- Why: the report is made before the binary check and removed only by per_key.
- Fix: create it after the check and remove it from an EXIT trap.
- Category: code-quality
- Added: 2026-11-21

### the default scenario list omits lh-float, lh-winbar, n, palette at bench/run.sh:69 (sprint-26 sweep quality, note 31)

- Location: bench/run.sh:69
- Why: the default scenario list omits lh-float, lh-winbar, n, palette, cmdline-tab, and grep, though its usage at :13 and make bench's help say every scenario runs when none is named, so make bench silently skips the float, winbar, and grep scenarios the map's areas 13 and 15 name
- Fix: have bench/keys print its SCENARIOS names and use them as the default, or add the six names
- Category: code-quality
- Added: 2026-11-22
- Merged: ### bench/run.sh:69: the default scenario list (documented as every scenario when (sprint-22 sweep quality)
- Location: `bench/run.sh:69`
- Why: the default scenario list (documented as every scenario when none is named, and the one make bench runs without SCENARIOS) leaves out lh-float, lh-winbar, n, palette, and grep, which bench/keys.rb defines
- Fix: have bench/keys.rb print its SCENARIOS names (for example with a --list argument) and loop over that output, so the list cannot fall out of date
- Also: bench/keys.rb
