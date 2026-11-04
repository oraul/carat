# Proposal

## Why

A tooling change pays for compiles it does not need, and every run ends with three agent starts where one would do. In `pipeline-speed-b`, whose diff touched only `tools/`, `.claude/`, `docs/`, and `openspec/`, `dev-build`, `test-build`, and `diagnose` took 222 of the 346 stage seconds (34, 83, and 105) to compile and analyse code `main` had already passed. Recording, the retrospective, and the report are three starts (639, 13,530, and 3,144 output tokens in `pipeline-speed-b`), each reading its instructions anew, and the budget line the retrospective read could say `unmeasured` (`pipeline-speed`). Three findings sit in the same functions: `check` records stages on a dirty tracked tree (periodic security Low (4), `tools/run_state.sh:309` at e20c83c), it still writes the `phase.check` that backs its own stages, and `add_note` strips a leading commit with two patterns, so an advisory starting with `add` is noted twice (`tools/run_state.sh:577`). This is item 2 of `docs/queue.md`, outside the editor roadmap of `docs/architecture.md` section 12: it changes the delivery workflow only.

## What Changes

- (a) Compile skip: `tools/run_state.sh check` skips `dev-build`, `test-build`, and `diagnose` when the code they read (every tracked path but `.claude/`, `.github/`, `docs/`, `openspec/`, top-level Markdown, and the `tools/*.sh` scripts other than `tools/analysis_budget.sh`) is the code of their last pass and their outputs are the ones that pass left. The pass is kept in the run state's directory, which only `tools/run_state.sh` writes. CI is unchanged: any path outside the documentation paths still runs `dev-build` and `test-build` there.
- (b) One closing start: the `retrospective` agent runs the run's last records (the queued phase lines and the metric line), and when the change merged also its proposals, the budget line of the history's last row, and `review-due`, then writes the report. The `reporter` agent is removed. The guard gives it a `close` profile: the read profile plus `tools/run_state.sh phase CHANGE NAME COMMIT` for the phases no merge gate reads (plan, implement, package, ci, merge, retro, report), never `review` and never `phase` of check, quality, security, or bench.
- (b) The budget line starts with `under:` instead of `within:`, and names the wall minutes only when they were recorded.
- Folds: `check` refuses a tree whose tracked files differ from `HEAD` or that holds an untracked file under `carat/`, `bin/`, `test/`, or `bench/`; `check` no longer writes `phase.check`, which the workflow records from the checker's result; `add_note` strips the same 7-to-40 digit commit on both sides.
- The plan's bookkeeping: three entries of the user's insights review go into `docs/backlog.md`, the entries this change fixes leave it, and the six advisories of `buffer-substitute` are marked as queued in `substitute-tidy`.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the change touches the delivery workflow, its agents, and its scripts, and no editor behavior, so it sets `skip_specs: true`.

## Impact

- `tools/run_state.sh` (`check`, `note`, `budget`), `tools/agent_guard.sh` (the `close` profile), `tools/tools_test.sh`.
- `.claude/workflows/deliver-change.js` (the closing start), `.claude/agents/retrospective.md`, `.claude/agents/checker.md`; `.claude/agents/reporter.md` removed.
- `CLAUDE.md`, `README.md`, `docs/codebase-map.md`, `docs/backlog.md`, `docs/queue.md` at the package step.

## Out of scope

- The tool-call cap and the early budget note of the user's insights review: the planner placed them in `run-budgets` (item 3 of the plan), past the size rule here.
- A superseded or killed check that starts no contributor round: the planner placed it in `pipeline-durability`, with the killed stage reported at stage none.
- Classifying CI failures, parallel delivery in worktrees, and a replay benchmark: recorded in `docs/backlog.md`, not queued.
- The scout and plan inputs of `agent-inputs`.

## Assumptions

- "Such a diff skips them" is read as: the three stages skip whenever the code they read equals the code of their last recorded pass with its outputs unchanged, which holds for a diff that touches only tooling, docs, and records, and also for a fix round of such a diff. The pass is recorded across changes, since the first check of a tooling change follows another change's build.
- The closing start cannot see this run's total tokens, which only the session that ran the workflow learns afterwards (`/deliver` runs `usage`, which prints this run's own final budget line). It therefore budgets the history's last row, the newest run whose totals are final, as the retrospective did; with `under:` that line starts with `under:` or `over:` for every row since `pipeline-speed`, and the row this change appends for `buffer-substitute` carries `total_tokens` and `wall_min`.
- The hooks run `origin/main`'s guard and the agent files the session loaded, so this run's own closing start may still find the old `read` profile; the workflow then hands the records to one record start, as before, and the next run closes in one start.
- The minute dash of `budget_line` (`docs/backlog.md`, queued in `pipeline-durability`) is fixed here because part (b) rewrites that line; its entry and its fold in the queue item go.
