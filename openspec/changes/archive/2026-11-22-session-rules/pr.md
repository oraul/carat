chore(process): write the main session's standing rules into the repository

## Summary

Writes the main session's six standing rules into the repository so every session and agent reads the same text instead of a conversation. The user asked for the points to be inside the repository and not in session.

---

## Changes

- Add a Main session section to CLAUDE.md with five bullets covering the six rules, the first bullet holding both never stopping a running delivery and resuming with the run id and the same args, then reporting total and weighted tokens, keeping the contributor on its agent file's tier, following the user's instructions as written, and the after-merge routine.
- Add a Main session section to docs/goals.md with each rule's reason and the resume defects it does not claim to fix.
- Tighten existing prose in CLAUDE.md to pay for the new section, so the file stays under its docs-lint byte budget, which is not raised.
- Apply the waiting sprint 29 plan carried by this delivery: the groomed backlog, both lane queues, the sprint's row, and the lanes' metrics history rows.
- Archive the session-rules change with skip_specs, since it is a process-document change with no spec.

---

## Testing

- Security review of the committed diff, pass with no High, Medium, or Low findings.
- Checker run of the pipeline stages at the reviewed head, passed.
- Run make gates, all checks ok.
- Run make docs-lint, all checks ok.
- Run make spec-validate after the archive, 56 passed and 0 failed.

---

## Notes

No tool, workflow, agent, or tools/rules.sh file is edited. The rules record how the main session behaves, so nothing beyond the gates and docs-lint proves them. The feature lane's queue and metrics files change only through the sprint plan this delivery carries by the user's exception.
