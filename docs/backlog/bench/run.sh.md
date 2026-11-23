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
- Merged: ### lh-winbar and n stay out of the default scenario list at bench/run.sh:69 (picker-speed plan, rest of sprint-26 sweep quality note 31)
- Location: `bench/run.sh:69`; scenarios at `bench/keys.rb:123` (`lh-winbar`), `:147` (`n`).
- Why: the sprint-26 heading names four scenarios the default list omits; picker-speed's item covers `lh-float` and `palette` only, so `lh-winbar` and `n` still run only when named and no budget covers them.
- Fix: run both by default with a budget; accepted when `make bench` runs them and `bench-budget` fails on a doubled figure.

### TOOLS_RE does not match bench/run.sh, which tools-test now reads
- Location: `tools/rules.sh:98` (`TOOLS_RE`), `tools/tools_test.sh` (the bench/run.sh section).
- Why: `tools-test` now runs `bench/run.sh` over a fake program, but a change to that file alone does not match `TOOLS_RE`, so the scoped check skips `tools-test` for it. The test finds the runner from the tools directory's parent without the `$here/../` spelling that the coverage test scans, since an edit of `tools/rules.sh` goes first and alone, so the gap is left open on purpose.
- Fix: add `bench/run[.]sh$` to `TOOLS_RE` in its own change, then spell the path in the test as `$here/../bench/run.sh` so the coverage test checks it.
- Also: tools/rules.sh, tools/tools_test.sh
- Category: code-quality
- Added: 2026-11-22

### An empty PICKER_BUDGETS passes bench-budget without checking a picker
- Location: `bench/run.sh` (`--budgets`), `Makefile` (`PICKER_BUDGETS`).
- Why: `make bench-budget PICKER_BUDGETS=` runs `--budgets ""`, which checks no scenario and exits 0, so an override can turn the gate off without a message.
- Fix: refuse an empty list in `--budgets` with exit 2 and a message, with a `tools/tools_test.sh` case.
- Also: Makefile, tools/tools_test.sh
- Category: code-quality
- Added: 2026-11-22


### The benchmark's report file is left behind at bench/run.sh:24 (sprint-28 review quality note 2, sweep notes 10, 34)

- Location: bench/run.sh:23, :24, :72
- Why: REPORT is made by mktemp before the argument checks and never removed on --budgets, the missing-binary exit, or a failed run under set -e, so each `make bench-budget` leaves a file in TMPDIR; per_key removes it after the first scenario and later runs re-create it by name; --budgets passes an empty pair list and dies unbound when it is missing. Also: "## The benchmark reuses one temporary report path".
- Fix: a trap removing it on EXIT, drop the rm in per_key; refuse a missing or empty list with exit 2 and a usage line.
- Category: code-quality
- Added: 2026-11-22

### REPORT is made by mktemp at start but removed at bench/run.sh:5 (sprint-30 sweep quality, note 46)

- Location: bench/run.sh:5
- Why: REPORT is made by mktemp at start but removed only inside per_key, so the missing-binary exit, a failing --budget, and every --budgets run (whose parent never calls per_key and whose children each make their own) leave a carat-bench-alloc file in the temporary directory
- Fix: trap 'rm -f "$REPORT"' EXIT after the mktemp, or make the file inside per_key
- Category: code-quality
- Added: 2026-11-23

### the usage says every scenario runs when none is at bench/run.sh:13 (sprint-30 sweep quality, note 69)

- Location: bench/run.sh:13
- Why: the usage says every scenario runs when none is named, but the default list at line 88 is a hard-coded subset that leaves out lh-winbar, n, cmdline-tab, and grep of SCENARIOS in bench/keys.rb, and drifts as scenarios are added
- Fix: correct the usage text or ask the binary for its scenario names (keys.rb accepts all) instead of repeating them
- Also: bench/keys.rb
- Category: code-quality
- Added: 2026-11-23

### the mktemp report file is made before the missing-binary at bench/run.sh:25 (sprint-30 sweep quality, note 70)

- Location: bench/run.sh:25
- Why: the mktemp report file is made before the missing-binary check and never removed by a trap, so an early exit, a failing run under set -e, and every --budgets parent (which only re-invokes itself) leave a carat-bench-alloc file in TMPDIR
- Fix: trap 'rm -f "$REPORT"' EXIT after the mktemp, or make it inside per_key
- Category: code-quality
- Added: 2026-11-23
