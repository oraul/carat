chore(pipeline): skip placed planning and current scouts, cap merge work

## Summary

Skips delivery work that changes no decision: the planner on a placed, estimated first item, a scout for an area whose pack is still current or whose locations the brief names, merge calls beyond a fixed cap on a first-pass green CI, and a package step edit of a reviewed file, and stops docs-lint failing a change on its own queue item. Over the last 24 deliveries a change averaged 1,091,490 total and 183,053 output tokens, part of the plan, scout, merge, and package shares spent on such work, and two package steps had their push refused for editing reviewed files. This is part a of pipeline-diet (cuts 1, 2, and 5); part b, queued as pipeline-diet-b, takes the check relay, the quality first pass, fix in place, and the records budget.

---

## Changes

- Change `plan-needed` in `tools/run_state.sh` to ask for the planner when the head item of the lane queue has no estimate and to stop counting a pending change's notes once a later sprint records change merged, so a placed, estimated first item runs with planned=0.
- Change the workflow's scout plan to reuse an area pack whose read files are unchanged at the head, handing its missing locations and every location of an area the brief names to the contributor as an unread list instead of starting a scout.
- Change the merger's call cap to a fixed 10 calls of work plus 2 per CI wait, with the merger agent's text and turn ceiling to match.
- Add `run_state.sh reviewed-edits`, which lists files changed since the passing security review outside the records-only paths and exits 1 on any, run by the contributor's package step and allowed by the agent guard.
- Change `tools/docs_lint.sh` to skip dead backticked paths on the queue item naming the change being checked.
- Add `tools/tools_test.sh` cases for each skip taken when its condition holds and not otherwise, the merger cap, reviewed-edits, and the docs-lint own-item rule.
- Document when the planner and a scout are skipped in the README and the new commands in the code map.
- Record the plan's backlog queue, the metrics history row, and seven non-blocking findings in `docs/findings/pipeline-diet.md`.

---

## Testing

- Run the security review on the committed diff at 0ac441dbb78f, pass with 0 High, 0 Medium, and 1 Low, recorded in the findings file.
- Run the quality review at 0ac441dbb78f, pass with 0 blocking and 6 advisories, all recorded in the findings file.
- Run the checker's stages at 0ac441dbb78f (docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, metrics), all pass, and the benchmark review, pass.
- Run `make spec-validate` after the archive, 54 passed and 0 failed.
- Run `sh tools/run_state.sh reviewed-edits pipeline-diet` after the records commit, no edit since the security review.
- Run `make gates` and `make docs-lint` on the packaged branch, all pass.

---

## Notes

The security review is unchanged and still runs on every change, and `tools/rules.sh` is not edited. The pool lines plan-skip-placed, scout-pack-reuse, merge-cap-ci-wait, package-advisory-edit, and lint-own-queue-paths, folded by sprint-16-records, are delivered here; records-budget-scope stays in the pool for pipeline-diet-b. The archived proposal records this part's 172,726 output tokens before the package step against the 183,053 average; its total is recorded by the history row at the close and read by the retrospective with the next two deliveries.
