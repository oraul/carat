docs(design): add the binding Facet design doc

## Summary

Adds docs/design.md, the one binding description of carat's look, written from the user's decided Facet design of 2026-11-18. Two sources disagreed (the early council notes against the decided design), and briefs quoted the early notes twice, so the decided design now wins in one named place.

---

## Changes

- Add docs/design.md with the Facet rules, R1 to R7, the color roles table with both palettes and contrast targets, the glyph table with its open clashes, the one-accent rule, the empty and loading rule, the element notes, and a Known drift table naming each shipped difference by file and line with the item that closes it.
- Name docs/design.md in CLAUDE.md, docs/architecture.md, README.md, and docs/codebase-map.md, stating that the look is binding for every UI change.
- Add a required-file check for docs/design.md to tools/docs_lint.sh with a passing and a failing case in tools/tools_test.sh.
- Add the user-approved exception line under the Sprint 25 heading of docs/queue-feature.md so this change runs first in the feature lane, outside the three.
- Archive the OpenSpec change with skip_specs, since no behavior changes, and record the plan's notes and the advisories in docs/findings/facet-design-doc.md.

---

## Testing

- Run the security review of the committed diff, no findings at any severity
- Run the quality review, no blocking findings and eleven advisories, all fixed in place
- Run the checker stages docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, and metrics, all exit 0
- Run make spec-validate, 55 passed, 0 failed
- Run make gates and make docs-lint on the packaged branch, both pass

---

## Notes

The docs only change touches no behavior and no file of the backlog lane. The package step's metrics history appended a backlog lane row because the lane lookup answers backlog for this change, so that row was reverted and the lookup recorded in the findings file.
