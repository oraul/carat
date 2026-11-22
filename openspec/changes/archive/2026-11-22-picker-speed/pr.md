chore(bench): gate the float, finder, and palette allocations

## Summary

Gates the allocations per key of the float, finder, and command palette scenarios in `make bench-budget` and runs them by default in `make bench`. Until now only the cursor scenario had a maximum, so nothing failed when a key typed into a float, the finder, or the palette started allocating more, which the design council's decision 4 of 2026-11-21 asks to settle before window-surfaces.

---

## Changes

- Add `lh-float` and `palette` to the default scenario list of `bench/run.sh`, so `make bench` without `SCENARIOS` runs the float, finder, and palette scenarios.
- Add `bench/run.sh --budgets "NAME:MAX ..."`, which checks every named scenario against its own maximum, runs them all, and fails naming each one over its maximum.
- Add the `PICKER_BUDGETS` variable to the Makefile (`lh-float:40 finder:600 palette:450`) and run it from `bench-budget` at 20 and 120 keys, each maximum above the current figure and under its double.
- Add `tools/tools_test.sh` cases over a fake benchmark program: a figure passes, a doubled figure fails, one failing scenario fails the list and names itself, and the default list holds the float, finder, and palette scenarios.
- Document the gate in README.md, `docs/architecture.md`, `docs/codebase-map.md`, the Makefile help line, and the CI step comment.
- Archive the OpenSpec change, record the plan and the metrics history, and queue the next sprint item.

---

## Testing

- Run the security review of the committed diff, no High, Medium, or Low finding and nothing blocking
- Run the benchmark review, passed with nothing blocking
- Run the check stages at the head commit (docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, metrics), all pass
- Run the quality review of the diff, one advisory finding recorded in the findings file
- Run `make spec-validate`, all 56 items pass

---

## Notes

The gate compares allocations per key only, not time, as the existing budget does. `lh-winbar` and `n` stay out of the default list, and the maximum of `lh` and the unbounded `grep` figure are unchanged; these are recorded as findings. An empty `PICKER_BUDGETS` checks nothing and exits 0, also recorded as a finding.
