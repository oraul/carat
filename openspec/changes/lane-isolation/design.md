# Design

## Context

Two deliveries run at once, one per lane, each in its worktree `tmp/.lane-<change>` sharing the main checkout's `build/pipeline`, `build/stages`, `build/plan`, and compile cache. Three things still cross the lanes: the shared queue budget of `docs_lint.sh`, the queue bytes `plan-apply` adds after the check, and the check's escape scan, which fails a check when anything outside its clone changed, the other lane included, with the same verdict as a failed stage.

## Decisions

- Per-lane budgets in `docs_lint.sh`, read by `run_state.sh` from that file (`queue_budget`), one source. Split 6,976 and 10,993: the sizes at fa889a3 (6,884 and 10,901 with this plan) and 92 bytes of headroom each, the sum unchanged at 17,969.
- The lane being checked comes from `DOCS_LINT_LANE` (`feature`, `backlog`, or `all`), else the queue whose item names the checked change (`own_change`), else the branch type: `feature/` the feature lane, another type the backlog lane. A sprint's records change, `main`, and a detached head check all lanes. In lane mode the pipeline limit counts only that lane's sprint section; the cross-lane limit is kept by the full runs on main and in CI and by the records change, the only change rewriting a sprint section. Alternative rejected: passing the lane from `run_state.sh` to the stage, since every stage's environment reaches `tools-test`, whose docs-lint cases would then run in lane mode.
- `plan-apply` fits in a temporary copy (`queue_fit`): it drops `## Decisions` bullets, with their indented continuation lines, from the last up, and writes the queue only when it fits; otherwise it dies with the bytes over, the queue unchanged. `push` checks HEAD's lane queue (`queue_over`) and refuses, so an edit after `plan-apply` cannot reach CI.
- Metrics: `metrics_out` resolves to `tmp/.lane-<change>/build/metrics/current.tsv` when that lane exists and the command runs from the main checkout (inside a lane, `tmp/.lane-<change>` does not exist and the relative `build/metrics` already is the lane's). `bench` passes `METRICS_OUT` to `make metrics-compare`, so make compares the same file.
- The escaped verdict is a new word, `escaped`, in `check: stage none escaped at HEAD; read LOG`, kept out of `failed` so the workflow's `checkerNeeded` and fix round never see it. `RERUN_WORDS` takes it, so the existing rerun path, capped by `RERUNS`, handles it. The runner rewrites each stage record it wrote in this run (`runner_records`) as `escaped SECS HEAD TIME` and clears the compile record of each (`compiled_set`), since `compiled_same` would otherwise skip a compile stage on a pass the escape voided. Records from an earlier clean check, skipped at the head, stand.

## Risks

- A stage that really writes outside its clone now reruns instead of going to a fix round; it repeats on every rerun and the run stops after `RERUNS` with the reason named, which is the outcome before this change minus the empty fix rounds.
- A planner queue over budget loses its last Decisions bullets at `plan-apply`; the planner's own check (`wc -c`) keeps that rare, and items are never dropped.
