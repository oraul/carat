chore(workflow): record a late blocking quality finding as a first-pass miss

## Summary

The quality reviewer now reports every blocking finding it can in its first pass, and the workflow records a blocking finding that a later round raises on lines unchanged since the last review as a first-pass miss. Quality failed its first pass on about half the runs because later rounds raised new findings on code the first pass had already read, and only a re-raise at an earlier advisory's location was caught.

---

## Changes

- Change the quality reviewer's agent file so the first pass reads each changed hunk with its enclosing function and reports every blocking finding, and a later review marks a new blocking finding on unchanged lines as a first-pass miss
- Add a qualitySplit helper and a first-pass miss check to the review bookkeeping in the delivery workflow, so only a new marked finding is noted as a first-pass miss and a finding still unfixed from the last review is not
- Change the quality input to list the last review's blocking findings, on the whole-branch path as well as the scoped path
- Add workflow test cases in tools/tools_test.sh for the miss marker, the prior-location filter, and the whole-branch prior list
- Document the first-pass miss rule in the README and archive the OpenSpec change with no spec delta
- Record the non-blocking review findings, the plan, and the metrics history

---

## Testing

- Run the security review on the committed diff, pass with no findings
- Run the quality review at the fixed head, pass with no blocking findings and advisories recorded as findings
- Run the checker stages at the fixed head (diagnose, dev-build, test-build, test-run, tools-test, docs-lint, bench-budget, gates, metrics), all pass
- Run the benchmark review, pass with no blocking findings
- Run make spec-validate after archiving, all items pass

---

## Notes

The acceptance that quality passes first on 7 of the next 10 runs is measured by later runs, not by this change. The contributor returned a placeholder instead of its result on the last fix start; the fix itself passed its checks, and the breach is recorded as a finding for the mid-tier trial. This change edits no file of the feature lane and does not edit tools/rules.sh.
