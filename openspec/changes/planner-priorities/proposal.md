# Proposal

## Why

The planner orders the queue by the priority list of `docs/goals.md` and cites "a metric, finding, or request" per decision, but nothing fixes how a security Low, a pipeline defect, a user request, and a roadmap item compare, how big a change may grow, or whether a run stayed within its size. The queue's items carry a tier and a size only by habit (3 of 12 numbered items in `docs/queue.md` at 15ea48a have no size word), `docs/metrics.tsv` records the actual output tokens of a change but never its estimate, and nobody compares the two. The cost shows in the data: `workflow-trim` bundled seven fixes and needed four quality rounds across two runs, 56,348 of 112,010 output tokens of its last run in quality review; one blocking finding there reversed an approach that brief part 4, a retrospective note, and a plan note had all prescribed (`workflow-trim` retrospective note 2). This is the user's now-request, queue item 1 (tier T2, estimated small), outside the roadmap of `docs/architecture.md` section 12: it changes only the delivery pipeline's charter, agents, and scripts.

## What Changes

- `docs/goals.md` gains the rubric the planner orders by: tiers T0 to T6; value divided by size inside T3 to T6; quick wins jumping within T4 to T6 but never ahead of T0 to T2; same-domain quick wins batched to share the fixed overhead of about 300k output tokens; token budgets small under 300k, medium under 700k, large under 1.2M output tokens; aging after three push-backs; at least one user-requested feature in every three changes; a size check that splits a brief of more than about four separate fixes, or one estimated large outside the roadmap, into balanced changes; and a brief part, plan note, or proposal that states the problem, its numbers, and the acceptance check, not the implementation.
- `.claude/agents/planner.md` applies the rubric: every queue item names its tier and `estimated small|medium|large`, every decision cites its tier and a number, and the size check runs before a change starts.
- `.claude/agents/retrospective.md` runs the new `sh tools/run_state.sh budget CHANGE`, records an `overrun` note when the run's output tokens exceed its estimate's budget, and states each proposal as a problem with its numbers and acceptance check.
- `tools/run_state.sh`: a 15th history column, `estimate`, the size word of the change's queue item in `docs/queue.md` at the parent of its squash commit (`-` when no item states one); the `budget` command prints the estimate, its budget, the actual output tokens, and `over` or `within`.
- `docs/metrics.tsv` gains the `estimate` header and `-` in each existing row, which predates estimates.
- `tools/docs_lint.sh` gains a `queue` check: every numbered item of `docs/queue.md` names a tier `T0` to `T6` and `estimated small`, `medium`, or `large`. `docs/queue.md` takes the planner's new queue (`build/plan/queue.md`), whose items all pass it.
- `tools/tools_test.sh` cases for the check, the column, and the command; `CLAUDE.md`, `README.md`, `.claude/agents/contributor.md` (the package step runs `make docs-lint` on the queue it commits), and the code map follow.

Out of scope: the workflow script (`.claude/workflows/deliver-change.js`) is unchanged, since the estimate is read from git at history time and the retrospective runs the new command itself; the backlog entries on the guard's symlinked body file and the unchecked `merged` value stay for `guard-hardening`; the lost quality advisories of `workflow-trim` stay for `workflow-records`.

Assumptions: the estimate is the size word only (the budgets are fixed in `tools/run_state.sh` and `docs/goals.md`), and the actual is the existing `out_tokens` column; a queue item is a line starting with a number and a period, so the "Under discussion" bullet and the Decisions bullets are not checked.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. This changes the delivery pipeline's charter, agents, and scripts, not the editor's behavior; `skip_specs` is set.

## Impact

- Edited: `docs/goals.md`, `docs/queue.md`, `docs/metrics.tsv`, `.claude/agents/planner.md`, `.claude/agents/retrospective.md`, `.claude/agents/contributor.md`, `tools/run_state.sh`, `tools/docs_lint.sh`, `tools/gates.sh` (a comment), `tools/tools_test.sh`, `CLAUDE.md`, `README.md`, `docs/codebase-map.md`.
- No file the binaries compile changes, so allocations and rounds equal main's.
