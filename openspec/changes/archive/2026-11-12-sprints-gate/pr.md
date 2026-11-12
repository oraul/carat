fix(gates): count the sprint row as a planning record

## Summary

Lets the security, stages, and passed gates keep a review or check recorded before a package commit that only appends the sprint row to docs/sprints.tsv. The package step's groom writes that row, and the gates counted it as a code change after the reviews, so they refused the push and the merge of any delivery that applied a sprint plan.

---

## Changes

- Change settled_at in tools/gates.sh to treat docs/sprints.tsv as a records-only path beside docs/metrics.tsv, while a code change after the reviewed commit is still refused
- Document docs/sprints.tsv with the other records in the header comments of the security gate and of settled_at
- Add tools_test.sh cases: the security gate passes after a commit that changes only docs/sprints.tsv and refuses one that changes it together with a code file
- Record the archived OpenSpec change, the applied sprint-1 plan and queue, the ci-time metrics row, and the review findings in docs/backlog.md

---

## Testing

- Run the security review of the committed diff, pass with no High or Medium findings and one Low finding at confidence 3 (any edit to docs/sprints.tsv is exempt, not only an appended row), recorded in docs/backlog.md
- Run the quality review, pass with one advisory finding (the records-only path list is kept in three places), recorded in docs/backlog.md
- Run the checker's stages (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, gates), all pass
- Run the benchmark comparison, pass with no allocation or round change
- Run make spec-validate, make gates, and make docs-lint, all pass

---

## Notes

TEST_ONLY in tools/run_state.sh and documentation() in tools/ci_scope.sh still leave docs/sprints.tsv out; they refuse nothing a groom write needs, and the follow-up to name the list once is in the backlog. This package commit itself writes the sprint-1 row, so it exercises the fix.
