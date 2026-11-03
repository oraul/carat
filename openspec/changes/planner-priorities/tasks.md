# Tasks

## 1. Queue check

- [x] 1.1 `tools/docs_lint.sh`: `check_queue` (gate `queue`) fails a numbered item of `docs/queue.md` without a tier `T0` to `T6` or without `estimated small|medium|large`, naming the line; tested by the `tools/tools_test.sh` cases "docs_lint: passes a queue whose items carry a tier and a size", "docs_lint: refuses a queue item without a tier and names it", and "docs_lint: refuses a queue item without a size".
- [x] 1.2 `docs/queue.md`: take the planner's `build/plan/queue.md`; checked by `make docs-lint`.

## 2. Estimate and budget

- [x] 2.1 `tools/run_state.sh`: `estimate_of` (the size word of the change's item at `merged^`, `merged` checked as a commit hash first), the `estimate` column after `review` in `HEADER` and `history_row`, `out_tokens` shared by the row and `budget`; tested by the cases "history records no estimate without a queue item", "history records the estimate of the queue item", and "every history row has the header's columns".
- [x] 2.2 `tools/run_state.sh budget CHANGE`: `over`, `within`, `unmeasured`, or `no estimate` with the budget and the actual; tested by the cases "budget names an overrun", "budget passes a run within its budget", "budget says when no estimate was made", "budget says when no output tokens were recorded", "budget reads no estimate of an unmerged change", "budget passes git only a commit hash as the merged value", and "budget refuses a change without a run state".
- [x] 2.3 `docs/metrics.tsv`: the `estimate` header and `-` in every row; checked by `awk -F'\t' '{ print NF }'` printing 15 for every line.

## 3. Charter and agents

- [x] 3.1 `docs/goals.md`: the rubric section (tiers, value by size, quick wins, batching, budgets, size check, aging, user features, problem-first briefs).
- [x] 3.2 `.claude/agents/planner.md`: tier and size per item, tier and a number per decision, the size check, problem-first briefs and notes; `.claude/agents/retrospective.md`: `budget` and the `overrun` note, problem-first proposals; `.claude/agents/contributor.md`: `make docs-lint` in the package step. Checked by `make docs-lint` (budgets).

## 4. Docs

- [ ] 4.1 `CLAUDE.md` (Agents, Commands), `README.md` (the planner, the retrospective, `make docs-lint`), `docs/codebase-map.md` (area 1 and the delivered-changes line), `tools/gates.sh` comment. Checked by `make docs-lint`, `make tools-test`, and `make gates`.
