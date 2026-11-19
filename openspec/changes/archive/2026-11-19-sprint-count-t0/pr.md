fix(run-state): count only a sprint's queue items and their split parts

## Summary

Makes `review-due`, the sprint row, and `groom` count a sprint's changes as its queue's numbered Sprint N items and their split parts only, and name every left-out change by reason. Before, every change merged since the last sprint row counted but one marked beyond the sprint, so T0 items and changes a user-approved exception line puts outside the 3 took sprint slots and a sprint could close before its planned items merged.

---

## Changes

- Fix `sprint_state` in `tools/run_state.sh` to count a sprint item, a split part of a counted change, or a change no queue names, and to leave out every T0 change, every change outside the 3, every change beyond the sprint, and every pool item, removing the cap of one held in `SPRINT_EXCEPTIONS`.
- Add `queue_class`, which classes a merged change by the queue before and at its merged commit as T0, outside the 3, beyond the sprint, sprint item, or pool item.
- Add `queue_records`, the one reader of the queue line form that `queue_class` and `queue_items` share, keeping a sub-heading's sprint.
- Change the not-due line of `review-due` to list the left-out changes by reason (beyond the sprint, outside the 3, T0, not a sprint item), while the due line keeps the fixed form `sprint-planning.js` parses.
- Change `sprint_row` and `groom` to read the left-out list in place of the old exception list, so the sprint row, the grooming check, and `review-due` agree.
- Add tools-test cases for a T0 change left out, a change named outside the 3 left out, a split part and a sibling split part counted, a pool item left out, and the printed reasons.
- Document the counted changes in the README's sprint planning paragraph and in the code map's `tools/run_state.sh` entry.

---

## Testing

- Security review of the committed diff, pass with no high, medium, or low finding
- Quality review, pass with no blocking finding after one round fixed an untested sibling split-part branch
- Benchmark review, pass
- Run the checker's stages (docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, metrics), all pass
- Run `make tools-test`, 1827/1827 passed
- Run `make spec-validate`, 54 passed, 0 failed

---

## Notes

A rename written only in prose, such as `spinel-bump` delivered as `spinel-catchup`, is not parsed, so a delivered name no queue holds is counted as before. The change touches no file of the feature lane and does not edit `tools/rules.sh`.
