fix(metrics): give the lane histories the full header and check it

## Summary

Gives both lane metrics histories the full 24-column header, pads their older 22-field rows, and makes the history writer and docs-lint refuse a header or row that does not match. Since the closing loop added two columns, the history writer only wrote the header into a new file, so both histories kept a 22-column header over 24-field rows from feature line 65 and backlog line 126 on, and nothing would catch the next column added.

---

## Changes

- Change the history writer in tools/run_state.sh to refuse, before appending, a non-empty lane history whose first line is not the current header, appending nothing, and to write the header into an absent or empty lane file
- Fix line 1 of docs/metrics-feature.tsv and docs/metrics-backlog.tsv to the current header and pad the 187 older 22-field rows with two trailing dash fields, leaving every other field and row unchanged
- Add a histories check to tools/docs_lint.sh that fails on any row of a docs/metrics-*.tsv file whose field count differs from its header's, naming the file, line, and counts
- Add tools-test cases for a header short of the current one (failing before the fix), a header ending in a carriage return, an empty lane file, and the docs-lint field-count check, and give the sprint, budget, and bench fixtures the real header
- Add the user-approved exception line for this change under Sprint 23 in docs/queue-backlog.md
- Document the header refusal and the field-count check in the README, the code map, the history writer's comment, and the docs-lint usage header
- Record the plan and the backlog lane's metrics history row for the previous delivery

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low findings
- Run the quality review, pass with no blocking finding
- Run the checker's stages (docs-lint, dev-build, test-build, diagnose, test-run, gates, bench-budget, tools-test, metrics), all pass
- Run the benchmark review, pass with no blocking finding
- Run make spec-validate after archiving, 54 passed and 0 failed

---

## Notes

The writer refuses a differing header instead of rewriting it, since a rewrite under the lanes' union merge could leave two headers, and the change that adds a column is the one that knows how to pad older rows. tools/rules.sh is not edited.
