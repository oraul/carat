# Proposal

## Why

The design council's decision 4 of 2026-11-21 asks for a float, finder, and palette speed gate before `window-surfaces`. `make bench-budget` fails only on the cursor scenario `lh` (under 100 objects a key, where the figure is 25.0) and prints `grep` without a maximum, so nothing fails when a key typed into the float, the finder, or the command palette starts allocating more. The default scenario list of `bench/run.sh` runs `finder` but not `lh-float` or `palette`, so `make bench` does not show them either.

## What Changes

- Add `lh-float` and `palette` to the default scenario list of `bench/run.sh`, so `make bench` without `SCENARIOS` runs the float, finder, and palette scenarios.
- Add `bench/run.sh --budgets "NAME:MAX ..."`, which checks each named scenario against its own maximum with the existing `--budget` check, runs every one, and fails when any exceeds its maximum, naming each.
- Add the make variable `PICKER_BUDGETS` (default `lh-float:40 finder:600 palette:450`) and run it from `make bench-budget` at 20 and 120 keys. The figures at this commit are 25.0, 376.0, and 280.5 objects a key, so each maximum is above the figure by about 60 percent and under its double: a doubled figure fails.
- Document the gate in README.md, `docs/architecture.md`, `docs/codebase-map.md`, and the comments of the Makefile and the CI step.
- Add `tools/tools_test.sh` cases that run `bench/run.sh` over a fake benchmark program: a figure passes, a doubled figure fails, one failing scenario fails the list and names itself, and the default list holds the float, finder, and palette scenarios.

Out of scope, recorded in the findings file: `lh-winbar` and `n` stay out of the default list (the brief names float and palette; the planner's note keeps them on record), the `lh` maximum of 100 is four times its figure of 25.0 and is not changed, and `grep` stays printed without a maximum.

Assumptions: allocations per key do not depend on the key counts of the runs (checked: the three scenarios give the same figure at 20 and 120 keys as at 200 and 1200), so the pickers run at 20 and 120 keys like `grep`, since the finder's setup over 10,000 files dominates its run; "doubled" is judged on the allocations per key, the only figure the budget compares, as the existing budget does, since time differs by machine.

## Capabilities

### New Capabilities

### Modified Capabilities

## Impact

- Code: `bench/run.sh`, `Makefile` (`bench-budget`, `PICKER_BUDGETS`).
- Tests: `tools/tools_test.sh`.
- Docs: README.md (`make bench-budget` row), `docs/architecture.md` (section 11's bench paragraph), `docs/codebase-map.md` (the bench lines of the float and picker areas, the Flow line, and the `bench/run.sh` entry), the comment of the CI step.
- tools/rules.sh: unchanged. Its `TOOLS_RE` does not match `bench/run.sh`, which `tools/tools_test.sh` now reads, so a change to that file alone does not run `tools-test`; the test finds the file without the `$here/../` spelling the coverage test scans, and the gap is recorded in the findings file for the planner, since an edit of the merge gate's rules goes first, alone.
- No spec changes: the benchmark and its budget are tooling, so the change sets `skip_specs: true`.
- CLAUDE.md: unchanged, no target is added or renamed and its Performance line already names `make bench` and `bench-budget`; the `PICKER_BUDGETS` variable is a default of an existing target.
