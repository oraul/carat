fix(workflow): refuse a contributor head other than the lane's

## Summary

The delivery workflow now reads the lane's head itself after a contributor start returns done and refuses a result whose head is malformed or differs from it, restarting the start once and moving later contributor starts to the session's model. Two runs this week stopped on a literal placeholder head because the workflow took the reported head unchecked, so card rule 1 of the contributor was only an instruction.

---

## Changes

- Add a lane-head read to the contributor phase of the delivery workflow, a record start running only git rev-parse --short=12 HEAD in the change's worktree after each done result
- Refuse a done result whose head is not twelve lowercase hex characters or differs from the lane's head, noting head-refused in the run state and the report, escalating later contributor starts to the session's model, and restarting once with the reason, a second refusal stopping the run
- Queue the refusal's note with only a sanitized excerpt of the reported head, so a result cannot inject shell text into the record line
- Take a well-formed head when the lane's head cannot be read, with a report note and a head-unread note in the run state so a reader that always fails shows
- Share one record-start helper between the record flush and the lane-head read
- Add tools-test cases that run the real contributor phase over a placeholder, a wrong head, a second refusal, an unread lane head, and a hostile head, and assert the lane-head command
- Document the refused head as an escalation trigger in the goals and the README's pipeline paragraph

---

## Testing

- Run the security review on the committed diff, pass with no High, Medium, or Low finding
- Run the quality review, pass with no blocking finding and no open advisory after its three advisories were fixed in place
- Run the checker's stages (diagnose, dev-build, test-build, test-run, gates, docs-lint, bench-budget, tools-test, metrics), all pass
- Run the benchmark comparison, pass with no blocking difference
- Run make spec-validate after archiving the change, 54 passed and 0 failed

---

## Notes

The self-check-mismatch note after the next check and its escalation test are left for the follow-up change delivery-guards-c by the plan's split, so this pull request covers only the refused head. Nothing under carat/ and no merge gate rule changes.
