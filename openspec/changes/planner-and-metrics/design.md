# Design

## Context

`docs/queue.md` names this change as the planner, a metrics history, the retrospective, periodic reviews, `/plan`, and `/review`. The scouts found the seams (`tmp/scout/build-and-ci-a8135cc-*`, `tmp/scout/tests-and-benchmarks-a8135cc-*`): `tools/run_state.sh status` already prints the last row of `docs/metrics.tsv`, which nothing writes; `stage.*` and `review.*` keep only the last result, so first passes and rework are lost; the CI minutes the CI watcher returns stay in the workflow's memory; no output of `bench/run.sh` or `tools/analysis_budget.sh` is machine-readable; CI checks only `ALLOC_BUDGET` for `lh`; and the comparison with `main` exists only in the benchmark agent's prose, which expects a text `bench/run.sh` does not print. The delivery workflow's script cannot touch files, so every record goes through an agent that runs `tools/run_state.sh`.

## Goals / Non-Goals

Goals:

- One record per merged change, in the repository, written by one script, that the planner and the retrospective cite.
- A machine-readable measurement shared by the checker, the benchmark agent, and CI, with one comparison rule: more allocations or analysis rounds fail, slower time warns.
- Planning and review steps fixed in the workflow, so none depends on memory: Plan before a change, Retrospective and the periodic review after its merge.
- No new rule that only an agent enforces when a script can.

Non-Goals:

- Acting on what the retrospective or a periodic review finds; each finding becomes a queue item.
- Exact per-agent token counts, which the workflow runtime does not expose.

## Decisions

### The next change carries the records

A run learns its CI minutes, its retrospective, and any periodic review only after its own merge, and `main` accepts only pull requests. So every record waits in the run state (`build/pipeline/<change>.json`) until the next delivery: its Plan phase reads the pending run states, and its package step runs `sh tools/run_state.sh history`, which appends one row to `docs/metrics.tsv` for every merged run state without one, and applies the planner's queue. These are records of the pipeline, carried like the archived OpenSpec change, not a second logical change. The settled rule of `tools/gates.sh` (what may change after the reviewed commit) adds `docs/queue.md`, `docs/goals.md`, and `docs/metrics.tsv` to `openspec/` and `docs/backlog.md`, since no check reads them; `tools/ci_scope.sh` treats `docs/metrics.tsv` as documentation. A fresh workspace loses pending run states; the report and the pull request still hold the figures, and the risk is recorded below.

### The history file

`docs/metrics.tsv`, tab-separated, one header line, one row per merged change (or `/review` run), columns:

`change date merged pr rework first_pass ci_min rounds allocs us_per_key out_tokens tool_calls phases review`

Grouped values are `name=value` lists joined by commas (`rounds` is `carat=2,runner=2`; `allocs` and `us_per_key` name the scenarios; `phases` is `implement=TOKENS/CALLS,...`; `first_pass` is `check:1,quality:0,...,gates:1`), an absent value is `-`, and a field never holds a tab. `history` builds a row from the run state keys `metric.*`, `merged`, `pr`, `gates_failed`, and `review.periodic-*`, and the merge commit's date from git. `status` prints the last row and the first-pass rate of each gate over the file, so the planner cites `quality 3/5` without arithmetic.

### Run state commands

- `metric CHANGE NAME=VALUE...` writes `metric.NAME`. Names are `[a-z0-9_.-]`, values are `[A-Za-z0-9_.,:/=+-]`, so a value the workflow passes is safe on a shell line and in a TSV field.
- `metrics CHANGE FILE` imports a measurement file (`name<TAB>value` lines) as `metric.*`.
- `note CHANGE KIND TEXT` appends `note.N` = `KIND TEXT`: retrospective proposals and periodic review findings.
- `pending` prints the merged run states without a history row; `history` appends their rows.
- `review-due CHANGE` prints `due: REASON` and exits 0, or `not due: ...` and exits 1. Due when one of the change's merged paths matches a sensitive area (config loading, file access, plugin boundaries, terminal output, process spawning, as path patterns in the script), or when five changes have merged since the last row with a periodic review (rows after it plus pending run states without one).
- `push` counts a pre-push gate failure in `gates_failed`.
- `PHASES` gains `plan` first and `retro` after `merge`.

### One measurement, one comparison

`tools/metrics.sh measure OUT [SCENARIO...]` writes `name<TAB>value` lines: `rounds.carat`, `analysis_ms.carat` (from `build/dev/carat.timing`), `rounds.runner`, `analysis_ms.runner` (from `build/test/run_all.timing`), and `allocs.S` and `us.S` per scenario from `bench/run.sh` on `build/bench/keys-budget`. The default scenarios are `lh j insert ddp undo dot-ciw lh-ruby open-ruby`, about eleven seconds on four cores, which cover cursor motion, scrolling, insert, delete and put, undo, repeat, the Ruby tokenizer, and file open. `tools/analysis_budget.sh --fields REPORT` prints the milliseconds and rounds, so the report format is read in one place. `compare BASE CURRENT` prints each name with both values and fails when an `allocs.*` or `rounds.*` value grew, warns when a `us.*` or `analysis_ms.*` value grew by more than `TIME_TOLERANCE` percent (default 20; time depends on the machine and the run), as a `::warning::` line on GitHub Actions; a missing base file is a notice and passes.

`make metrics` is a stage after `bench-budget` in `CHECK_STAGES`, writing `build/metrics/current.tsv` from the builds the earlier stages made, so the checker, CI, and the benchmark agent measure the same way; `make metrics-compare` compares it with `BASE_METRICS`.

### CI compares with main through the Actions cache

Allocations and rounds are the same on every machine for the same sources, but time is not, so the base must be measured on the same kind of runner. A push to `main` already builds the three development builds; it now runs `make metrics` and saves `build/metrics/main/current.tsv` under the cache key `carat-metrics-main-<sha>`. A pull request restores the base commit's entry, or the newest `carat-metrics-main-` entry, and runs `make metrics-compare BASE_METRICS=build/metrics/main/current.tsv`. A pull request cannot write `main`'s cache scope, so it cannot plant a base. Measuring the base inside each pull request run would cost another analysis of three roots, about a minute on runs held near two.

### Plan phase and the planner

The workflow runs the planner once per change, before the scouts, unless `phase.plan` is recorded. The planner reads `sh tools/run_state.sh pending` and those run states, `status` (the last row and the rates), `docs/metrics.tsv`, `docs/backlog.md`, `docs/goals.md`, `docs/queue.md`, and the brief; it writes `build/plan/queue.md` (the whole next queue, the delivered item removed, retrospective proposals and periodic findings placed by the goals' priority) and `build/plan/backlog.md` (entries to add), never a tracked file; it records `phase plan` and returns its decisions, each with its evidence. When a High or Medium periodic security finding at confidence 8 or above is unresolved and the brief does not fix it, it returns it as `security_first` and the workflow stops and names it: security fixes go to the front. The contributor's package step applies `build/plan/` and runs `history` in one `docs` commit. `/plan` starts the planner directly as a preview; the queue changes only through a delivery.

### Measuring a run

The workflow wraps every agent call: it reads `budget.spent()` before and after (the output tokens of the run so far, since the main session is idle meanwhile), adds the difference to the phase, and adds the `tool_calls` each agent reports in an optional schema field. It keeps the first verdict of check, quality, security, benchmark, and CI, counts every contributor `fix` call as a rework round, and keeps the last CI run's minutes. After the merge it passes these as one `metric` line to the retrospective, built only from numbers and fixed names.

### Retrospective, then the periodic review

After a merge the `retrospective` agent records the metric line, reads the run state and the last rows of the history, records at most three proposals as `note retro`, each with the number behind it and a preference for removing a step, an agent, or an instruction over adding one, runs `review-due`, and records `phase retro`. When a review is due, the workflow runs `.claude/workflows/periodic-review.js` as a child workflow: the security reviewer and the quality reviewer in their periodic mode, in parallel, over the whole tree at `origin/main`; each records `review CHANGE periodic-security|periodic-quality` and every finding as a `note`. A security review that does not run is retried once and then reported, never skipped silently, and the count keeps the review due for the next run. `/review` runs the same child workflow on a run state `review-<date>` whose `merged` is `origin/main`, so its row resets the count of five.

### The benchmark agent

It measures the base in a worktree at `origin/main` with the change's `tools/metrics.sh` after the base's `dev-build`, `test-build`, and `bench-budget`, compares with `tools/metrics.sh compare`, imports the change's measurement with `run_state.sh metrics`, and keeps the release-build time comparison for changes under `carat/`. This removes the text it expected from `bench/run.sh` that the script never printed.

## Risks / Trade-offs

- A pending run state lives in `build/`, which a fresh workspace lacks; its history row is then lost. Committing it before the merge would need a second pull request per change.
- Output tokens are the session's counter, not one agent's; parallel scouts share one phase total, which is how they are reported.
- Tool calls are self-reported and approximate.
- The CI comparison passes when `main`'s cache entry is missing or evicted after seven days without a push; the benchmark agent remains the blocking comparison.
- `make check` gains about fifteen seconds for the metrics stage.
- The count of five is approximate when several merged run states are pending at once, since run states carry no order; the next change appends them and the count is exact again.
