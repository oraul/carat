fix(tools): check recorded merge heads and the sprint row

## Summary

Makes the run state refuse a CI head that is not the pushed head and a merged commit that is not the pull request's squash commit on main, and makes the sprint-log exemption of the review gates accept only the one row groom appends for the sprint in progress. Several merges recorded swapped or wrong CI and merge heads, and any edit of docs/sprints.tsv after the reviewed commit settled the review gates, so a forged or rewritten row could move the sprint base and let the sprint-end review skip changes.

---

## Changes

- Change tools/run_state.sh so a CI result or CI phase is accepted only at the pushed head the run state records, stored in its 12-digit form, and refused naming both values otherwise or before any push
- Change tools/run_state.sh so a merged commit or merge phase is resolved with git and accepted only when it is on main and is the squash commit whose subject ends with the pull request number
- Add the run_state.sh sprint-row command, printing the row groom appends for the sprint the plan's marker names, computed against the sprints file at a given commit
- Change settled_at in tools/gates.sh to count a docs/sprints.tsv change only when the appended bytes are exactly groom's one row, so an edited, forged, or second row leaves the review or check unsettled
- Change the delivery workflow to record the CI phase at the pushed head, and the merger and retrospective agents to copy heads from git output and stop on a refused record naming both values
- Add tools-test cases refusing a CI head not the pushed head, a merged commit not on main or not the squash commit, an edited sprint row, a forged or second row, and a row for another sprint
- Document the shared settled_at helper once in the codebase map and the merge-record checks in the README
- Record the plan, the metrics history row, and three review findings for follow-up

---

## Testing

- Run the security review of the committed diff at f7208b282704, passed with no High, Medium, or blocking finding; two Low findings are recorded in docs/findings/merge-record-check.md
- Run the quality review and the benchmark review at f7208b282704, both pass with no blocking finding
- Run the checker's stages at f7208b282704 (docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, metrics), all pass
- Run make spec-validate after archiving, 53 passed and 0 failed
- Run make gates and make docs-lint on the packaged branch, both pass

---

## Notes

The change alters pipeline tooling only and is archived with skip_specs. A merge refused because main moved stays in the backlog. Of the review advisories, the unclear sprint-row refusal message, the duplicated run-state forging in tools-test, and the dead HEAD fallback text in squash_commit are dropped as wording and style; the HEAD fallback itself is covered by the recorded security Low. No tools/rules.sh pattern is edited.
