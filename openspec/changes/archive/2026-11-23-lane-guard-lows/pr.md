fix(tools): refuse tracked lane paths, pin merge git, and check the picked pull request

## Summary

Hardens four delivery-tool steps that took decisions from branch-controlled files or the machine's own git configuration: lane setup, the merge of main, the run state's keys, and the pull request that `wait` records. Branch code is untrusted, and each of these was a Low security finding from earlier reviews.

---

## Changes

- Change `lane_open` in `tools/run_state.sh` to refuse a branch that tracks a path the lane links (a `build/pipeline` of its own) or commits a `tmp` or `build` link, and an existing lane link that points anywhere but the main checkout.
- Change `merge_main` to run its merge, conflict checkout, add, commit, and abort through `pinned_git`, so no global or system configuration and no hook runs.
- Change `set` to refuse every `note.*` key, which only `note` writes, and the `change`, `branch`, and `repo` keys, which only `init` writes.
- Change `wait` in `tools/open_pr.sh` to record a pull request only when gh reads it back as same-repository with the run state's branch as its head; a fork's or another branch's is refused.
- Add tools-test cases for each guard, each failing before the change, and write the forged notes of the late-finding tests by the file since `set` no longer takes note keys.
- Document the refusals in the headers of `tools/run_state.sh` and `tools/open_pr.sh`.

---

## Testing

- Security review of the committed diff: pass, high 0, medium 0, low 0, blocking 0.
- Run the fast stages through `make check` at the change's head: docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, and metrics all pass.
- Benchmark review: pass, no allocation or round regression against main.

---

## Notes

The brief's other parts (the sprint notes phase, the control characters in the spec validation and gateway path, the package step's prose-only edit, and the budget line) are left to follow-up changes `lane-guard-lows-b` and `lane-guard-lows-c`. The shared writable toolchain finding is closed with a recorded reason in the findings file: one toolchain is the design and only `lane-open` makes the links. `wait` now needs gh installed and authenticated, and refuses instead of recording an unchecked number.
