# Tasks

## 1. Queue budget

- [ ] 1.1 `tools/docs_lint.sh`: `docs/queue.md 17369` in `BUDGETS`. Tested by the `tools/tools_test.sh` case "docs_lint: refuses a queue over its budget".
- [ ] 1.2 `docs/queue.md`: the planner's `build/plan/queue.md` (16,921 bytes). Checked by `make docs-lint`.

## 2. Item from the file

- [ ] 2.1 `tools/run_state.sh`: `plan_needed` prints no `item:` line. Tested by "run_state: plan-needed prints one line" (replacing the three item-line cases) and the existing plan-needed cases.
- [ ] 2.2 `.claude/workflows/deliver-change.js`: the brief points to the item in `docs/queue.md`, the scouts get the brief, the resume schema's `plan` is one line. No test runs the workflow script: checked by a syntax check and a simulation of the brief's three cases.

## 3. Agent inputs

- [ ] 3.1 `.claude/agents/planner.md`: backlog by headings, the queue within its budget, one-line decisions.
- [ ] 3.2 `.claude/agents/scout.md` and the scout plan prompt: existing code only, no rules step, about 150 lines.
- [ ] 3.3 `.claude/agents/contributor.md`: covered files at the lines edited, the guides for Ruby code only. Checked by `make docs-lint` (agent budget).

## 4. Docs and bookkeeping

- [ ] 4.1 `docs/codebase-map.md` area 1 and the `tools/run_state.sh` header.
- [ ] 4.2 `docs/backlog.md`: the four entries of `build/plan/backlog.md`, the three stale figures, the queued pointers, the plan-skip entry removed, and an entry for the `CLAUDE.md` every agent receives.
- [ ] 4.3 Run `make tools-test`, `make docs-lint`, `make gates`, and `openspec validate agent-inputs --strict --no-interactive`.
