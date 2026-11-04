# Design

## Context

The delivery workflow measures each phase with `budget.spent()`, the runtime's output-token counter (`measured`, `.claude/workflows/deliver-change.js:156`), and `tools/run_state.sh` sums those figures into `out_tokens` for the history and `budget`. Input tokens and wall time are reported only to the main session, in the Workflow tool's result. The rework counter is seeded from `metric.rework` but `rounds()` allows `ROUNDS` fix rounds per start, and the counter is stored only when a record is flushed. The periodic review is due on any path of `REVIEW_AREAS`, whose last line matches every file under `tools/`, `.claude/`, and `.github/workflows/`. The planner runs whenever the plan phase is not recorded.

## Goals / Non-Goals

Goals: record total tokens and wall minutes per run and budget on them; hold the three-round limit across starts; run the periodic review and the planner only when they can change a decision. Non-goals: the cost cuts of part B (parallel reviews, skipped stages, merged agents), which need these measures first.

## Decisions

### Totals come from the main session

The script cannot read input tokens or the clock, so `/deliver`'s command file runs `sh tools/run_state.sh usage CHANGE TOKENS MINUTES` after each Workflow start with the total tokens and the duration the tool reported (the duration from `date -u +%s` before and after when the result names none). `usage` adds them to `metric.total_tokens` and `metric.wall_min`, so two starts sum, and prints the budget line. An alternative, a figure the retrospective estimates from output tokens, was rejected: the ratio of total to output tokens ranged from about 3 to 7 in the brief's numbers.

The history keeps its 15 columns in place, since `rates` reads columns 5 and 6 and `review_due` column 14, and appends `total_tokens` and `wall_min` as columns 16 and 17; the committed rows get `-` in both. `budget` compares `metric.total_tokens` with `TOKEN_BUDGETS` (small 500,000, medium 1,200,000, large 2,500,000) and `metric.wall_min` with `MINUTE_BUDGETS` (small 25); either over is `over:`, no total is `unmeasured:`, and every line names the output tokens too.

The retrospective runs inside the workflow, before its own start's totals exist, so it checks the change of the history's last row (appended by this run's package step, its totals recorded after its run returned) and records an `overrun` note naming it.

### Rework counted from the run state

`rework` is seeded from `metric.rework` as before; what changes is the limit and its storage. `mayFix()` allows a fix while `rework < ROUNDS + extra`, for the review rounds and the CI fixes alike. The checker's prompt starts with the metric line, so the count of a fix round is stored before its check runs, without an extra agent. The metric line also stores `stop=rounds` when a start stopped at the limit and `stop=none` otherwise; a killed start leaves the last line it ran, `none`. On a resume whose seeded rework is above 0 and whose `metric.stop` is not `rounds`, the first time the limit is reached `mayFix()` grants one extra round, stores `extra=N`, and queues an `extra-round` note with the reason built from fixed words and the stored stop word.

### Review areas

The last `REVIEW_AREAS` line becomes `guard and gates`: `tools/agent_guard.sh`, `tools/gates.sh`, `tools/rules.sh`, `tools/ci_scope.sh`, `tools/noruby/`, `.claude/settings.json`, and `.github/workflows/`. An agent file under `.claude/agents/` counts only when its diff adds or removes a `tools:` line or a hook line (`hooks:`, `PreToolUse:`, `matcher:`, `type:`, `command:`), the wiring of the guard (`agent_hooks`, beside `keymap_only`). The count of five still includes every merged change.

### When the planner runs

`plan-needed CHANGE` prints `needed: REASON` (exit 0) when the change is not the first item of `docs/queue.md`, or when a merged run state without a history row, other than the change, holds a `retro`, `overrun`, `security`, or `quality` note; otherwise `not needed: ...` with the head item's size (exit 1). The resume agent runs it and returns the line. The workflow also runs the planner for a brief that is more than the change name, a user request. When it skips the planner it stores the estimate from the line, `planned=0`, and the plan phase; the package prompt then tells the contributor to remove the item from `docs/queue.md` and leave `build/plan/`, which holds an older run's files.

## Risks / Trade-offs

- A start whose Workflow result never reaches the main session leaves its totals unrecorded; the row shows the starts that were recorded.
- Tooling changes outside the guard and gates now wait for the count of five; the merge's own security review of the diff still runs on every change.
- Skipping the planner leaves `docs/queue.md`'s Decisions section as the last plan wrote it.
