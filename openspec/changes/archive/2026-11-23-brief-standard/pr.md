chore(tools): add the brief standard and tools/brief.sh

## Summary

Adds a committed brief standard and `tools/brief.sh`, which builds a delivery brief from a change's queue item and run state and refuses a brief that lacks a field or a failing-before test. Briefs in the queue-entry shape needed 0.36 rework rounds over 129 merged runs against 0.78 to 1.44 for hand-written ones, the worst missing locations, bundled asks, and a prescribed how.

---

## Changes

- Add `docs/brief-standard.md`, which fixes the fields in order (the header, WHERE, WHY, OUTCOME, ACCEPTED WHEN, CONSTRAINTS, OUT OF SCOPE, USER DECISIONS, RULES), one change per brief, and no WHERE no start.
- Add `tools/brief.sh` with `build CHANGE`, which assembles a complete brief from the queue item and the run state, and `check [FILE]`, which refuses a missing or misordered field, a WHERE with no path and line, an ACCEPTED WHEN with no test, an empty field, and a brief of two changes.
- Add `tools/tools_test.sh` cases for the build from a queue item and for each refusal, including an out-of-order field and a missing run state.
- Point the planner's queue item shape at the standard's labels in `.claude/agents/planner.md`.
- Document the standard in `README.md` and the tools area of `docs/codebase-map.md`.
- Record the plan, the metrics history, and the archived change with its brief.

---

## Testing

- Run the security review of the committed diff at the checked head, no findings at any severity.
- Run the benchmark review at the checked head, passed with nothing blocking.
- Run `sh tools/run_state.sh check brief-standard` at the implemented head, all stages pass including tools-test, test-run, diagnose, bench-budget, gates, docs-lint, and metrics.
- Run `make spec-validate` after the archive, 56 items pass.

---

## Notes

None
