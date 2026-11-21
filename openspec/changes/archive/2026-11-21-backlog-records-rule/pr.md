chore(gates): read the backlog folder's markdown files as records

## Summary

Widens the merge gate's records rule so the Markdown files under docs/backlog/ count as records, beside docs/backlog.md. The coming move of the backlog into per-file entries under docs/backlog/ would otherwise be read as code by the security gate's settled check and the check's test-only rerun, costing the whole check and the reviews on a records-only commit.

---

## Changes

- Change RECORDS_RE in tools/rules.sh to also match docs/backlog/ followed by any path ending in .md, keeping docs/backlog.md until the move removes it, and name the backlog folder in its comment
- Add tools-test cases proving docs/backlog.md, docs/backlog/_general.md, and docs/backlog/carat/adapters/tab_bar.rb.md are records while docs/backlogs.md and docs/backlog/x.txt are not
- Add tools-test cases proving settled_at in tools/gates.sh, TEST_ONLY in tools/run_state.sh, the settled check, and ci_scope read the backlog folder's Markdown files as records and a non-Markdown file there as code
- Add the user-approved exception line for this change under Sprint 25 of the backlog lane queue, with the plan and the metrics history row

---

## Testing

- Run the security review of the committed diff, pass with no finding
- Run the checker's stages (diagnose, docs-lint, dev-build, test-build, test-run, tools-test, gates, bench-budget, metrics), all pass
- Run the quality review of the diff, no bug and no untested behavior change found; the new pattern, gate, check, and settled cases fail with the regex reverted
- Run make spec-validate, 55 passed, 0 failed
- Run make gates and make docs-lint after packaging, both clean

---

## Notes

The two ci_scope cases pass with or without the regex change, since documentation() already read every Markdown file as documentation; they guard the folder against a later narrowing. The backlog move itself is the next backlog-lane change, which removes the docs/backlog.md alternative once the file is gone.
