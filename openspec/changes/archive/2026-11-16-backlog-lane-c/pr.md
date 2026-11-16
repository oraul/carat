chore(pipeline): pick the sprint's backlog batches by map area

## Summary

Adds a `backlog-pick` command to the run state tool that chooses the sprint's two backlog items from the backlog and findings files the planner names, one code-map area per batch, security entries first and then the oldest. Backlog items were queued by hand with no rule for which entries they close, so the backlog only grew; this replaces backlog-lane-b, which stopped after three blocked fix rounds, with its blocking finding and advisories fixed.

---

## Changes

- Add `sh tools/run_state.sh backlog-pick FILE...`, which reads the entries of the named files, skips those a queued item names, places each by its Location in the `docs/codebase-map.md` area naming it, reports unplaced entries as unmapped, and prints two batches of 5 to 10 entries of one area, security entries first whatever their age, an area under 5 passed over unless it holds security entries
- Fix the placement so a bare backticked word counts only when the map names it as a file or directory and the tree holds it, so an identifier before the real path no longer picks the wrong area, and a bare directory word is placed by its slash form
- Change the command to require its files: with none it prints its usage and fails, never reading the backlog or the findings files on its own
- Change the planner's sprint mode to fill the backlog items from the pick's batches, run a one-time triage recorded once, and apply the calibration rule after about 5 backlog-lane runs, with sprint-planning naming the pick and the triage and passing the real files explicitly
- Add tools_test cases over fixture backlogs and a fixture map for the ordering, batching, skipping, unmapped reporting, the identifier-before-path placement, the directory word, and the missing-files usage
- Document the pick in the README's sprint planning step and in the code map's entry for the run state tool, and align the groom header column and drop a repeated phrase in the planner
- Record the planner's queue, the metrics history row, and the change's non-blocking findings

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low finding
- Run the quality review, pass with no blocking finding and two advisories recorded as findings
- Run the checker's stages at the last code commit (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, gates), all pass
- Run the benchmark review, pass with no blocking finding
- Run make spec-validate after the archive, 53 passed and 0 failed
- Run make gates and make docs-lint before the push, all pass

---

## Notes

The pick and its cases read fixture files only, and no agent of this delivery ran it over the real backlog. Of the handed advisories, four (an unmatched findings glob, a doubled candidate lookup, unmapped top-level docs entries, and an unpinned bare directory case) are recorded in docs/findings/backlog-lane-c.md; the planner rewording note and the duplicated membership test are style advisories and are dropped. The one-time triage and the calibration figures are left to the next sprint-planning run and later runs. tools/rules.sh is unchanged.
