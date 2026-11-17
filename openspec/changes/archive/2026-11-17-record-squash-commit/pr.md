fix(pipeline): record the merge at the squash commit and keep every close record

## Summary

The close of a delivery now records the merge, retro, and report phases at the squash commit on main, the run state's `merged`, whatever sha the merger reports, and a refused record line no longer drops the lines after it. Sprint-14-records and ruby-structure-remove lost their merge, retro, and report phases and every metric field because the merger reported the pushed branch head and the close joined its record lines with `&&`, so one refusal stopped the rest and the records had to be filled in by hand.

---

## Changes

- Change `tools/run_state.sh phase CHANGE NAME merged [REPORTED]` so the word `merged` records the merge, retro, or report phase at the change's squash commit on main, adding a `merge-disagreement` note naming both values when the reported sha resolves to another commit.
- Change `.claude/workflows/deliver-change.js` to record those phases with `merged`, pass the merger's sha only as the reported value, and tell the close that the merged commit is the run state's squash commit.
- Change the close's record line to run every line whatever an earlier one did, printing each refused line's position, and add a `refused` list to the close's result, `recorded` true only when no line was refused.
- Change the close profile of `tools/agent_guard.sh` to accept the `phase CHANGE NAME merged` forms.
- Document in `.claude/agents/merger.md` and `.claude/agents/retrospective.md` that the merged commit is the squash commit on `origin/main` whose subject ends with the pull request number, never an agent's sha, and that a refused line no longer stops the rest.
- Add `tools/tools_test.sh` cases for a merger reporting the pushed head leading to the squash commit recorded as phase.merge, phase.retro, and phase.report, and for a record line with one refused phase still storing the other phases and every metric field.
- Change `docs/queue-backlog.md` to take the item out of the pool and record it as Sprint 15's one user-approved exception, and record the plan, the metrics history row, and the review findings.

---

## Testing

- Run the security review of the committed diff, pass with high 0, medium 0, low 0, nothing blocking.
- Run the quality review, pass with 0 blocking and 5 advisories, the missing unresolvable-sha case recorded in the findings file and the design wording fixed.
- Run the checker's stages diagnose, docs-lint, dev-build, test-build, test-run, bench-budget, tools-test, gates, and metrics, all pass with allocations unchanged.
- Run make gates, make docs-lint, and make spec-validate after archiving, all pass.

---

## Notes

The change alters only the pipeline's tooling, so it sets skip_specs and was archived without spec updates. It is delivered as Sprint 15's user-approved exception, beyond the sprint, so the sprint count does not include it. The three duplication advisories in `tools/run_state.sh` and `.claude/workflows/deliver-change.js` were dropped as style; the missing case for a mistyped sha is in `docs/findings/record-squash-commit.md`.
