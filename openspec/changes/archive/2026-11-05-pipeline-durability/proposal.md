# Proposal

## Why

A killed check has cost a round or a stop in 3 of the last 5 runs. In `buffer-global` a check whose `dev-build.log` ends `Terminated` came back as failed at stage `pending`, at the pre-fix commit 8e889f6 while `HEAD` was 76fa78b, and started a contributor fix start that committed nothing (rework round 2 of 3 from it alone, retrospective note 10). In `buffer-substitute` a check killed while a fix landed was reported as failed at stage `none` and spent round 2 of 3 the same way, and `guard-allowlist` stopped on one. The cause: the checker starts `tools/run_state.sh check` as a background job of its own Bash tool and must wait for its completion notice; when its turn ends first, the harness ends its background jobs with SIGTERM, the check leaves no verdict and no record of the stage it was in (`run_stage` writes only after the command returns), and the checker reports what the stale records say. Nothing tells a killed or superseded check from a failed one, and the workflow sends every check that did not pass to a fix round (`deliver-change.js`, `rounds`). Separately, the container restarted during `buffer-search` with six unpushed commits, which a run cannot recover today. This is item 2 of `docs/queue.md`, outside the editor roadmap of `docs/architecture.md` section 12: it changes the delivery workflow only.

## What Changes

- (a) The check outlives its caller: `tools/run_state.sh check` starts the stages in a runner detached from the calling shell (`setsid`), records it in `build/stages/<change>/check.pid`, and waits for it at most `CHECK_WAIT` seconds (540, under the Bash tool's ten-minute limit), printing the runner's log when it ends and exiting 3 while it still runs. A second `check` at the same `HEAD` rejoins the running one instead of starting another; one at a newer `HEAD` stops it (its verdict reads superseded) and starts afresh. The checker runs the check in the foreground and repeats the same command on exit 3.
- (b) A killed stage is reported with its log: a stage's record reads `running` while it runs; a stage ended by a signal (its own exit 129, 130, 137, or 143, or the runner's trap) is recorded as `killed` and its log ends `KILLED: ...`; a stage during which `HEAD` moved is recorded as `superseded`; a runner gone without a verdict has its running stage marked `killed` by the next `check`. Every check ends with one verdict line: `check: every stage passed at C`, `check: stage S failed|killed|superseded at C; read LOG`, `check: still running at C ...`, or a refusal; `S` is `none` when no stage ran. Records are written at the commit the stage started on, not the one after it.
- (c) The workflow routes by that line, which the checker returns verbatim as `verdict`: a pass or a failure at the branch head goes on as now; a killed, superseded, or still-running check, a missing verdict, or a verdict at another commit reruns the checker without a contributor start or a rework round, noted with the stage and its log, at most twice in a row before the run stops with that reason.
- (d) Backup ref: `tools/run_state.sh backup CHANGE` pushes the unpushed commits of the change's branch to `refs/backup/<branch>` on origin, after the trailer and content gates (`tools/gates.sh backup`); that ref is no branch, so no pull request or CI run starts from it. `push` deletes it once the branch is pushed. `tools/run_state.sh restore BRANCH` creates a branch missing here and on origin from its backup, which the workflow's resume step runs. The guard allows the contributor `backup CHANGE` only; the contributor runs it after each commit until the branch is pushed.
- The plan's bookkeeping in `docs/backlog.md`: the scratch-file entry is queued in `merge-gate-integrity`, the entry of `build/plan/backlog.md` is added, the six `buffer-global` advisories are queued in `global-tidy`, and the global's ex commands entry points to item 27.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the change touches the delivery workflow, its agents, and its scripts, and no editor behavior, so it sets `skip_specs: true`.

## Impact

- `tools/run_state.sh` (`check`, `run_stage`, `push`, new `backup` and `restore`), `tools/gates.sh` (the `backup` group), `tools/agent_guard.sh` (the contributor's `backup` form), `tools/tools_test.sh`.
- `.claude/workflows/deliver-change.js` (the check verdict and the resume's restore), `.claude/agents/checker.md`, `.claude/agents/contributor.md`.
- `CLAUDE.md`, `README.md`, `docs/codebase-map.md` area 1, `docs/backlog.md`; `docs/queue.md` and `docs/metrics.tsv` at the package step.

## Out of scope

- The push gate refusing an untracked file outside the ignored paths, which the planner folded into `merge-gate-integrity`.
- Two workflow runs at once in one clone: they share `build/dev`, `build/test`, and the compile cache, and no evidence names it as a cause; one run per clone stays the rule.
- Restoring the run state after a reclaim: the backup keeps the commits, and a resumed run rebuilds its records by running the phases again.

## Assumptions

- The cause is inferred from the evidence the runs left (a `Terminated` stage log, a verdict at the pre-fix commit, a fix start with no commit); the logs of those checks were overwritten by later ones. The design removes each way a check can end without a verdict rather than one guessed cause.
- The acceptance's `tools/tools_test.sh` cases cover the scripts: a killed, a superseded, a rejoined, and a hard-killed check, their records and verdict lines, the backup, the restore, and the guard form. The workflow script has no test harness (no JavaScript runtime in the stack), so its routing is checked by a contract case that the verdict words the script prints are the ones the workflow reruns, and by a simulation with stub agents run once by hand.
- The plan notes queue six `buffer-global` advisories in `global-tidy` and fold the seventh, 'GlobalArgs restates the delimiter rules DelimitedPattern owns', into that item's two-documents part; it is marked queued in `global-tidy` too.
- A stage killed by a signal is rerun, not fixed; a stage that a real defect makes the system kill (out of memory) therefore stops the run after three starts with the stage and its log named, which the user reads, instead of reaching the contributor.
