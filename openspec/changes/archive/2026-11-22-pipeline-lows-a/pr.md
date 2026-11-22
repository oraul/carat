fix(pipeline): close five security lows of the checks and the notes

## Summary

Closes five security Lows of the delivery pipeline: a check's runner over a dirty tree no longer writes stage records, `diagnose` is skipped only at the recorded check, the skeptic's notes are recorded with every word shell-quoted, and the held-finding and unpushed-finding notes are refused outside the workflow's close and outside their window. Before this, an uncommitted edit restored after a contributor's check could forge passes the checker skipped, a finding holding `$(...)` expanded when recorded, and any note writer could plant a note that a resume relabeled as a late finding or handed over as a finding.

---

## Changes

- Change `tools/run_state.sh check-run` to refuse, at its own start, a tracked file differing from HEAD, so a runner over a dirty tree writes no stage record and backs no head.
- Change `tools/run_state.sh check` to skip `diagnose` only on a record backed by the recorded `phase.check`, never on a contributor's claimed head or a compiled line, so the checker reruns it whenever a contributor's runner could have written its pass.
- Change the sprint skeptic to return its kept, missed, and disputed notes instead of recording them, the workflow building each note command with `shellWord` and running them in one start of the quality reviewer's new record mode, whose hook runs the agent guard.
- Change `tools/agent_guard.sh` so the read profile's `note` refuses the kinds `late-finding`, `held-finding`, and `unpushed-finding`, which only the close profile writes.
- Change `tools/run_state.sh note` to refuse a `held-finding` before the push or after the merge and an `unpushed-finding` once a push is recorded.
- Fix the check waiter reading a non-verdict `check: ` line, such as the escape scan heading, as the runner's verdict, so it no longer returns before the verdict and a check log always ends on it.
- Add `tools/tools_test.sh` cases for each fix, each failing before it: a dirty-tree runner's pass backing no head, a finding holding `$(...)` recorded literally, the refused note kinds, and a check log ending on the escape heading holding no verdict.
- Document the diagnose rerun, the skeptic's notes, and the note kinds in the README, the checker, quality reviewer, and security reviewer agent files, the contributor notes, and the code map.
- Record the plan's queue, the metrics history row, and the findings left open in `docs/findings/pipeline-lows-a.md`.

---

## Testing

- Run the security review of the committed diff at 95e5d1d07425, pass with no High or Medium finding and one Low, the sprint's security notes runner that predates this change, recorded in the findings file.
- Run the checker's stages at 95e5d1d07425 (docs-lint, dev-build, test-build, bench-budget, test-run, diagnose, gates, tools-test, metrics), all pass.
- Run the benchmark review at 95e5d1d07425, pass with no blocking finding.
- Run `make spec-validate` after the archive, 56 passed and 0 failed.
- Run `make gates` and `make docs-lint` on the packaged branch, all pass.
- Run `make tools-test` after the CI fix of the check waiter, 2126 of 2126 pass.

---

## Notes

The `open_pr.sh` fork heading no longer held on main, since an earlier change made `open` list only same-repository pull requests, so `tools/open_pr.sh` is unchanged. The sprint quality review's continuation at its cap, the reviewer's missed and twice-investigated findings, and the moved-main merge path are left for `pipeline-lows-b`. The sprint's security notes runner and the quality reviewer's own periodic notes keep the exposure the skeptic had and are recorded in the findings file. `tools/rules.sh` is not edited.
