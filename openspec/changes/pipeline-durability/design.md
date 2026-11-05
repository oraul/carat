# Design

## Context

`tools/run_state.sh check_stages` runs `make -s stages` in order through `run_stage`, which runs a stage's command in the foreground, then appends `EXIT n` to its log and writes `stage.NAME` at `head_commit()` read after the command returned. The checker starts `check` as a background job of its Bash tool, its output in `build/stages/<change>/check.out`, and waits for the completion notice. `.claude/workflows/deliver-change.js` (`rounds`) trusts the checker's `passed`, and every check that did not pass becomes a contributor fix round counted by `mayFix`. The scout pack `tmp/scout/build-and-ci-578b0e8-20261105T070712Z.md` holds the line references; they hold at 578b0e8.

## Why checks are killed

- The checker's background job belongs to the checker's tool calls. When the agent's turn ends before the completion notice (an early report, a turn limit), the harness ends its jobs with SIGTERM: `dev-build.log` of `buffer-global` ended `Terminated`. The check then had no verdict, its running stage kept its previous record, and the checker reported the stale records: `failed at stage pending` at the pre-fix commit, or `stage none`.
- `run_stage` stamped a record with the commit read after the command returned, so a stage that finished after a commit landed was recorded at the new commit although it ran on the old tree.
- An agent tool timeout cuts a foreground call at ten minutes, longer than a check without compile skips can take.
- A second check on a newer commit and concurrent builds: the workflow starts one checker at a time, so a second check only arises from a rerun after the first was cut off; concurrent builds need two runs in one clone, which no evidence shows.

## Decisions

### A detached runner and a waiter

`check CHANGE [COMMIT]` is now the waiter. It refuses a dirty tree as before, then looks at `build/stages/<change>/check.pid` ("PID COMMIT"): a live runner (its process exists and is a `run_state.sh check-run`) at `HEAD` is rejoined; one at another commit is sent SIGTERM, which its trap reports as superseded, and the waiter starts afresh once it is gone; a pid file whose runner is gone without a verdict is a hard-killed check, whose running stage the waiter records as killed before it starts afresh. It starts the runner with `setsid -f` (a subshell `&` where `setsid` is missing), its output in `build/stages/<change>/check.log`, so the end of the caller's turn, tool call, or process group cannot reach it. It then polls every fifth of a second for at most `CHECK_WAIT` seconds (540): on the runner's verdict it prints the log and exits 0 for a pass, 1 otherwise; on a runner gone without one it writes the killed verdict itself; at the limit it prints `check: still running at C (pid P); run the same command again to wait` and exits 3. The checker runs it in the foreground and repeats it on exit 3, so neither its own end nor a tool timeout kills the stages.

`check-run` is the runner, an internal verb the guard admits to no agent. It writes the pid file, traps TERM, INT, and HUP, and removes the pid file on exit when it still names it.

Rejected: a lock directory around the start, which two waiters at once would need. One workflow runs one checker at a time; the pid file covers the sequential rerun, the only second check observed.

### Killed and superseded records

`run_stage` reads the commit before the command runs, writes `running 0s C TIME` first, runs the command in the background and `wait`s for it, so a trapped signal interrupts the wait at once. Its record's first word is the exit status as before, `killed` for 129, 130, 137, or 143 (a hang-up, interrupt, kill, or terminate signal), or `superseded` when `HEAD` moved while it ran; the log ends `EXIT n`, `KILLED: ...`, or `SUPERSEDED: ...`. The runner's trap stops the stage's command (its process group too when the runner leads one), records the stage, and prints the verdict. The stages gate and the skips read only `0 ...` as a pass, so every new word is a non-pass to them unchanged.

The verdict lines are fixed: `check: every stage passed at C; ...`, `check: stage S failed|killed|superseded at C; read LOG`, `check: still running at C ...`, and the refusals `check: refused: ...`. `S` is `none` and the log `check.log` when the runner was stopped before its first stage.

### The workflow reruns what did not finish

`CHECK` gains `verdict`, the last line `check` printed, verbatim. `checkVerdict` parses it. A pass or a failure at the workflow's head, or a refusal, is handled as before (a refusal is a failure the contributor fixes, as a dirty tree was). Anything else, a killed, superseded, or running verdict, a missing or unknown line, or a pass or failure at another commit, reruns the checker in the same round: no `rework`, no `mayFix`, no first-pass verdict, a note naming the stage, its log, and the rerun count. Three starts in a row without a verdict at the head stop the run with that reason, so a stage the system kills on every run reaches the user rather than looping.

### The backup ref

`backup CHANGE` checks that `HEAD` is the change's branch, not `main`, and not pushed yet (`pushes` 0; after the push it says so and exits 0), runs `gates.sh backup` (the trailer and content gates, which a public ref needs as a branch does), and pushes `HEAD:refs/backup/<branch>` without force: the branch's history only grows, a merge of `origin/main` included. The ref lies outside `refs/heads`, so GitHub opens no pull request for it and the CI workflow, which runs on pull requests and on pushes to `main`, does not start. `push` deletes the ref after the branch push succeeds. `restore BRANCH` creates `BRANCH` from `refs/backup/BRANCH` only when the branch exists neither here nor on origin; the resume step runs it before it would create the branch from `origin/main`. The run state, under the ignored `build/`, is not backed up: a resumed run runs its phases again from the restored commits and the change's `tasks.md`.

The guard admits `tools/run_state.sh backup CHANGE` to the contributor and nothing else of it; `restore` runs in the resume start, which has no agent profile.

## Risks

- A runner left alive by a waiter that is never called again keeps running to its end, writing records only under its own change; the next check rejoins or supersedes it.
- `setsid -f` is util-linux; elsewhere the subshell fallback leaves the runner in the caller's process group, as before this change.
- `check.pid` and `check.log` lie under `build/stages/`, where the read profile may redirect output. A forged pid file can only make the waiter wait on, or stop, a process that is a check runner (`runner_alive` reads its command line), and a forged verdict decides no gate: the stages gate and the merge gate read the stage records, which only `tools/run_state.sh` writes, as before.
- `refs/backup/*` refs of runs that never pushed stay on origin until deleted by hand; `push` deletes the ref of every run that reaches its push.
