fix(pipeline): close the review pipeline's security lows

## Summary

Closes the review pipeline's security Lows and advisories of backlog sprint 11 item 1: a stale red CI check is now cleared only by a green run of the same check of the same workflow file, the periodic review keeps each kind's own missed areas, and the continued security prompt leaves the last file alone on its line. A workflow a branch adds could post a green job named like a required check and hide a red run, and the other three read records or prompts wrong.

---

## Changes

- Change staleRed in the delivery workflow to read each check run as workflow, name, status, conclusion and key the last run by workflow file and name, so a green run of another workflow file, a branch-added one included, never supersedes a red one, and an entry without a workflow file keeps the red
- Change the merger to return its checks in that form, reading the head's workflow runs once when a check failed
- Fix missedOf in the periodic review to keep only security area names for the security result and only the integers 1 to MAP_AREAS for the quality result
- Fix the continued security prompt so its closing sentence starts on its own line instead of joining the last file of the list
- Fix the security reviewer's periodic step 5 to state the workflow's order: one more start, then not-run only when that start returns nothing
- Add tools-test cases for another workflow's green run not clearing a red, missedOf refusing the other kind, the last path alone on its line, and the sprint review covering the whole combined diff, the record keepers included
- Document the per-workflow-file rule in the README's run state paragraph
- Record the backlog lane's plan and metrics history row, and one late finding on the merger's check matching

---

## Testing

- Run the security review of the committed diff, pass with no findings
- Run the quality review, pass with no blocking finding and four advisories
- Run the checker's stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, and gates, all pass
- Run the benchmark review against main's recorded figures, pass
- Run make spec-validate after the archive, 53 passed and 0 failed
- Run make gates and make docs-lint before the push, both pass

---

## Notes

The first backlog finding no longer holds on main: the guard and gates review area was removed with the sprint-end review, and every change is now covered by its own security review of the whole committed diff and by the sprint review of the combined diff with no path filter, which a new tools-test case pins. Of the quality advisories, the proposal's diff wording is fixed before the archive, the merger's missing check-suite matching is recorded as a finding, and the repeated missedOf calls and the stale-check comment wording are dropped as style-only. No delta specs, so the change is archived with skip-specs.
