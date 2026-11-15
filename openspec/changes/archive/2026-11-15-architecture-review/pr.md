docs(architecture): record the architecture review and correct its drift

## Summary

Records a review of the architecture and the code map against the code at main, and corrects the statements in docs/architecture.md and docs/codebase-map.md that the code contradicts. The architecture described the target system mostly in the present tense, so a reader could not tell what exists, and several of its statements named classes, files, ex commands, a plugin directory, an API version, and a reader size that no longer match the code.

---

## Changes

- Add the review as the Findings section of the archived change's design: holes, redundancy, and reading and maintenance costs, each finding with its location, why it matters, and a fix outline.
- Change docs/architecture.md to mark the pieces not built yet as planned, among them marks, references, rename, formatting, the one-shot tools, the plugin gateway, git_signs, and the plugin protocol document.
- Fix docs/architecture.md where it disagreed with the code: the layer diagram's names, the ex commands registered, the plugin API version, the size of Carat::Json, the Makefile's role, which layers talk to ports, the environment reads, the completion menu, and the roadmap's green condition.
- Fix docs/codebase-map.md: the environment reads of area 17, a method listed twice in area 4, and a stray mark in area 1.
- Add every finding the change leaves open, and the review's five advisory findings, to the end of docs/backlog.md for the planner's sprint mode.
- Change docs/queue.md to the planner's queue and add the previous merged change's row to docs/metrics.tsv.

---

## Testing

- Run the security review of the committed diff, pass with no high, medium, or low findings
- Run the quality review, pass with no blocking finding and five advisories recorded in the backlog
- Run the checker's stages (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, gates), all pass
- Run the benchmark comparison against main's recorded figures, pass
- Run make spec-validate after the archive, 51 passed and 0 failed
- Run make gates and make docs-lint before the push, all pass

---

## Notes

No code, test, configuration, or behavior changes, so the change sets skip_specs and is archived without delta specs. Code fixes the review names, including the dead code, are left to the backlog for the planner to queue.
