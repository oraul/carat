# Proposal

## Why

Most extra contributor starts since #274 came from lane cross-talk, not from the changes. The two lane queues share one byte budget (`QUEUE_BUDGET`, 17,969 bytes, `tools/docs_lint.sh`), so one lane's queue growth fails the other lane's docs-lint (backlog-records-rule CI red at 7aee084; backlog-per-file and showtabline check failures), and `plan-apply` adds bytes after the check, so a passing check can still go red in CI. A check that another process disturbed by writing outside its clone while every stage exited 0 ends in `check: stage none failed`, which the workflow reads as a failed stage and answers with a contributor fix round that changes no code (groom-stale-prune, picker-styles-b twice, lsp-tidy, pr-trust-lows), and the passing stage records that check wrote stay reusable. The user decided on 2026-11-21 to apply the self-check council's ideas; this is the backlog lane's first item, outside Sprint 25's 3. It folds the backlog's `check-lane-scratch` and `queue-fit` items.

## What Changes

- Each lane queue gets its own budget, `QUEUE_BUDGET_FEATURE` 6,976 and `QUEUE_BUDGET_BACKLOG` 10,993 bytes, which sum to the old 17,969: the queues' sizes at fa889a3 (feature 6,884, backlog 10,901 with this change's plan applied) with the 184 bytes of headroom split evenly. `docs_lint.sh` learns the lane being checked (`DOCS_LINT_LANE`, else the lane whose queue names the checked change, else the branch's type, as `run_state.sh lane_of` reads it) and checks only that lane's queue: its tiers, sizes, sprint share, pipeline limit, and bytes against its own budget. On main, a detached head (CI), and a sprint's records change, it checks both lanes, each against its own budget, and the pipeline limit across both.
- `plan-apply` fits the lane's queue within its budget as it copies it: when over, it drops the queue's `## Decisions` bullets from the last up until it fits, naming each count, and refuses with the overage, the queue left as it was, when dropping every one is not enough. `push` refuses a lane queue at HEAD over its budget, so CI never meets an over-budget queue the check did not see.
- The check's and bench's metrics stay in the change's lane: run from the main checkout while `tmp/.lane-<change>` exists, `run_state.sh` writes `build/metrics/current.tsv` and `last.tsv` under the lane, never the main checkout's shared `build/`, and `bench` passes that file to `make metrics-compare`. The benchmark agent runs its `make` targets in the lane. The check's own scratch already lives in `build/stages/<change>/` and its clone under `TMPDIR`.
- A check whose stages all exited 0 but which found files outside its clone changed ends in `check: stage none escaped at HEAD; read LOG`, rewrites every stage record it wrote as `escaped` and clears their compile records, so no later check reuses them. `deliver-change.js` reads `escaped` as a check that did not finish: a rerun counted by `RERUNS`, with no checker log start and no contributor fix round.
- The README's budget, planner, checker, and benchmark sentences, the planner's budget line, the checker's verdict list, the benchmark agent's steps, and the code map's entries for `docs_lint.sh`, `run_state.sh`, and `deliver-change.js` follow.
- The Sprint 25 exception line and the removal of the folded backlog names come in through this change's plan, which the package step's `plan-apply` copies over `docs/queue-backlog.md`; the change adds no second, differently spelled exception line.

Out of scope: `tools/rules.sh` (untouched), the feature lane's queue and history (read only for the budget split), the backlog's `plan-apply-stale` (plan notes: not folded), and the CHECK_JOBS refusal, which stays a refusal the contributor fixes.

Assumptions:

- "Trimming as the planner's trims do" drops whole Decisions bullets, last first, never an item; the planner keeps writing within budget, so the trim is a safety net.
- A lane of a feature branch is the feature lane and of any other type the backlog lane, as `lane_of` falls back; a check clone checks out the branch's name, CI a detached head.

## Capabilities

### New Capabilities

None: the change alters the delivery tooling, not editor behavior (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

- `tools/docs_lint.sh`, `tools/run_state.sh`, `.claude/workflows/deliver-change.js`, `tools/tools_test.sh`, `.claude/agents/planner.md`, `.claude/agents/benchmark.md`, `.claude/agents/checker.md`.
- README.md: the docs-lint budget sentence names the per-lane budgets.
- CLAUDE.md: unchanged, it names neither the queue budget nor the check's metrics or verdicts, and the paths it names (`build/pipeline/<change>.json`, `build/stages/<change>/`) stay true; it stands at its 30,720-byte budget.
- docs/codebase-map.md: the entries of `tools/docs_lint.sh`, `tools/run_state.sh`, and `.claude/workflows/deliver-change.js` name the new functions; no file is added, moved, or removed.
- docs/architecture.md: unchanged, section 10 names neither the queue budget nor the check's `build/` paths; no layer, port, or roadmap item changes.
