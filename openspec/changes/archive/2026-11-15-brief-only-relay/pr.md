fix(pipeline): carry only the brief into every contributor start

## Summary

Makes every contributor start of the delivery workflow carry the brief, and only the brief, as its request, and lets docs-lint honor a sprint marked as a user-approved exception to the one-pipeline-item limit. The package start, the one that pushes, never saw the brief, so a hold for the user's reading did not reach it and pull request 137 pushed and merged early, while any extra field passed to the workflow reached the resume start as if it were part of the request.

---

## Changes

- Change the delivery workflow to keep only its known arguments (change, brief, branch, packs, areas, records) and drop any other field before a start's prompt is built
- Change every contributor start, implement, fix, package, wait, push, and body, to carry the brief or the resume brief
- Change the resume brief to name the one queue plan-needed read, build/plan/queue.md while a sprint plan waits there and docs/queue.md otherwise
- Change docs-lint to lift a sprint's limit of one pipeline item when a line under its Sprint heading begins with The user-approved exception, and fix its usage header to say 0 to 5 items
- Add tools_test cases for the argument filter, the brief in every contributor start, the resume brief, and the docs-lint marker
- Document the brief in every contributor start and the sprint exception line in CLAUDE.md, the README, and the codebase map
- Record the archived OpenSpec change, the planner's sprint 8 queue, the groomed backlog, the sprint row, and the previous change's metrics row

---

## Testing

- Run the security review of the committed diff, pass with no high, medium, or low findings
- Run the quality review, pass with no blocking findings and six advisories appended to the backlog
- Run the checker's stages (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, gates), all pass
- Run make spec-validate after the archive, 51 items pass
- Run make gates and make docs-lint before the push, both pass

---

## Notes

The change alters no spec, so it is archived with skip specs. Six quality advisories are left for follow-ups in the backlog, among them naming build/plan/queue.md in the resume brief when the planner runs, a stronger line-start case for the marker, and restoring the CLAUDE.md rule that tasks of one domain may share a change.
